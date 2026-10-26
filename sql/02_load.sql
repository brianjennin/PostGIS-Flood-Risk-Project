-- 02_load.sql
-- Goal: Verify the raw load (run on the flood_risk connection, port 5433).
-- Loading itself is done by scripts\load_data.cmd.

-- 1. SRID and geometry type of every raw table
--    Expect: fld_haz_ar = 4269 (NAD83), Overture tables = 4326 (WGS 84)
SELECT f_table_schema, f_table_name, f_geometry_column, srid, type
FROM geometry_columns
WHERE f_table_schema = 'raw'
ORDER BY f_table_name;

-- 2. Row count per table
SELECT 'buildings' AS table_name, count(*) AS row_count FROM raw.buildings
UNION ALL
SELECT 'division_area', count(*) FROM raw.division_area
UNION ALL
SELECT 'fld_haz_ar', count(*) FROM raw.fld_haz_ar
UNION ALL
SELECT 'places', count(*) FROM raw.places
ORDER BY table_name;

-- 3. Coordinate order check: x should be ~ -76, y ~ 36.8-37.0
--    (Swapped values would mean lon/lat were reversed somewhere.)
SELECT 'buildings' AS table_name, ST_Extent(geom) AS extent FROM raw.buildings
UNION ALL
SELECT 'division_area', ST_Extent(geom) FROM raw.division_area -- Returned -180 to 180, overture returned all of US/VA polygons because they overlap, harmless as later on I will filter by subtype
UNION ALL
SELECT 'fld_haz_ar', ST_Extent(geom) FROM raw.fld_haz_ar
UNION ALL
SELECT 'places', ST_Extent(geom) FROM raw.places;

-- 4. Flood zone breakdown
--    sfha_tf = 'T' marks the Special Flood Hazard Area (100-year floodplain)
SELECT
    fld_zone,
    zone_subty,
    sfha_tf,
    count(*) AS polygon_count
FROM raw.fld_haz_ar
GROUP BY fld_zone, zone_subty, sfha_tf
ORDER BY polygon_count DESC;

-- 5a. Which division types did Overture return?
SELECT subtype, class, count(*) AS n
FROM raw.division_area
GROUP BY subtype, class
ORDER BY subtype, class;

-- 5b. Neighborhood coverage: are there enough named neighborhoods to use?
SELECT subtype, (names::json)->>'primary' AS name
FROM raw.division_area
WHERE subtype IN ('locality', 'macrohood', 'neighborhood');

-- Norfolk boundary: confirm the county row exists
SELECT gid, subtype, class, (names::json)->>'primary' AS name
FROM raw.division_area
WHERE subtype = 'county';

-- What geometry types are actually inside the generic columns?
SELECT GeometryType(geom), count(*) FROM raw.buildings GROUP BY 1;
