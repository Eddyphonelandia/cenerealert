# CenereAlert — Sprint 1

Modello dati (Postgres/PostGIS) + schermata SEGNALA (Flutter/Riverpod/Supabase).

## Setup rapido

1. **Supabase**
   - Crea un progetto su supabase.com.
   - Abilita "Anonymous sign-ins" in Authentication > Providers.
   - Esegui `supabase/migrations/0001_init.sql` nell'SQL Editor del progetto
     (o con `supabase db push` se usi la CLI).

2. **Flutter**
   - `flutter pub get`
   - Scarica i tre pesi del font Inter (Regular, Medium, SemiBold) da
     https://fonts.google.com/specimen/Inter e mettili in `assets/fonts/`
     con i nomi indicati in `pubspec.yaml`.
   - Avvia passando le variabili del tuo progetto Supabase:
     ```
     flutter run \
       --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
       --dart-define=SUPABASE_ANON_KEY=xxxx
     ```

3. **Autenticazione anonima**
   - Abilita "Anonymous sign-ins" in Authentication > Providers (passaggio
     obbligatorio, altrimenti l'app resta bloccata sulla schermata di
     errore di `AuthGate`, vedi Sprint 3 più sotto).
   - Il bootstrap (`signInAnonymously()`) parte automaticamente dopo la
     schermata di consenso, prima di mostrare la mappa.

## Cosa c'è in questo sprint
- Schema completo del database: `reports`, `event_clusters`,
  `user_reputation`, `saved_places`, `thresholds_config`, `vona_feed_cache`,
  con Row Level Security e i due trigger anti-abuso (cooldown utente,
  formazione cluster minimo).
- Design system applicato: palette, tipografia, componenti (`AppColors`,
  `AppTheme`, `IntensityGlyph`).
- Flusso end-to-end del pulsante SEGNALA: geolocalizzazione → selezione
  intensità → invio a Supabase → conferma o gestione errore (incluso
  messaggio dedicato per il cooldown).

## Sprint 2 — MAPPA LIVE

Aggiunta la heatmap live delle segnalazioni su base MapLibre, con filtro
temporale 1h/3h/6h/24h e skeleton loader al primo caricamento.

**File nuovi**: `lib/features/map/` (repository di lettura dalla vista
pubblica, provider Riverpod col refresh periodico, stile heatmap, widget
mappa, chip filtro) e `assets/map_style/dark_style.json` (stile di base).

### Decisioni prese senza fermarmi a chiederti conferma

1. **Basemap raster CARTO Dark Matter** (gratuita, no API key) invece di
   uno stile vettoriale su misura, per avere subito il mood "nero
   vulcanico" senza bloccare lo sprint su un provider di tile a pagamento.
   **Attenzione**: le basemap gratuite di CARTO hanno limiti d'uso pensati
   per progetti a basso traffico — proprio lo scenario "eruzione notturna,
   migliaia di accessi in pochi minuti" del vincolo non negoziabile
   rischia di violarli. Prima di andare oltre l'MVP valuta un provider
   dedicato (MapTiler, Stadia Maps) o tile self-hosted (OpenMapTiles).
2. **Nessun canale Realtime dedicato**: la tabella `reports` ha RLS che
   limita la lettura alle righe proprie dell'utente (necessario per la
   privacy), quindi un abbonamento Realtime diretto mostrerebbe solo le
   segnalazioni dell'utente stesso, non quelle altrui. Ho optato per un
   refresh periodico (ogni 20s) della vista pubblica `reports_public`.
   Se in fase di test un ritardo di ~20s risultasse troppo lento durante
   un evento in corso, il passo successivo è un canale Realtime via
   Broadcast/`pg_notify`, non ancora implementato.
3. **`myLocationEnabled: false`**: guardare la mappa non richiede il
   permesso di geolocalizzazione, richiesto solo al momento di una
   segnalazione — coerente col consenso granulare richiesto dal GDPR.
4. **Transizione del filtro temporale semplificata**: invece di un
   cross-fade nativo dei dati della heatmap (che richiederebbe due
   layer paralleli), il cambio filtro aggiorna la sorgente GeoJSON
   direttamente; l'unica animazione nativa MapLibre è quella dello
   skeleton loader al primo caricamento. Un cross-fade vero è rimandabile
   a un secondo passaggio di rifinitura se la transizione dovesse
   risultare troppo "a scatto" nei test con dati reali.

### Limite di verifica di questo ambiente
Non ho un runtime Flutter né accesso a pub.dev in questo ambiente, quindi
non ho potuto eseguire `flutter pub get` / `flutter analyze` su questo
codice. L'uso dell'API di `maplibre_gl` (nomi di classi come
`GeojsonSourceProperties`, `HeatmapLayerProperties`, metodi come
`addSource`/`addLayer`/`setGeojsonSource`) segue la superficie pubblica
documentata del pacchetto, ma ti consiglio di lanciare `flutter pub get`
e `flutter analyze` in locale appena possibile, per intercettare eventuali
differenze di firma legate alla versione esatta che si installa.

## Sprint 3 — Autenticazione anonima

Bootstrap della sessione anonima, collegamento facoltativo di un'email
per portare reputazione e luoghi salvati su un nuovo dispositivo, e una
schermata di consenso GDPR granulare mostrata al primo avvio.

**File nuovi**: `lib/features/auth/` (repository, provider, `AuthGate`),
`lib/features/onboarding/` (`ConsentScreen`, `ConsentGate`),
`lib/features/account/` (`AccountLinkSheet`), `lib/core/storage/local_flags.dart`,
`lib/core/widgets/disclaimer_bar.dart`.

Ordine di avvio in `main.dart`: **ConsentGate → AuthGate → HomeScreen**.
Il consenso viene chiesto prima di qualunque rete o permesso di sistema;
solo dopo l'accettazione parte il bootstrap della sessione anonima.

### Un gap che ho notato e corretto senza chiedere conferma

Rileggendo i vincoli non negoziabili del brief originale, il **disclaimer
sempre visibile** ("servizio informativo collaborativo, non sostituisce
la Protezione Civile né l'INGV") non era ancora stato implementato negli
sprint precedenti — l'avevo discusso nel design system ma non c'era
ancora un componente reale in `HomeScreen`. L'ho aggiunto ora come
`DisclaimerBar`, fissata in `bottomNavigationBar` così resta visibile in
ogni momento, non dietro un menu.

### Decisioni prese senza fermarmi a chiederti conferma

1. **Collegamento email, non telefono**: ho implementato solo il
   collegamento via email (`AuthRepository.linkEmail`). Il collegamento
   via telefono richiede un provider SMS configurato in Supabase (a
   pagamento) e un flusso OTP separato — l'ho lasciato fuori per non
   bloccare lo sprint su una dipendenza esterna a pagamento. La UI
   (`AccountLinkSheet`) è scritta in modo da poter aggiungere in seguito
   un secondo campo "telefono" senza refactoring.
2. **Consenso come schermata a sé stante, non un banner dismissibile**:
   ho scelto una schermata bloccante al primo avvio invece di un banner
   sovrapposto alla mappa, per rendere il consenso un'azione esplicita e
   non un elemento che si può ignorare per errore (requisito "consenso
   granulare", non preselezionato).
3. **`shared_preferences` per il flag di consenso**: è l'unico dato
   salvato solo sul dispositivo (nessun dato personale, solo "consenso
   già letto"); tutto il resto dei dati utente resta su Supabase.

### Limite di verifica di questo ambiente
Come per `maplibre_gl`, non ho un runtime Flutter/pub.dev in questo
ambiente per eseguire `flutter pub get` / `flutter analyze` su questo
codice. In particolare, il campo `User.isAnonymous` e il metodo
`signInAnonymously()` sono documentati per le versioni recenti di
`supabase_flutter`/`gotrue`, ma ti consiglio di verificarli contro la
versione esatta che si installa con `flutter pub get`.

## Sprint 4 — Luoghi salvati

Schermata elenco + form di creazione/modifica per casa, lavoro, terreno
agricolo (o etichette libere), con selettore di posizione su mappa e
slider per il raggio di allerta (3-10 km, vincolo già imposto anche a
livello di database dal check constraint su `alert_radius_km`).

**File nuovi**: `supabase/migrations/0002_saved_places_view.sql` (vista
di lettura con lat/lon esplicite), `lib/features/saved_places/`
(dominio, repository, provider, le tre schermate: elenco, form,
selettore di posizione).

Accesso dalla home: icona segnalibro in alto a destra, accanto
all'icona account.

### Decisioni prese senza fermarmi a chiederti conferma

1. **Vista `saved_places_view` per la lettura**: la colonna `position`
   è un tipo `geography` che PostgREST non restituisce in un formato
   comodo da consumare direttamente in Flutter. Ho aggiunto una vista
   che espone `latitude`/`longitude` come colonne numeriche (stesso
   pattern già usato per `reports_public`). È solo di lettura: le
   scritture continuano ad andare sulla tabella base `saved_places`,
   che resta l'unica con la Row Level Security che conta.
2. **Selettore di posizione "mappa che scorre sotto un pin fisso"**
   invece di un marker trascinabile o di un tap-to-place: è il pattern
   più robusto multipiattaforma con l'API di MapLibre, e riusa lo stesso
   stile mappa già pronto dallo sprint precedente.
3. **Limite di 5 luoghi salvati per utente**, imposto solo lato client
   per ora (`maxSavedPlaces`). Non è ancora specchiato in
   `thresholds_config` né in un vincolo lato database: se dovesse
   servire un limite duro anche in caso di più dispositivi/client
   diversi, andrebbe aggiunto un check lato server nello sprint delle
   push di prossimità.

## Sprint 5 — Allerta di prossimità

Il pezzo più delicato dell'anti-abuso: il gate INGV, la validazione/
scadenza dei cluster, e l'invio effettivo delle push quando un cluster
viene validato.

**File nuovi**: `supabase/migrations/0003_proximity_alerts.sql` (gate
INGV, `try_validate_pending_clusters`, `expire_stale_clusters`, tabella
`device_alert_subscriptions`, funzione `find_recipients_for_cluster`),
`supabase/functions/notify-proximity/index.ts` (Edge Function che invia
le push FCM), `lib/features/notifications/` (registrazione token,
aggiornamento posizione in primo piano, preferenza raggio).

### Come si incastra con quanto già costruito
1. Una segnalazione fa scattare `after_insert_report` (sprint 1): se la
   soglia è raggiunta, crea/aggiorna un `event_cluster` con
   `status = 'pending'`.
2. Quando arriva un comunicato in `vona_feed_cache` (per ora solo
   manualmente, finché non esiste la Edge Function di scraping VONA), il
   trigger `trg_vona_feed_validate_clusters` prova a validare tutti i
   cluster pending: se il gate è aperto (comunicato recente per l'Etna),
   passano a `status = 'validated'`.
3. Un **Database Webhook** (da creare a mano nel dashboard Supabase, vedi
   sotto) chiama la Edge Function `notify-proximity` su ogni update di
   `event_clusters`.
4. La Edge Function chiama `find_recipients_for_cluster` e invia una push
   FCM a ciascun destinatario: chi si trova entro il proprio raggio di
   notifica, o chi ha un luogo salvato entro il raggio di quel luogo.

### Setup necessario (non eseguibile da questo ambiente)
1. **Estensione `pg_cron`**: abilitala in Database > Extensions per far
   scadere automaticamente i cluster pending. Se non la abiliti, la
   migration non fallisce ma dovrai chiamare `select
   expire_stale_clusters();` manualmente o schedularla altrove.
2. **Progetto Firebase**: crealo, aggiungi le app Android/iOS, genera un
   service account (Project Settings > Service Accounts > Generate new
   private key).
3. **Secrets della Edge Function**:
   ```
   supabase secrets set \
     FCM_PROJECT_ID=il-tuo-project-id \
     FCM_CLIENT_EMAIL=xxx@xxx.iam.gserviceaccount.com \
     FCM_PRIVATE_KEY="$(cat service-account.json | jq -r .private_key)"
   ```
4. **Deploy della funzione**: `supabase functions deploy notify-proximity`.
5. **Database Webhook**: Database > Webhooks nel dashboard Supabase,
   tabella `event_clusters`, evento UPDATE, condizione sulla colonna
   `status`, URL della funzione deployata, header con la service role key.
6. **Scaffold nativi Flutter mancanti**: questo repository contiene solo
   `lib/`, non le cartelle `android/`/`ios/` generate da `flutter create`.
   Vanno generate (`flutter create .` nella cartella del progetto) prima
   di aggiungere `google-services.json` / `GoogleService-Info.plist` e le
   configurazioni native di MapLibre e Firebase — un passaggio che avrei
   dovuto segnalare fin dal primo sprint con MapLibre e non l'avevo
   fatto esplicitamente.

### Decisioni e limiti importanti

1. **Nessun aggiornamento della posizione in background.** La posizione
   usata per l'allerta di prossimità (non i luoghi salvati, che restano
   validi in ogni momento) si aggiorna solo mentre l'app è aperta, ogni 5
   minuti. Per lo scenario centrale del brief — "un'eruzione notturna
   concentra migliaia di accessi in pochi minuti" — questo è un limite
   reale: se l'utente ha l'app chiusa quando la cenere arriva, l'allerta
   di prossimità legata alla posizione attuale non si attiva (i luoghi
   salvati sì, perché non dipendono dalla posizione in tempo reale). Non
   ho aggiunto l'aggiornamento in background perché richiederebbe il
   permesso di geolocalizzazione "sempre" (Always) su iOS, con
   implicazioni su consumi e consenso che meritano una decisione
   esplicita, non un'aggiunta silenziosa.
2. **Gate INGV semplificato.** Per ora il gate è "esiste un comunicato
   VONA per l'Etna nelle ultime N ore", senza distinguere un comunicato
   di inizio attività da uno di fine fenomeno (che dovrebbe *chiudere*
   il gate, non tenerlo aperto). Questa distinzione richiede il parsing
   del testo del PDF, che è lo sprint "FEED UFFICIALE" ancora da fare.
3. **API FCM HTTP v1** invece della legacy API (deprecata): la Edge
   Function firma da sé un JWT con Web Crypto per ottenere un access
   token OAuth2, senza librerie Node non disponibili in Deno. Non ho
   potuto eseguire questa funzione in questo ambiente (nessun runtime
   Deno, nessun progetto Firebase reale): verificala con
   `supabase functions serve` in locale prima del deploy.
4. **`find_recipients_for_cluster` è `SECURITY DEFINER`**: deve poter
   leggere le sottoscrizioni e i luoghi salvati di utenti diversi da chi
   chiama la funzione. L'esecuzione è concessa solo al ruolo
   `service_role`, usato dalla Edge Function.

## Sprint 6 — Feed ufficiale

Scraping/parsing dei comunicati vulcanici INGV (nessuna API ufficiale
disponibile, vedi ricerca fatta in fase di architettura), card "FEED
UFFICIALE" in home con riassunto in linguaggio semplice e link sempre
visibile alla fonte, e un aggiornamento del gate INGV che ora chiude
subito l'allerta di prossimità dopo un comunicato di fine fenomeno.

**File nuovi**: `supabase/migrations/0004_vona_feed_parsing.sql`,
`supabase/functions/fetch-vona-feed/index.ts`,
`lib/features/vona_feed/` (dominio, repository, provider, `VonaFeedCard`).

### Decisione più importante di questo sprint

**Ho scelto di classificare i comunicati dal testo della descrizione
nella tabella HTML, non dal contenuto del PDF.** La pagina INGV già
etichetta ogni riga in modo abbastanza strutturato — "PRIMO COMUNICATO
DI NOTIFICA EVENTO", "INVIO COMUNICATO GENERICO DI ATTIVITÀ", "COMUNICATO
DI FINE FENOMENO" — ed è materiale sufficiente per capire se un evento
sta iniziando, è in corso, o è finito, che è esattamente ciò che serve al
gate INGV. Estrarre il testo dal PDF (spesso un'immagine scansionata o un
layout non semplice da parsare in modo affidabile) avrebbe aggiunto
complessità e fragilità senza un beneficio proporzionato per l'MVP. Il
PDF resta comunque sempre raggiungibile con un link diretto — mai
nascosto, come richiesto dal design system — per chi vuole i dettagli
completi (coordinate, quota del pennacchio, ecc.).

Una conseguenza pratica: il gate INGV, aggiornato in questa migration,
ora si **chiude immediatamente** quando l'ultimo comunicato per l'Etna è
di tipo "fine fenomeno", indipendentemente dalla finestra temporale
configurata. Prima di questo sprint, un comunicato di fine evento non
faceva nulla di esplicito: il gate restava aperto fino alla scadenza
naturale della finestra oraria, il che avrebbe potuto validare cluster
anche dopo la fine ufficiale di un evento.

### Altre decisioni e limiti

1. **Parsing HTML fragile per costruzione**: la funzione cerca righe nel
   formato esatto osservato nella pagina INGV oggi. Se INGV cambia il
   markup, la funzione smette di trovare righe (risponde con
   `righeLette: 0`) invece di rompersi rumorosamente, ma questo va
   comunque monitorato nei log della funzione nel tempo.
2. **Pagina di partenza assunta come "I=1"**: verificato manualmente
   durante la ricerca, ma da riconfermare se INGV rinumera le pagine.
3. **Nessuna pianificazione automatica di questa Edge Function**: a
   differenza di `expire_stale_clusters` (chiamata SQL interna),
   `fetch-vona-feed` richiede una chiamata HTTP verso l'URL della
   funzione deployata, che non conosco in anticipo. Va pianificata a
   mano dopo il deploy:
   ```sql
   -- Richiede le estensioni pg_cron e pg_net (Database > Extensions).
   select cron.schedule(
     'fetch-vona-feed',
     '*/10 * * * *',
     $$
     select net.http_post(
       url := 'https://<il-tuo-project-ref>.supabase.co/functions/v1/fetch-vona-feed',
       headers := jsonb_build_object('Authorization', 'Bearer <service-role-key>'),
       body := '{}'::jsonb
     );
     $$
   );
   ```
4. **Non ho potuto eseguire questa funzione in questo ambiente** (nessun
   runtime Deno, e non è prudente fare scraping ripetuto della pagina
   INGV da qui solo per testare). Verificala con `supabase functions
   serve` in locale, confrontando l'output con il contenuto reale della
   pagina, prima del deploy.

## Sprint 7 — Reputazione utente (ultimo pezzo del piano MVP)

Il brief elenca la reputazione sotto ANTI-ABUSO, non come funzionalità a
sé stante — quindi questo sprint non si limita a calcolare un numero da
mostrare in un profilo, ma lo aggancia davvero alla soglia di clustering.

**File nuovi**: `supabase/migrations/0005_reputation.sql` (riscrive
`after_insert_report` e `try_validate_pending_clusters`, aggiunge
`credit_reputation_for_cluster` e la colonna `reports.cluster_id`),
`lib/features/reputation/` (dominio, repository, provider) e un piccolo
riepilogo di sola lettura aggiunto in fondo a `AccountLinkSheet`.

### La decisione centrale: la soglia di clustering ora è pesata, non contata a teste

Prima di questo sprint, `min_reports_per_cluster` contava semplicemente
quante segnalazioni cadevano nella stessa cella/finestra. Ora ogni
segnalazione **pesa quanto il punteggio di reputazione di chi la invia**
(0.5 di partenza per chi non ha ancora storico, fino a 1.0 per chi ha
sempre visto le proprie segnalazioni confermate). Concretamente: un
gruppo di account nuovi o mai confermati deve essere più numeroso di un
piccolo gruppo di segnalatori storicamente affidabili per raggiungere la
stessa soglia. È esattamente il collegamento anti-abuso che il brief
chiedeva accostando "clustering" e "reputazione" nella stessa sezione,
ma che gli sprint precedenti avevano lasciato separati.

Effetto collaterale onesto da segnalare: **la colonna `report_count` su
`event_clusters` ora rappresenta questa somma pesata (arrotondata per
eccesso)**, non più un conteggio esatto di segnalazioni. Se in futuro ti
servisse anche il conteggio "a teste" per la UI o per analisi, va
aggiunta una colonna separata: non l'ho fatta perché non è stata
richiesta finora e avrebbe aggiunto una colonna mai letta da nessuna
schermata.

### Come si aggiorna la reputazione

1. **Ad ogni segnalazione**: viene contata nello storico totale
   dell'utente (`total_reports`), con un punteggio di partenza neutro
   (0.5) se non ha ancora storico.
2. **Quando un cluster viene validato** (gate INGV aperto, come dallo
   sprint precedente): tutte le segnalazioni collegate a quel cluster
   (tramite la nuova colonna `reports.cluster_id`) accreditano
   `confirmed_reports` ai rispettivi utenti; il punteggio si ricalcola
   come `confermate / totali`, con un tetto a 1.0.
3. **Se un cluster scade senza mai essere validato** (`expire_stale_clusters`,
   sprint precedente), le segnalazioni che lo componevano restano nel
   totale ma non vengono mai accreditate: il punteggio scende nel tempo.
   Questo è un limite intrinseco di qualunque punteggio basato sulla
   conferma altrui — un utente onesto in una zona con pochi altri
   segnalatori attivi può vedere il proprio punteggio scendere senza
   aver fatto nulla di scorretto. Non ho trovato un modo di correggerlo
   senza introdurre un'euristica arbitraria (es. "non contare le
   segnalazioni scadute se l'area ha meno di N utenti attivi"), quindi
   l'ho lasciato come limite dichiarato piuttosto che nascosto dietro
   una correzione improvvisata.

### In app
Un piccolo riepilogo di sola lettura in fondo alla scheda "Account"
("collega email"): quante segnalazioni sono state inviate e quante
confermate, in percentuale. Deliberatamente **senza livelli, badge o
lessico competitivo** — mostrare come funziona la reputazione senza
trasformarla in qualcosa da "ottimizzare", coerente col mood "strumento
scientifico" del design system piuttosto che con un'app gamificata.

## Stato del piano MVP originale
Con questo sprint sono state costruite tutte le funzionalità elencate nel
brief iniziale (SEGNALA, MAPPA LIVE, ALLERTA DI PROSSIMITÀ, LUOGHI
SALVATI, FEED UFFICIALE, COSA FARE ADESSO — quest'ultima non ancora
implementata come schermata a sé, vedi sotto — più tutto il blocco
anti-abuso: clustering pesato dalla reputazione, gate INGV, cooldown,
soglie configurabili da remoto).

## Sprint 8 — Checklist "Cosa fare adesso" (ultimo pezzo del brief originale)

Checklist contestuale: contenuto e ordine cambiano in base all'intensità
rilevata vicino alla posizione dell'utente, come richiesto dal design
system.

**File nuovi**: `lib/features/checklist/` (contenuto progressivo per
livello, provider che determina l'intensità nella zona, la schermata).

### Come viene determinata "l'intensità nella zona dell'utente"

Non esisteva ancora un concetto di "situazione attuale intorno a me" da
nessuna parte nel codice — il filtro 1h/3h/6h/24h della mappa è
un'impostazione di visualizzazione scelta dall'utente, non adatta a
guidare automaticamente una checklist di sicurezza. Ho quindi introdotto
una logica dedicata e indipendente da quel filtro: la segnalazione più
intensa tra quelle ricevute nelle **ultime 3 ore** entro **5 km** dalla
posizione attuale (calcolata lato client con la formula di Haversine,
nessuna dipendenza aggiuntiva). In presenza di segnalazioni miste nella
stessa zona, vince l'intensità più alta, non una media — un compromesso
deliberatamente cautelativo per un contenuto di sicurezza.

### Decisioni prese senza fermarmi a chiederti conferma

1. **Raggio (5 km) e finestra (3 ore) sono valori hardcoded**, non
   ancora in `thresholds_config`. Li ho scelti come compromesso
   ragionevole, ma se in fase di test reali risultassero troppo stretti
   o troppo larghi, andrebbero prima resi configurabili da remoto (come
   già fatto per le soglie anti-abuso) piuttosto che modificati con un
   nuovo deploy.
2. **Liste progressive, non liste separate per livello**: leggera è un
   sottoinsieme di moderata, che è un sottoinsieme di intensa. Ho
   preferito questo all'avere tre liste scritte indipendentemente,
   perché le precauzioni di base restano valide quando la situazione
   peggiora, e non volevo rischiare di "dimenticarle" duplicandole a
   mano in tre punti diversi del codice.
3. **Nessuna spunta persistita**: le caselle segnate si resettano se si
   esce dalla schermata. Ho scelto di non salvarle (né in Supabase né in
   locale) perché non è chiaro se abbia senso ricordarle tra una caduta
   di cenere e la successiva — mi è sembrata un'aggiunta non richiesta
   dal brief piuttosto che un'omissione.

## Bilancio finale del progetto

Con questo si chiudono tutte le funzionalità elencate nel brief
originale: SEGNALA, MAPPA LIVE, ALLERTA DI PROSSIMITÀ, LUOGHI SALVATI,
FEED UFFICIALE, COSA FARE ADESSO, più l'intero blocco anti-abuso
(clustering pesato dalla reputazione, gate INGV, cooldown, soglie
configurabili da remoto) e i vincoli non negoziabili (GDPR con consenso
granulare, disclaimer sempre visibile, auth anonima).

Quello che resta, per onestà, prima che sia pronto per un vero rilascio
— gli stessi punti segnalati alla fine dello sprint precedente, ancora
tutti aperti:
- Verifica end-to-end reale: nessuno sprint è stato eseguito in un
  ambiente Flutter/Supabase/Firebase vero. `flutter create .` per gli
  scaffold nativi mancanti, poi `flutter pub get` e `flutter analyze`
  sono il primo passo pratico.
- Le basemap CARTO gratuite non sono pensate per il traffico di
  un'eruzione notturna.
- La posizione per l'allerta di prossimità si aggiorna solo ad app
  aperta, non in background.
- Raggio e finestra della checklist (questo sprint) sono hardcoded,
  non ancora configurabili da remoto.

## Decisioni prese senza conferma esplicita (sprint 1)
Per la cella di griglia dell'anti-abuso ho usato una griglia quadrata
semplice (`compute_grid_cell`, basata su floor/lon/lat) invece di H3,
perché H3 richiede un'estensione non disponibile di default su Supabase.
È una scelta pragmatica per l'MVP, facilmente sostituibile in seguito se
servisse una griglia esagonale.
