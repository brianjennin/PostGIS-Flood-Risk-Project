@echo off
REM ============================================================================
REM load_data.cmd
REM Goal: Download Overture data and load all source layers into the raw schema.
REM
REM Run from the repo root in the OSGeo4W Shell (provides ogr2ogr).
REM Requires: overturemaps CLI (pip install overturemaps), flood_risk database
REM           created by sql\01_setup_sql.sql, PostGIS container on port 5433.
REM
REM FEMA NFHL is a manual download (no stable direct URL):
REM   msc.fema.gov/portal/advanceSearch > Virginia > Norfolk (Independent City)
REM   > NFHL data, community 510104. Unzip to data\nfhl\.
REM
REM Raw tables keep their source CRS (NFHL = EPSG:4269, Overture = EPSG:4326).
REM Reprojection to EPSG:32618 happens in sql\03_clean.sql.
REM SPATIAL_INDEX=NONE is deliberate: GIST indexes are built in 03_clean.sql so
REM the EXPLAIN ANALYZE before/after comparison can be shown.
REM ============================================================================

REM Password is never stored in the repo: prompt if not already set.
if not defined PGPASSWORD set /p PGPASSWORD=Postgres password:

set PG=PG:"host=localhost port=5433 dbname=flood_risk user=postgres"
set LCO=-lco GEOMETRY_NAME=geom -lco FID=gid -lco SPATIAL_INDEX=NONE

REM Bounding box = NFHL extent (from ogrinfo) padded ~500 m. Order: W,S,E,N
set BBOX=-76.350,36.815,-76.170,36.977

REM ---- 1. Download Overture layers -------------------------------------------
if not exist data\overture mkdir data\overture

overturemaps download --bbox=%BBOX% -f geojson --type=building      -o data\overture\buildings.geojson     || exit /b 1
overturemaps download --bbox=%BBOX% -f geojson --type=division_area -o data\overture\division_area.geojson || exit /b 1
overturemaps download --bbox=%BBOX% -f geojson --type=place         -o data\overture\places.geojson        || exit /b 1

REM ---- 2. Load FEMA flood hazard zones ----------------------------------------
REM PROMOTE_TO_MULTI: shapefile mixes Polygon/MultiPolygon.
REM PRECISION=NO: avoid shapefile numeric width errors.
ogr2ogr -f PostgreSQL %PG% data\nfhl\S_FLD_HAZ_AR.shp -nln raw.fld_haz_ar -nlt PROMOTE_TO_MULTI %LCO% -lco PRECISION=NO -overwrite || exit /b 1

REM ---- 3. Load Overture layers -----------------------------------------------
ogr2ogr -f PostgreSQL %PG% data\overture\buildings.geojson     -nln raw.buildings     -nlt PROMOTE_TO_MULTI %LCO% -overwrite || exit /b 1
ogr2ogr -f PostgreSQL %PG% data\overture\division_area.geojson -nln raw.division_area -nlt PROMOTE_TO_MULTI %LCO% -overwrite || exit /b 1
REM places are points: no PROMOTE_TO_MULTI
ogr2ogr -f PostgreSQL %PG% data\overture\places.geojson        -nln raw.places        %LCO% -overwrite || exit /b 1

echo All layers loaded into raw schema.
