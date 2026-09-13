-- =====================================================================
-- CenereAlert — Sprint REPUTAZIONE UTENTE (ultimo pezzo del piano MVP)
-- =====================================================================

-- Collega ogni segnalazione al cluster che ha eventualmente attivato o
-- aggiornato, per poter risalire — quando quel cluster viene validato —
-- a quali utenti hanno contribuito e accreditare la loro reputazione.
alter table reports add column if not exists cluster_id uuid references event_clusters(id);
create index if not exists idx_reports_cluster on reports (cluster_id);

-- ---------------------------------------------------------------------
-- after_insert_report, riscritta per includere la reputazione in due
-- punti (entrambi richiesti dal brief, che elenca la reputazione sotto
-- ANTI-ABUSO, non come funzionalità a sé stante):
--
-- 1. Ogni segnalazione viene contata nello storico totale dell'utente
--    (riga user_reputation creata al bisogno, con un prior neutro 0.5).
-- 2. Il conteggio che determina se un cluster raggiunge la soglia non è
--    più un semplice numero di segnalazioni, ma una SOMMA PESATA dalla
--    reputazione di chi segnala: un utente con storico scarsamente
--    confermato pesa meno di uno affidabile, quindi servono più
--    account nuovi o sospetti per raggiungere la stessa soglia di un
--    piccolo gruppo di segnalatori affidabili. Questo è un cambio di
--    semantica per min_reports_per_cluster (ora una soglia "pesata", non
--    più un conteggio di teste) — la colonna report_count su
--    event_clusters resta un intero arrotondato per compatibilità con
--    quanto già mostrato altrove, ma rappresenta questa somma pesata.
-- ---------------------------------------------------------------------
create or replace function after_insert_report() returns trigger as $$
declare
  v_min_reports numeric := get_threshold_numeric('min_reports_per_cluster');
  v_window_minutes numeric := get_threshold_numeric('cluster_window_minutes');
  v_weighted_count numeric;
  v_avg_intensity numeric;
  v_cluster_id uuid;
begin
  insert into user_reputation (user_id, total_reports, confirmed_reports, score, updated_at)
  values (new.user_id, 1, 0, 0.5, now())
  on conflict (user_id) do update
    set total_reports = user_reputation.total_reports + 1,
        updated_at = now();

  select coalesce(sum(coalesce(ur.score, 0.5)), 0), avg(r.intensity)
    into v_weighted_count, v_avg_intensity
    from reports r
    left join user_reputation ur on ur.user_id = r.user_id
    where r.grid_cell = new.grid_cell
      and r.created_at >= now() - make_interval(mins => v_window_minutes);

  if v_weighted_count >= v_min_reports then
    select id into v_cluster_id
      from event_clusters
      where grid_cell = new.grid_cell
        and status = 'pending'
      order by created_at desc
      limit 1;

    if v_cluster_id is null then
      insert into event_clusters (grid_cell, average_intensity, report_count)
      values (new.grid_cell, v_avg_intensity, ceil(v_weighted_count))
      returning id into v_cluster_id;
    else
      update event_clusters
        set average_intensity = v_avg_intensity,
            report_count = ceil(v_weighted_count)
        where id = v_cluster_id;
    end if;
  end if;

  if v_cluster_id is not null then
    update reports set cluster_id = v_cluster_id where id = new.id;
  end if;

  return new;
end;
$$ language plpgsql;

-- ---------------------------------------------------------------------
-- Accredita la reputazione di chi ha contribuito a un cluster appena
-- validato: +1 segnalazione confermata per ciascuna sua segnalazione
-- in quel cluster, punteggio ricalcolato come confermate/totali (capped
-- a 1). Un limite consapevole: se un cluster non viene mai validato
-- (scade, vedi expire_stale_clusters) le segnalazioni che lo componevano
-- restano contate nel totale ma mai nelle confermate, quindi abbassano
-- il punteggio nel tempo anche quando la mancata validazione non dipende
-- da un comportamento scorretto dell'utente (es. zona con pochi altri
-- segnalatori). È un compromesso intrinseco a qualunque punteggio basato
-- sulla conferma altrui, non specifico di questa implementazione.
-- ---------------------------------------------------------------------
create or replace function credit_reputation_for_cluster(p_cluster_id uuid) returns void as $$
begin
  update user_reputation ur
    set confirmed_reports = ur.confirmed_reports + sub.report_count,
        score = least(1, (ur.confirmed_reports + sub.report_count)::numeric / greatest(ur.total_reports, 1)),
        updated_at = now()
  from (
    select user_id, count(*) as report_count
    from reports
    where cluster_id = p_cluster_id
    group by user_id
  ) sub
  where ur.user_id = sub.user_id;
end;
$$ language plpgsql;

-- try_validate_pending_clusters ora itera sui cluster appena validati
-- (non solo un UPDATE cieco) per poter accreditare la reputazione dei
-- rispettivi contributori.
create or replace function try_validate_pending_clusters() returns trigger as $$
declare
  v_cluster record;
begin
  for v_cluster in
    update event_clusters
      set status = 'validated',
          ingv_gate_ok = true,
          validated_at = now()
      where status = 'pending'
        and check_ingv_gate()
      returning id
  loop
    perform credit_reputation_for_cluster(v_cluster.id);
  end loop;

  return null;
end;
$$ language plpgsql;
