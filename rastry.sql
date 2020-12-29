
--Ładowanie danych:

cd C:\Program Files\PostgreSQL\13\bin\

raster2pgsql.exe -s 3763 -N -32767 -t 100x100 -I -C -M -d C:\Users\Lenovo\Desktop\STudia3\BazyDanych\rasters\srtm_1arc_v3.tif rasters.dem | psql -d restored -h localhost -U postgres -p 5432

raster2pgsql.exe -s 3763 -N -32767 -t 128x128 -I -C -M -d C:\Users\Lenovo\Desktop\STudia3\BazyDanych\rasters\Landsat8_L1TP_RGBN.TIF rasters.landsat8 | psql -d restored -h localhost -U postgres -p 5432


-- 1) Tworzenie rastrów z istniejących rastrów:
-- Raster nakłądający się z wektorem (ST_Intersect)
CREATE TABLE kowalczyk.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b 
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

ALTER TABLE kowalczyk.intersects
ADD COLUMN rid SERIAL PRIMARY KEY;

CREATE INDEX idx_intersects_rast_gist ON kowalczyk.intersects
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('kowalczyk'::name, 'intersects'::name,'rast'::name);

--Przykład 2

CREATE TABLE kowalczyk.clip AS 
SELECT ST_Clip(a.rast, b.geom, true), b.municipality 
FROM rasters.dem AS a, vectors.porto_parishes AS b 
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

--Przykład 3

CREATE TABLE kowalczyk.union AS 
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b 
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);

--2)Tworzenie rastrów z wektorów

--Przykład 1
CREATE TABLE kowalczyk.porto_parishes AS
WITH r AS (SELECT rast FROM rasters.dem LIMIT 1)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--Przykład 2
DROP TABLE kowalczyk.porto_parishes;
CREATE TABLE kowalczyk.porto_parishes AS
WITH r AS (SELECT rast FROM rasters.dem LIMIT 1)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--Przykład 3
DROP TABLE kowalczyk.porto_parishes;
CREATE TABLE kowalczyk.porto_parishes AS
WITH r AS (SELECT rast FROM rasters.dem LIMIT 1)
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--3)Konwertowanie rastrów na wektory

--Przykład 1
CREATE TABLE kowalczyk.intersection as 
SELECT a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b 
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--Przykład 2
CREATE TABLE kowalczyk.dumppolygons AS
SELECT a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b 
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


--4)Analiza rastrów

--Przykład 1
CREATE TABLE kowalczyk.landsat_nir ASSELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

--Przykład 2
CREATE TABLE kowalczyk.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--Przykład 3
CREATE TABLE kowalczyk.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM kowalczyk.paranhos_dem AS a;

--Przykład 4
CREATE TABLE kowalczyk.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3', '32BF',0)
FROM kowalczyk.paranhos_slope AS a;

--Przykład 5
SELECT st_summarystats(a.rast) AS stats
FROM kowalczyk.paranhos_dem AS a;

--Przykład 6
SELECT st_summarystats(ST_Union(a.rast))
FROM kowalczyk.paranhos_dem AS a;

--Przykład 7
WITH t AS (SELECT st_summarystats(ST_Union(a.rast)) AS statsFROM kowalczyk.paranhos_dem AS a)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

--Przykład 8
WITH t AS (
    SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast, b.geom,true))) AS stats
    FROM rasters.dem AS a, vectors.porto_parishes AS b
    WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
    GROUP BY b.parish)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

--Przykład 9
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

--Przykład 10
CREATE TABLE kowalczyk.tpi30 as
SELECT ST_TPI(a.rast,1) as rast
FROM rasters.dem a;

CREATE INDEX idx_tpi30_rast_gist ON kowalczyk.tpi30
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('kowalczyk'::name, 'tpi30'::name,'rast'::name);


-- 5)Algebra map

--Przykład 1
CREATE TABLE kowalczyk.porto_ndvi AS 
WITH r AS (
    SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
    FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
    WHERE b.municipality ilike 'porto'and ST_Intersects(b.geom,a.rast))
SELECT
    r.rid,ST_MapAlgebra(
        r.rast, 1,
        r.rast, 4,
        '([rast2.val] -[rast1.val]) / ([rast2.val] + 
        [rast1.val])::float','32BF'
        ) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi_rast_gist ON kowalczyk.porto_ndvi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('kowalczyk'::name, 'porto_ndvi'::name,'rast'::name);

--Przykład 2
create or replace function kowalczyk.ndvi(
    value double precision [] [] [], 
    pos integer [][],
    VARIADIC userargs text []
)RETURNS double precision AS
$$
BEGIN
--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
RETURN (value [2][1][1] -value [1][1][1])/(value [2][1][1]+value [1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

CREATE TABLE kowalczyk.porto_ndvi2 AS 
WITH r AS (
    SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
    FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
    WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
    r.rast, ARRAY[1,4],
    'kowalczyk.ndvi(double precision[], 
    integer[],text[])'::regprocedure, --> This is the function!
    '32BF'::text) 
    AS rast
FROM r;

CREATE INDEX idx_porto_ndvi2_rast_gist ON kowalczyk.porto_ndvi2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('kowalczyk'::name, 'porto_ndvi2'::name,'rast'::name);

--6) Eksport danych

--Przykład 1
SELECT ST_AsTiff(ST_Union(rast))FROM kowalczyk.porto_ndvi;

--Przykład 2
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
FROM kowalczyk.porto_ndvi

--Przykład 3
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,ST_AsGDALRaster(ST_Union(rast), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])) AS loid
FROM kowalczyk.porto_ndvi;----------------------------------------------
SELECT lo_export(loid, 'C:\myraster.tiff') 
FROM tmp_out;
SELECT lo_unlink(loid)
FROM tmp_out;

--Przykład 4
gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9 PG:"host=localhost port=5432 dbname=postgis_raster user=postgres password=postgis schema=kowalczyk table=porto_ndvi mode=2" porto_ndvi.tiff










