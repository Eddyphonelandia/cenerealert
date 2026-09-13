-- =====================================================================
-- CenereAlert — Sprint ALLERTA DI PROSSIMITÀ
-- =====================================================================

-- Nuove soglie configurabili.
insert into thresholds_config (key, value, description) values
  ('ingv_gate_window_hours', '6', 'Ore entro cui un comunicato VONA/INGV recente tiene aperto il gate per validare i cluster'),
  ('cluster_expiry_minutes', '60', 'Minuti dopo i quali un cluster ancora "pending" (mai validato dal gate INGV) viene scaduto')
on conflict (key) do nothing;

-- ---------------------------------------------------------------------
-- Gate INGV: nessuna allerta di massa se l'INGV non conferma un'attività
-- in corso. Per l'MVP il gate guarda semplicemente se esiste un
-- comunicato recente in vona_feed_cache; la categorizzazione fine
-- (es. escludere i comunicati "fine fenomeno") è demandata alla Edge
-- Function di scraping/parsing del feed VONA, non ancora implementata.
-- ---------------------------------------------------------------------
create or replace function check_ingv_gate() returns boolean as $$
declare
  v_window_hours numeric := get_threshold_numeric('ingv_gate_window_hours');
begin
  return exists (
    select 1 from vona_feed_cache
    where volcano = 'ETNA'
      and received_at >= now() - make_interval(hours => v_window_hours)
  );
end;
$$ language plpgsql stable;

-- Ricostruisce il centro approssimativo di una cella di griglia a partire
-- dalla sua chiave testuale ("lonIdx_latIdx"), per poter fare query di
-- prossimità (ST_DWithin) contro luoghi salvati e posizioni degli utenti.
create or replace function grid_cell_centroid(p_grid_cell text) returns geography as $$
declare
  v_cell_size numeric := get_threshold_numeric('grid_cell_size_degrees');
  v_lon_idx int := split_part(p_grid_cell, '_', 1)::int;
  v_lat_idx int := split_part(p_grid_cell, '_', 2)::int;
begin
  return ST_SetSRID(
    ST_MakePoint(
      (v_lon_idx + 0.5) * v_cell_size,
      (v_lat_idx + 0.5) * v_cell_size
    ),
    4326
  )::geography;
end;
$$ language plpgsql stable;

-- Quando arriva un nuovo comunicato VONA (inserito dalla Edge Function di
-- scraping, sprint successivo — o manualmente per i test), riprova a
-- validare tutti i cluster ancora "pending": se il gate ora è aperto,
-- diventano "validated" e la Edge Function notify-proximity può inviare
-- le push (vedi il Database Webhook descritto nel README).
create or replace function try_validate_pending_clusters() returns trigger as $$
begin
  update event_clusters
    set status = 'validated',
        ingv_gate_ok = true,
        validated_at = now()
    where status = 'pending'
      and check_ingv_gate();
  return null;
end;
$$ language plpgsql;

create trigger trg_vona_feed_validate_clusters
  after insert on vona_feed_cache
  for each row execute function try_validate_pending_clusters();

-- Un cluster "pending" che non viene mai confermato dall'INGV entro la
-- finestra configurata scade, così non resta a tempo indeterminato in
-- attesa senza mai generare né un'allerta né una pulizia.
create or replace function expire_stale_clusters() returns void as $$
declare
  v_expiry_minutes numeric := get_threshold_numeric('cluster_expiry_minutes');
begin
  update event_clusters
    set status = 'expired'
    where status = 'pending'
      and created_at < now() - make_interval(mins => v_expiry_minutes);
end;
$$ language plpgsql;

-- Tentativo di pianificazione automatica via pg_cron (estensione da
-- abilitare in Database > Extensions sul dashboard Supabase). Se non
-- disponibile, la migration non fallisce: va pianificata manualmente,
-- vedi il README.
do $$
begin
  perform cron.schedule(
    'expire-stale-clusters',
    '*/5 * * * *',
    'select expire_stale_clusters();'
  );
exception when others then
  raise notice 'pg_cron non disponibile: pianifica expire_stale_clusters() manualmente (vedi README).';
end $$;

-- ---------------------------------------------------------------------
-- Sottoscrizioni per le allerte di prossimità: un token FCM per
-- dispositivo, l'ultima posizione nota (solo mentre l'app è in primo
-- piano, vedi limite descritto nel README) e il raggio scelto
-- dall'utente (3-10 km, indipendente dai luoghi salvati).
-- ---------------------------------------------------------------------
create table device_alert_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  fcm_token text not null,
  last_known_position geography(Point, 4326),
  notify_radius_km numeric not null default 5 check (notify_radius_km between 3 and 10),
  updated_at timestamptz not null default now(),
  unique (user_id, fcm_token)
);

create index idx_device_alert_subscriptions_position
  on device_alert_subscriptions using gist (last_known_position);
create index idx_device_alert_subscriptions_user
  on device_alert_subscriptions (user_id);

alter table device_alert_subscriptions enable row level security;

create policy device_alert_subscriptions_all_own on device_alert_subscriptions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- Trova i destinatari di una push per un cluster validato: chi si trova
-- (secondo l'ultima posizione nota) entro il proprio raggio di notifica,
-- oppure chi ha un luogo salvato entro il raggio di quel luogo. SECURITY
-- DEFINER perché deve leggere righe di utenti diversi da chi la invoca
-- (la Edge Function la chiama con la service role, che bypassa comunque
-- la RLS; la marchiamo così anche per un'eventuale chiamata futura da
-- un contesto con privilegi minori).
-- ---------------------------------------------------------------------
create or replace function find_recipients_for_cluster(p_cluster_id uuid)
returns table(fcm_token text, user_id uuid)
security definer
as $$
declare
  v_centroid geography;
begin
  select grid_cell_centroid(grid_cell) into v_centroid
    from event_clusters where id = p_cluster_id;

  if v_centroid is null then
    return;
  end if;

  return query
    select distinct s.fcm_token, s.user_id
    from device_alert_subscriptions s
    where s.last_known_position is not null
      and ST_DWithin(s.last_known_position, v_centroid, s.notify_radius_km * 1000)
    union
    select distinct s.fcm_token, s.user_id
    from device_alert_subscriptions s
    join saved_places p on p.user_id = s.user_id
    where ST_DWithin(p.position, v_centroid, p.alert_radius_km * 1000);
end;
$$ language plpgsql stable;

revoke execute on function find_recipients_for_cluster(uuid) from public;
grant execute on function find_recipients_for_cluster(uuid) to service_role;
