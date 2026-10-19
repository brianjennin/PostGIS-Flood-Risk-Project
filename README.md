# Flood Risk Exposure in Norfolk, VA (PostGIS)

How many buildings in Norfolk, Virginia sit in FEMA flood zones, and which neighborhoods are most exposed?

## Key Findings
_Coming soon._

## Data
| Dataset | Source |
|---|---|
| Flood zones | FEMA National Flood Hazard Layer (Norfolk, 2021) |
| Buildings, city boundary | Overture Maps |
| Neighborhoods | City of Norfolk Civic Leagues |

## Method
1. **Load:** sources loaded into PostGIS with `ogr2ogr`
2. **Clean:** reprojected to meters (EPSG:32618), invalid geometries repaired, clipped to Norfolk
3. **Analyze:** buildings joined to flood zones, summarized by zone type and neighborhood
4. **Map:** H3 hexagon heatmap and QGIS maps

## Repository
```
sql/        numbered SQL scripts (run in order)
scripts/    data download and load script
maps/       map images
```

## Skills
PostGIS · spatial joins · CRS handling · geometry cleaning · spatial indexing · H3 · QGIS