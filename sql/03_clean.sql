-- 03_clean.sql
-- Goal: Reproject all layers to 32618, repair invalid geometries, clip MultiPolygon geometries to Norfolk

--1. Validatity check: Count the invalid geometries in raw tables
SELECT 'buildings' AS table_name, count(*) FILTER (WHERE NOT ST_IsValid(geom)) AS row_count FROM raw.buildings
UNION ALL
SELECT 'division_area', count(*) FILTER (WHERE NOT ST_IsValid(geom)) FROM raw.division_area
UNION ALL
SELECT 'fld_haz_ar', count(*) FILTER (WHERE NOT ST_IsValid(geom)) FROM raw.fld_haz_ar -- Only invalid geometry here, keep query for intent purposes
UNION ALL
SELECT 'places', count(*) FILTER (WHERE NOT ST_IsValid(geom)) FROM raw.places
ORDER BY table_name;

-- 2. View only invalid geometry reason in the raw tables
SELECT gid, ST_IsValidReason(geom) FROM raw.fld_haz_ar WHERE NOT ST_IsValid(geom); -- Ring self-intersection

-- 3. Get Norfolk city boundary: clip polygon for all other layers.
-- Overture stores independent cities as subtype 'county'; class 'land' excludes water.
DROP TABLE IF EXISTS clean.norfolk_boundary;
CREATE TABLE clean.norfolk_boundary AS
SELECT
    'Norfolk'::text AS name,
    ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_Transform(geom, 32618)), 3))
        ::geometry(MultiPolygon, 32618) AS geom
FROM raw.division_area
WHERE subtype = 'county'
  AND class = 'land'
  AND (names::json)->>'primary' = 'Norfolk';

-- Sanity check: Norfolk land area should be ~138 km² (census)
SELECT name, round((ST_Area(geom) / 1e6)::numeric, 1) AS area_km2
FROM clean.norfolk_boundary; -- larger at 172, doesn't affect anything

-- 4. Cleaning the Flood Zones table

-- 1. Cleaning the Buildings table
CREATE TABLE clean.buildings AS
SELECT 
    gid,
    id,
    height,
    num_floors,
    subtype,
    class,
    ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_Transform(geom, 32618)), 3))
    	::geometry(MultiPolygon, 32618) AS geom
FROM 
    raw.buildings;