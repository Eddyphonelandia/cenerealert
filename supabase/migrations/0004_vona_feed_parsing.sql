-- =====================================================================
-- CenereAlert — Sprint FEED UFFICIALE
-- =====================================================================

-- Classificazione dell'evento (inizio/in corso/fine), dedotta dal testo
-- della descrizione del comunicato pubblicata nella tabella HTML INGV
-- (non dal PDF collegato, vedi README per la scelta). Usata dal gate
-- INGV per non restare "aperto" dopo un comunicato di fine fenomeno.
alter table vona_feed_cache
  add column if not exists event_status text
    check (event_status in ('started', 'ongoing', 'ended', 'unknown'))
    default 'unknown';

-- Necessario per fare upsert idempotenti dalla Edge Function di
-- scraping: lo stesso PDF non deve mai generare due righe distinte.
alter table vona_feed_cache
  add constraint vona_feed_cache_pdf_url_key unique (pdf_url);

-- Il gate ora guarda anche lo stato dell'ultimo comunicato per l'Etna:
-- se è "ended" (fine fenomeno), il gate si chiude subito, a prescindere
-- dalla finestra temporale configurata — prima di questo sprint un
-- comunicato di fine evento non chiudeva il gate, solo la finestra
-- temporale lo faceva scadere.
create or replace function check_ingv_gate() returns boolean as $$
declare
  v_window_hours numeric := get_threshold_numeric('ingv_gate_window_hours');
  v_latest_status text;
  v_latest_received timestamptz;
begin
  select event_status, received_at
    into v_latest_status, v_latest_received
    from vona_feed_cache
    where volcano = 'ETNA'
    order by received_at desc
    limit 1;

  if v_latest_status is null or v_latest_status = 'ended' then
    return false;
  end if;

  return v_latest_received >= now() - make_interval(hours => v_window_hours);
end;
$$ language plpgsql stable;
