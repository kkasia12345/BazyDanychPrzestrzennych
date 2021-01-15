CREATE EXTENSION postgis;

--Zad4

CREATE TABLE tableB AS
SELECT DISTINCT a.gid, a.cat, a.f_codedesc, a.f_code, a.type, a.geom 
FROM popp a, majrivers b
WHERE popp.f_codedesc = 'Building' 
AND ST_DWithin(a.geom, b.geom, 100000);

--Zad5
CREATE TABLE airportsNew AS
SELECT name, geom, elev 
FROM airports;

--a
SELECT name AS airport_east, ST_X(geom) AS coords_e
FROM airportsNew
ORDER BY coords LIMIT 1

SELECT name AS airport_west, ST_X(geom) AS coords_w
FROM airportsNew
ORDER BY coords DESC LIMIT 1

--b
INSERT INTO airportsNew 
VALUES ('airportB', (SELECT ST_Centroid 
  (ST_ShortestLine(
  (SELECT geom FROM airportsNew WHERE name LIKE 'NIKOLSKI AS'),
  (SELECT geom FROM airportsNew WHERE name LIKE 'NOATAK')))), 
  100);


--Zad6
SELECT ST_Area(ST_Buffer(ST_ShortestLine(a.geom, b.geom), 1000)) AS squared_buffer1000
FROM airports a, lakes b
WHERE a.name='AMBLER' AND b.name='Iliamna Lake';

--Zad7
SELECT (SUM(t.area_km2)+SUM(b.areakm2)) suma, d.vegdesc gatunek FROM  trees d, tundra t , swamp b
WHERE t.area_km2 IN (SELECT t.area_km2 FROM tundra t, trees d 
					 WHERE ST_CONTAINS(d.geom,t.geom) = 'true') AND b.areakm2  IN (SELECT b.areakm2 FROM swamp b, trees d 

