// supabase/functions/fetch-vona-feed/index.ts
//
// Scraping periodico della pagina dei comunicati vulcanici pubblicata
// dall'INGV - Osservatorio Etneo. Non esiste un'API/feed strutturato
// ufficiale (verificato in fase di architettura): questa funzione fa
// parsing della tabella HTML pubblica e classifica ogni comunicato in
// base al testo della sua descrizione — NON al PDF collegato, che resta
// solo un link "leggi la fonte" mai nascosto (vedi README per il perché
// di questa scelta).
//
// Va invocata periodicamente (ogni 5-10 minuti) da un job pg_cron + pg_net
// configurato manualmente dopo il deploy: richiede l'URL della funzione
// deployata e la service role key del progetto, quindi non è
// scriptabile in modo affidabile da questo ambiente (vedi README).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

// Pagina più recente della sezione "Comunicati vulcanici trasmessi
// dall'INGV". Assunzione: I=1 (o l'assenza del parametro) corrisponde
// alla pagina più recente — verificata manualmente in fase di ricerca,
// ma da ricontrollare se INGV dovesse rinumerare le pagine.
const SOURCE_URL =
  'https://www.ct.ingv.it/sezioniesterne/Comunicati/ComunicatiVulcanici.php?I=1';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

interface ParsedRow {
  receivedAt: string; // ISO 8601, UTC
  description: string;
  pdfUrl: string;
  volcano: string;
}

Deno.serve(async (_req) => {
  try {
    const response = await fetch(SOURCE_URL);
    if (!response.ok) {
      return new Response(`pagina INGV non raggiungibile: ${response.status}`, {
        status: 502,
      });
    }
    const html = await response.text();
    const rows = parseRows(html);

    if (rows.length === 0) {
      // Non è necessariamente un errore: può darsi che INGV abbia
      // cambiato il markup della pagina. Da monitorare nei log della
      // funzione se questo valore resta 0 per più esecuzioni di fila.
      return new Response(
        JSON.stringify({ righeLette: 0, nuoveRighe: 0 }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      );
    }

    let nuoveRighe = 0;
    for (const row of rows) {
      const { error, count } = await supabase
        .from('vona_feed_cache')
        .upsert(
          {
            source_url: SOURCE_URL,
            pdf_url: row.pdfUrl,
            volcano: row.volcano,
            received_at: row.receivedAt,
            simplified_text: simplifiedTextFor(row),
            event_status: classify(row.description),
            parsing_succeeded: true,
          },
          { onConflict: 'pdf_url', ignoreDuplicates: true, count: 'exact' },
        );

      if (error) {
        console.error('upsert vona_feed_cache error', error, row.pdfUrl);
        continue;
      }
      nuoveRighe += count ?? 0;
    }

    return new Response(
      JSON.stringify({ righeLette: rows.length, nuoveRighe }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('fetch-vona-feed error', err);
    return new Response('errore interno', { status: 500 });
  }
});

// Parsing minimale della tabella HTML: ogni riga ha il formato
// "AAAA-MM-GG HH:MM:SS DESCRIZIONE [DOWNLOAD PDF](url)". Fragile per
// costruzione (dipende dal markup non versionato della pagina INGV): se
// il formato cambia, questa funzione smette semplicemente di trovare
// righe (righeLette: 0 nella risposta) invece di rompersi in modo
// rumoroso — ma un log applicativo va comunque monitorato nel tempo.
function parseRows(html: string): ParsedRow[] {
  const rows: ParsedRow[] = [];
  const rowRegex =
    /(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2})\s+([^<[]+?)\s*\[DOWNLOAD PDF]\((https:\/\/[^\s)]+\.pdf)\)/gi;

  let match: RegExpExecArray | null;
  while ((match = rowRegex.exec(html)) !== null) {
    const [, date, time, description, pdfUrl] = match;
    const volcanoMatch = description.match(/ETNA|STROMBOLI/i);
    rows.push({
      receivedAt: `${date}T${time}Z`,
      description: description.trim(),
      pdfUrl,
      volcano: volcanoMatch ? volcanoMatch[0].toUpperCase() : 'SCONOSCIUTO',
    });
  }
  return rows;
}

function classify(
  description: string,
): 'started' | 'ongoing' | 'ended' | 'unknown' {
  const upper = description.toUpperCase();
  if (upper.includes('FINE FENOMENO')) return 'ended';
  if (upper.includes('PRIMO COMUNICATO') || upper.includes('NOTIFICA EVENTO')) {
    return 'started';
  }
  if (upper.includes('ATTIVIT') || upper.includes('VALUTAZIONE')) {
    return 'ongoing';
  }
  return 'unknown';
}

function simplifiedTextFor(row: ParsedRow): string {
  const volcanoLabel =
    row.volcano === 'SCONOSCIUTO' ? 'un vulcano etneo' : row.volcano;

  switch (classify(row.description)) {
    case 'started':
      return `L'INGV ha segnalato l'inizio di un nuovo evento su ${volcanoLabel}.`;
    case 'ongoing':
      return `L'INGV conferma attività in corso su ${volcanoLabel}.`;
    case 'ended':
      return `L'INGV ha comunicato la fine del fenomeno su ${volcanoLabel}.`;
    default:
      return `Nuovo comunicato dell'INGV su ${volcanoLabel}.`;
  }
}
