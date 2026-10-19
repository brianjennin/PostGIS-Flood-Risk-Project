-- 01_setup.sql
-- Goal: Create flood_risk database, enable PostGIS, create schemas,
--       and run version / CRS sanity checks.

-- Run once. Errors harmlessly if flood_risk already exists.
CREATE DATABASE flood_risk;
SELECT current_database();

CREATE EXTENSION IF NOT EXISTS postgis;

-- Create the three working schemas
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS clean;
CREATE SCHEMA IF NOT EXISTS analysis;

-- Version check
SELECT postgis_full_version() AS postgis_version;

-- Sanity check: compare source CRS (4326, degrees) with working CRS (32618, meters)
SELECT
    srid,
    auth_name || ':' || auth_srid AS code,
    proj4text,
    srtext
FROM spatial_ref_sys
WHERE srid IN (4326, 32618)
ORDER BY srid;
