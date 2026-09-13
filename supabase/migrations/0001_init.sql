-- =====================================================================
-- CenereAlert — schema iniziale (Sprint 1)
-- Estensione richiesta per i tipi geografici e le query spaziali.
-- =====================================================================
create extension if not exists postgis;

-- ---------------------------------------------------------------------
-- Soglie configurabili da remoto (anti-abuso tarabile senza deploy).
-- ---------------------------------------------------------------------
create table thresholds_config (
  key text primary key,
  value jsonb not null,
  description text,
  updated_at timestamptz not null default now()
);

insert into thresholds_config (key, value, description) values
  ('min_reports_per_cluster', '3', 'Numero minimo di segnalazioni concordanti nella stessa cella per formare un cluster'),
  ('cluster_window_minutes', '20', 'Finestra temporale entro cui le segnalazioni concorrono allo stesso cluster'),
  ('user_cooldown_minutes', '10', 'Intervallo minimo tra due segnalazioni dello stesso utente'),
  ('decay_hours', '6', 'Ore dopo le quali il peso di una segnalazione nella heatmap decade a zero'),
  ('grid_cell_size_degrees', '0.01', 'Lato della cella di griglia in gradi (~1.1 km alla latitudine dell''Etna)')
on conflict (key) do nothing;

-- Funzione di lettura comoda per le soglie (con cast al tipo richiesto).
create or replace function get_threshold_numeric(p_key text) returns numeric as $$
  select (value#>>'{}')::numeric from thresholds_config where key = p_key;
$$ language sql stable;

-- ---------------------------------------------------------------------
-- Segnalazioni (reports)
-- ---------------------------------------------------------------------
create table reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  position geography(Point, 4326) not null,
  intensity smallint not null check (intensity in (1, 2, 3)),
  grid_cell text not null,
  created_at timestamptz not null default now()
);

create index idx_reports_position on reports using gist (position);
create index idx_reports_grid_cell_time on reports (grid_cell, created_at);
create index idx_reports_user_time on reports (user_id, created_at);

-- Calcola la cella di griglia quadrata: scelta fatta per l'MVP al posto di
-- H3 (che richiederebbe un'estensione non disponibile di default su
-- Supabase). Il lato cella è configurabile da thresholds_config, quindi
-- tarabile sui dati reali senza modificare questa funzione.
create or replace function compute_grid_cell(p_position geography) returns text as $$
declare
  v_cell_size numeric := get_threshold_numeric('grid_cell_size_degrees');
  v_lon numeric := st_x(p_position::geometry);
  v_lat numeric := st_y(p_position::geometry);
begin
  return format(
    '%s_%s',
    floor(v_lon / v_cell_size)::int,
    floor(v_lat / v_cell_size)::int
  );
end;
$$ language plpgsql stable;

-- Peso di decadimento temporale calcolato a runtime (non memorizzato,
-- perché dipende da una soglia configurabile che può cambiare nel tempo).
create or replace function report_decay_weight(p_created_at timestamptz) returns numeric as $$
declare
  v_decay_hours numeric := get_threshold_numeric('decay_hours');
  v_elapsed_hours numeric := extract(epoch from (now() - p_created_at)) / 3600.0;
begin
  return greatest(0, 1 - (v_elapsed_hours / nullif(v_decay_hours, 0)));
end;
$$ language plpgsql stable;

-- Trigger BEFORE INSERT: applica il cooldown utente e assegna la cella di griglia.
create or replace function before_insert_report() returns trigger as $$
declare
  v_cooldown_minutes numeric := get_threshold_numeric('user_cooldown_minutes');
  v_last_report_at timestamptz;
begin
  select created_at into v_last_report_at
    from reports
    where user_id = new.user_id
    order by created_at desc
    limit 1;

  if v_last_report_at is not null
     and now() - v_last_report_at < make_interval(mins => v_cooldown_minutes) then
    raise exception 'COOLDOWN_ATTIVO: prossima segnalazione disponibile tra qualche minuto';
  end if;

  new.grid_cell := compute_grid_cell(new.position);
  return new;
end;
$$ language plpgsql;

create trigger trg_before_insert_report
  before insert on reports
  for each row execute function before_insert_report();

-- ---------------------------------------------------------------------
-- Cluster di eventi (validazione anti-abuso: una segnalazione isolata
-- non genera mai un'allerta).
-- ---------------------------------------------------------------------
create table event_clusters (
  id uuid primary key default gen_random_uuid(),
  grid_cell text not null,
  average_intensity numeric not null,
  report_count int not null,
  status text not null default 'pending', -- pending | validated | expired
  ingv_gate_ok boolean not null default false,
  created_at timestamptz not null default now(),
  validated_at timestamptz
);

create index idx_event_clusters_cell_status on event_clusters (grid_cell, status);

-- Trigger AFTER INSERT: verifica se il numero di segnalazioni concordanti
-- nella cella, entro la finestra temporale, raggiunge la soglia minima.
-- Nota: questo trigger crea/aggiorna solo il cluster "pending". Il
-- passaggio a status = 'validated' (che sblocca l'invio delle push)
-- richiede l'incrocio col gate INGV (ingv_gate_ok) e verrà implementato
-- nello sprint "ALLERTA DI PROSSIMITÀ", insieme alla Edge Function di notifica.
create or replace function after_insert_report() returns trigger as $$
declare
  v_min_reports numeric := get_threshold_numeric('min_reports_per_cluster');
  v_window_minutes numeric := get_threshold_numeric('cluster_window_minutes');
  v_count int;
  v_avg_intensity numeric;
  v_cluster_id uuid;
begin
  select count(*), avg(intensity)
    into v_count, v_avg_intensity
    from reports
    where grid_cell = new.grid_cell
      and created_at >= now() - make_interval(mins => v_window_minutes);

  if v_count >= v_min_reports then
    select id into v_cluster_id
      from event_clusters
      where grid_cell = new.grid_cell
        and status = 'pending'
      order by created_at desc
      limit 1;

    if v_cluster_id is null then
      insert into event_clusters (grid_cell, average_intensity, report_count)
      values (new.grid_cell, v_avg_intensity, v_count);
    else
      update event_clusters
        set average_intensity = v_avg_intensity,
            report_count = v_count
        where id = v_cluster_id;
    end if;
  end if;

  return new;
end;
$$ language plpgsql;

create trigger trg_after_insert_report
  after insert on reports
  for each row execute function after_insert_report();

-- ---------------------------------------------------------------------
-- Reputazione utente (coerenza storica delle segnalazioni).
-- La logica di aggiornamento del punteggio verrà implementata nello
-- sprint dedicato, quando saranno disponibili le validazioni dei cluster.
-- ---------------------------------------------------------------------
create table user_reputation (
  user_id uuid primary key references auth.users(id) on delete cascade,
  score numeric not null default 0.5,
  total_reports int not null default 0,
  confirmed_reports int not null default 0,
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- Luoghi salvati (casa, lavoro, terreno agricolo).
-- ---------------------------------------------------------------------
create table saved_places (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  label text not null,
  position geography(Point, 4326) not null,
  alert_radius_km numeric not null default 5 check (alert_radius_km between 3 and 10)
);

create index idx_saved_places_position on saved_places using gist (position);
create index idx_saved_places_user on saved_places (user_id);

-- ---------------------------------------------------------------------
-- Cache del feed VONA/INGV (alimentata da una Edge Function schedulata,
-- vedi lo sprint "FEED UFFICIALE"). Nessuna API ufficiale disponibile:
-- la Edge Function fa scraping della pagina HTML e parsing del PDF collegato.
-- ---------------------------------------------------------------------
create table vona_feed_cache (
  id uuid primary key default gen_random_uuid(),
  source_url text not null,
  pdf_url text,
  volcano text, -- 'ETNA' | 'STROMBOLI'
  simplified_text text,
  received_at timestamptz not null,
  parsing_succeeded boolean not null default true
);

create index idx_vona_feed_received on vona_feed_cache (received_at desc);

-- ---------------------------------------------------------------------
-- Vista pubblica delle segnalazioni: espone solo i dati anonimizzati
-- necessari per la heatmap, mai lo user_id (GDPR / privacy by design).
-- ---------------------------------------------------------------------
create or replace view reports_public as
select
  id,
  st_y(position::geometry) as latitude,
  st_x(position::geometry) as longitude,
  intensity,
  grid_cell,
  created_at,
  report_decay_weight(created_at) as decay_weight
from reports;

-- =====================================================================
-- Row Level Security
-- =====================================================================
alter table reports enable row level security;
alter table event_clusters enable row level security;
alter table user_reputation enable row level security;
alter table saved_places enable row level security;
alter table thresholds_config enable row level security;
alter table vona_feed_cache enable row level security;

-- reports: un utente può inserire solo segnalazioni proprie e leggere
-- solo le proprie righe grezze (la lettura pubblica passa dalla vista).
create policy reports_insert_own on reports
  for insert with check (auth.uid() = user_id);

create policy reports_select_own on reports
  for select using (auth.uid() = user_id);

-- La vista reports_public eredita i permessi di chi la interroga;
-- la rendiamo leggibile a chiunque sia autenticato (anche in modo anonimo).
grant select on reports_public to authenticated, anon;

-- event_clusters: lettura pubblica, nessuna scrittura diretta dal client
-- (gestita solo da trigger/funzioni lato server).
create policy event_clusters_select_all on event_clusters
  for select using (true);

-- user_reputation: ogni utente legge solo il proprio punteggio;
-- gli aggiornamenti avvengono solo lato server.
create policy user_reputation_select_own on user_reputation
  for select using (auth.uid() = user_id);

-- saved_places: CRUD completo ma solo sulle proprie righe.
create policy saved_places_all_own on saved_places
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- thresholds_config: lettura pubblica (trasparenza), nessuna scrittura dal client.
create policy thresholds_config_select_all on thresholds_config
  for select using (true);

-- vona_feed_cache: lettura pubblica, scrittura riservata al service role
-- (usato dalla Edge Function schedulata).
create policy vona_feed_cache_select_all on vona_feed_cache
  for select using (true);
