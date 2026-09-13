-- =====================================================================
-- CenereAlert — Sprint LUOGHI SALVATI
-- Vista comoda per la lettura: espone lat/lon esplicite invece della
-- colonna geography grezza, più semplice da consumare da PostgREST/Flutter.
-- =====================================================================
create or replace view saved_places_view as
select
  id,
  user_id,
  label,
  st_y(position::geometry) as latitude,
  st_x(position::geometry) as longitude,
  alert_radius_km
from saved_places;

-- La vista NON bypassa la RLS della tabella sottostante: le policy si
-- basano su auth.uid(), valutato per sessione indipendentemente
-- dall'indirection della vista. Resta quindi leggibile solo dal
-- proprietario di ciascuna riga, esattamente come la tabella base.
grant select on saved_places_view to authenticated;
