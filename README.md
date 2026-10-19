\# Flood Risk Exposure in Norfolk, Virginia — a PostGIS Analysis



\*\*Question:\*\* How many buildings in Norfolk, VA sit inside FEMA flood hazard zones, and where is that exposure concentrated?



Norfolk is one of the most flood-exposed cities on the U.S. East Coast. This project measures building-level exposure to FEMA's mapped flood hazard zones and summarizes it by flood zone type, by neighborhood (civic league), and on an H3 hexagon grid, using spatial SQL in PostGIS.



\## Key Findings



\_TBD — e.g. "X% of Norfolk's buildings sit in the 100-year floodplain (FEMA SFHA), concentrated in …"\_



\## Data Sources



| Dataset | Source | Notes |

|---|---|---|

| Flood hazard zones (`S\_FLD\_HAZ\_AR`) | \[FEMA National Flood Hazard Layer](https://msc.fema.gov/portal/advanceSearch), community 510104 | Effective data dated 2021-10-27; EPSG:4269 |

| Building footprints | \[Overture Maps](https://overturemaps.org/) `building` | EPSG:4326 |

| City boundary | Overture Maps `division\_area` (subtype `county`, Norfolk is an independent city) | EPSG:4326 |

| Points of interest | Overture Maps `place` | EPSG:4326 |

| Neighborhoods | \[City of Norfolk Civic Leagues](https://gisshare.norfolk.gov/pubserver/rest/services/OpenData/Maps/MapServer/12) (ArcGIS REST) | 123 civic leagues; EPSG:4326 |



Overture's own neighborhood polygons covered only 10 Norfolk neighborhoods, so the city's civic league boundaries are used instead. Personal contact fields in that layer (league president names, emails, addresses) are dropped during cleaning and never published.



\## Method



The database is organized as a three-stage pipeline:



| Schema | Contents |

|---|---|

| `raw` | Source data exactly as loaded (original CRS, no index) |

| `clean` | Reprojected to EPSG:32618 (UTM 18N, meters), geometries repaired, clipped to Norfolk, strictly typed, indexed |

| `analysis` | Views and materialized views with the results |



1\. \*\*Setup:\*\* dedicated `flood\_risk` database, PostGIS extension, schemas, CRS checks.

2\. \*\*Load:\*\* `ogr2ogr` loads the shapefile, GeoJSON and ArcGIS REST sources into `raw`. Load results are checked for SRID, geometry type, row counts and coordinate order.

3\. \*\*Clean:\*\* `ST\_Transform` to a metric CRS, `ST\_MakeValid` repairs, `ST\_Union` dissolves flood zones, buildings are clipped to the city with `ST\_PointOnSurface`, and GIST indexes are benchmarked with `EXPLAIN ANALYZE`.

4\. \*\*Analysis:\*\* \_TBD.\_ Spatial joins (`ST\_Intersects` vs `ST\_Within`), partial overlap (`ST\_Intersection` + `ST\_Area`), and 100 m buffers around high-risk zones.

5\. \*\*H3 aggregation:\*\* \_TBD.\_ Hexagon heatmap of exposure.

6\. \*\*Maps:\*\* \_TBD.\_



\*\*Flood risk classes used:\*\*



| Class | FEMA definition |

|---|---|

| SFHA (100-yr) | `SFHA\_TF = 'T'`, zones AE, VE, AO, AH. 1% annual chance flood |

| 0.2% (500-yr) | Zone X, 0.2% annual chance flood hazard |

| Minimal | Zone X, area of minimal flood hazard |



\## Maps



\_TBD\_



\## Repository Structure



```

sql/

&#x20; 01\_setup.sql        database, extension, schemas, CRS sanity checks

&#x20; 02\_load.sql         verification of the raw load

&#x20; 03\_clean.sql        reprojection, validity repair, clipping, indexes   (TBD)

&#x20; 04\_analysis.sql     exposure analysis                                   (TBD)

&#x20; 05\_h3.sql           H3 hexagon aggregation                              (TBD)

scripts/

&#x20; load\_data.cmd       downloads Overture data and loads all sources with ogr2ogr

maps/                 exported map images                                (TBD)

data/                 raw downloads (git-ignored)

```



\## Reproduce



Requirements: Docker (PostGIS 16 + 3.4 image, on port 5433), QGIS / OSGeo4W Shell (`ogr2ogr`), Python with `pip install overturemaps`.



1\. Run `sql/01\_setup.sql` (Part A on the `postgres` database, Part B on `flood\_risk`).

2\. Download the FEMA NFHL for Norfolk (community 510104) and unzip it to `data/nfhl/`.

3\. From the repo root in the OSGeo4W Shell, run `scripts\\load\_data.cmd`.

4\. Run `sql/02\_load.sql` to verify the load, then the remaining scripts in order.



\## Skills Demonstrated



\- Loading real-world spatial data from shapefile, GeoJSON and ArcGIS REST with `ogr2ogr`

\- CRS handling: mixed sources (EPSG:4269 / 4326) reprojected to a metric CRS (EPSG:32618)

\- Data cleaning: `ST\_IsValid`, `ST\_MakeValid`, `ST\_CollectionExtract`, `ST\_Union`, strictly typed geometry columns

\- GIST spatial indexing benchmarked with `EXPLAIN ANALYZE` \_(TBD)\_

\- Spatial joins, partial-overlap area calculation, buffers \_(TBD)\_

\- H3 hexagon aggregation \_(TBD)\_

\- Reproducible pipeline: schema-staged SQL scripts, load script, git-ignored raw data



\## Limitations



\- FEMA zones show \*mapped\* regulatory hazard, not all flood risk. Rainfall flooding and sea-level rise are not fully captured.

\- Building footprints come from open data and may be incomplete.

\- Civic leagues don't cover the whole city. Buildings outside every league are reported as "unassigned".

