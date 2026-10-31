-- 03_clean.sql
-- Goal: Reproject all layers to 32618, repair invalid geometries, clip MultiPolygon geometries to Norfolk

--1. Validatity check: Count the invalid geometries in raw tables
SELECT 'buildings' AS table_name, count(*) FILTER (WHERE NOT ST_IsValid(geom)) AS row_count FROM raw.buildings
UNION ALL
SELECT 'division_area', count(*) FILTER (WHERE NOT ST_IsValid(geom)) FROM raw.division_area
UNION ALL
SELECT 'fld_haz_ar', count(*) FILTER (WHERE NOT ST_IsValid(geom)) FROM raw.fld_haz_ar -- Only invalid geometry here, keep query for intent purposes
UNION ALL
SELECT 'civic_leagues', count(*) FILTER (WHERE NOT ST_IsValid(geom)) FROM raw.civic_leagues
UNION ALL 
SELECT 'places', count(*) FILTER (WHERE NOT ST_IsValid(geom)) FROM raw.places
ORDER BY table_name;

-- View only invalid geometry reason in the raw tables
SELECT gid, ST_IsValidReason(geom) FROM raw.fld_haz_ar WHERE NOT ST_IsValid(geom); -- Ring self-intersection

-- 2. Get Norfolk city boundary: clip polygon for all other layers.
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

-- Sanity check: Norfolk land area should be ~170 km² (legal boundary incl. inland waterways)
SELECT name, round((ST_Area(geom) / 1e6)::numeric, 1) AS area_km2
FROM clean.norfolk_boundary;

-- 3. Cleaning the Flood Zones table
DROP TABLE IF EXISTS clean.flood_zones;
CREATE TABLE clean.flood_zones AS 
SELECT 
	gid,
	fld_zone,
	zone_subty,
	sfha_tf,
	ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_Transform(geom, 32618)), 3))
		::geometry(MultiPolygon, 32618) AS geom,
	CASE
		WHEN sfha_tf = 'T' THEN 'SFHA (100-yr)'
		WHEN zone_subty LIKE '0.2 PCT%' THEN '0.2% (500-yr)'
		ELSE 'Minimal'
	END AS risk_class
FROM raw.fld_haz_ar
WHERE NOT fld_zone = 'OPEN WATER';

-- Add a primary key
ALTER TABLE clean.flood_zones ADD PRIMARY KEY (gid);

-- 4. Dissolve flood zone polygons 
DROP TABLE IF EXISTS clean.dissolved_flood_zones;
CREATE TABLE clean.dissolved_flood_zones AS 
SELECT 
	risk_class,
	ST_Multi(ST_Union(geom))::geometry(MultiPolygon, 32618) AS geom


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