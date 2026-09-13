// supabase/functions/notify-proximity/index.ts
//
// Invocata da un Database Webhook di Supabase quando una riga di
// event_clusters passa a status = 'validated' (il webhook va creato dal
// dashboard, vedi README — non è scriptabile in modo affidabile da qui).
//
// Trova i destinatari con find_recipients_for_cluster (RPC lato database)
// e invia una push a ciascun token via l'API HTTP v1 di Firebase Cloud
// Messaging, autenticandosi con un service account tramite JWT firmato.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const FCM_PROJECT_ID = Deno.env.get('FCM_PROJECT_ID')!;
const FCM_CLIENT_EMAIL = Deno.env.get('FCM_CLIENT_EMAIL')!;
// La chiave privata va salvata come secret; qui ripristiniamo gli a capo
// nel caso siano stati salvati come sequenza letterale "\n".
const FCM_PRIVATE_KEY = Deno.env.get('FCM_PRIVATE_KEY')!.replace(/\\n/g, '\n');

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const cluster = payload.record;

    if (!cluster || cluster.status !== 'validated') {
      return new Response('ignorato: cluster non validato', { status: 200 });
    }

    const { data: recipients, error } = await supabase.rpc(
      'find_recipients_for_cluster',
      { p_cluster_id: cluster.id },
    );

    if (error) {
      console.error('find_recipients_for_cluster error', error);
      return new Response('errore nel recupero destinatari', { status: 500 });
    }

    if (!recipients || recipients.length === 0) {
      return new Response('nessun destinatario in zona', { status: 200 });
    }

    const accessToken = await getFcmAccessToken();
    const intensityLabel = intensityLabelFor(cluster.average_intensity);

    const results = await Promise.allSettled(
      (recipients as Array<{ fcm_token: string }>).map((r) =>
        sendFcmMessage(accessToken, r.fcm_token, intensityLabel),
      ),
    );

    const failed = results.filter((r) => r.status === 'rejected').length;
    return new Response(
      JSON.stringify({ sent: results.length - failed, failed }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('notify-proximity error', err);
    return new Response('errore interno', { status: 500 });
  }
});

function intensityLabelFor(averageIntensity: number): string {
  if (averageIntensity >= 2.5) return 'Intensa';
  if (averageIntensity >= 1.5) return 'Moderata';
  return 'Leggera';
}

async function sendFcmMessage(
  accessToken: string,
  token: string,
  intensityLabel: string,
): Promise<void> {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: {
            title: 'Caduta cenere segnalata vicino a te',
            body: `Intensità ${intensityLabel.toLowerCase()}. Apri CenereAlert per i dettagli e cosa fare adesso.`,
          },
          data: { type: 'proximity_alert' },
        },
      }),
    },
  );

  if (!response.ok) {
    throw new Error(`FCM ${response.status}: ${await response.text()}`);
  }
}

// --- OAuth2 per FCM HTTP v1 (JWT bearer flow con Web Crypto, senza
// dipendere da librerie Node come googleapis, non disponibili in Deno) ---

let cachedToken: { value: string; expiresAt: number } | null = null;

async function getFcmAccessToken(): Promise<string> {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 30_000) {
    return cachedToken.value;
  }

  const header = { alg: 'RS256', typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const claims = {
    iss: FCM_CLIENT_EMAIL,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const toBase64Url = (input: string) =>
    btoa(input).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

  const unsigned = `${toBase64Url(JSON.stringify(header))}.${toBase64Url(
    JSON.stringify(claims),
  )}`;

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(FCM_PRIVATE_KEY),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signatureBytes = new Uint8Array(
    await crypto.subtle.sign(
      'RSASSA-PKCS1-v1_5',
      key,
      new TextEncoder().encode(unsigned),
    ),
  );
  const signature = toBase64Url(String.fromCharCode(...signatureBytes));

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${unsigned}.${signature}`,
    }),
  });

  if (!tokenResponse.ok) {
    throw new Error(`Scambio token OAuth fallito: ${await tokenResponse.text()}`);
  }

  const tokenJson = await tokenResponse.json();
  cachedToken = {
    value: tokenJson.access_token,
    expiresAt: Date.now() + tokenJson.expires_in * 1000,
  };
  return cachedToken.value;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '');
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}
