-- 03_clean.sql
-- Goal: Reproject all layers to 32618, repair invalid geometries, clip MultiPolygon geometries to Norfolk

-- 1. Cleaning the Buildings table
CREATE TABLE clean.buildings AS
SELECT 
    gid,
    id,
    height,
    num_floors,
    subtype,
    class,
    ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_Transform(geom, 32618)), 3))::geometry(MultiPolygon, 32618) AS geom
FROM 
    raw.buildings;