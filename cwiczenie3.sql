-- OBIEKTY

CREATE TABLE obiekty(id INT NOT NULL, geometria GEOMETRY);
ALTER TABLE obiekty ADD nazwa VARCHAR(15);

INSERT INTO obiekty VALUES (1, ST_COLLECT(
Array [
	'LINESTRING(0 1, 1 1)',
	'CIRCULARSTRING(1 1, 2 0, 3 1)',
	'CIRCULARSTRING(3 1, 4 2, 5 1)',
	'LINESTRING(5 1, 6 1)'
]), 'obiekt1');

INSERT INTO obiekty VALUES (2, ST_COLLECT(
Array [
	'LINESTRING(10 2, 10 6, 14 6)',
	'CIRCULARSTRING(14 6, 16 4, 14 2)',
	'CIRCULARSTRING(14 2, 12 0, 10 2)',
	'CIRCULARSTRING(11 2, 13 2, 11 2)'
]), 'obiekt2');

INSERT INTO obiekty VALUES (3, ST_MakePolygon('LINESTRING(7 15, 10 17, 12 13, 7 15)'), 'obiekt3');

INSERT INTO obiekty VALUES (4, ST_LineFromMultiPoint('MULTIPOINT(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)'), 'obiekt4');

INSERT INTO obiekty VALUES (5, ST_Collect('POINT(30 30 9)', 'POINT(38 32 234)'), 'obiekt5');

INSERT INTO obiekty VALUES (6, ST_Collect('POINT(4 2)', 'LINESTRING(1 1, 3 2)'), 'obiekt5');

-- Zadanie 1

SELECT ST_Area(ST_Buffer(ST_ShortestLine(a.geometria, b.geometria), 5, 'endcap=round join=round'))
FROM obiekty a, obiekty b
WHERE a.nazwa='obiekt3' AND b.nazwa='obiekt4';

-- Zadanie 2

SELECT ST_AsText(ST_MakePolygon(ST_AddPoint(geometria, ST_StartPoint(geometria))))
FROM obiekty 
WHERE nazwa='obiekt4';

-- Zadanie 3

INSERT INTO obiekty 
SELECT 7, ST_Collect(a.geometria, b.geometria), 'obiekt7'
FROM obiekty a, obiekty b
WHERE a.nazwa='obiekt3' AND b.nazwa='obiekt4';

-- Zadanie 4

SELECT SUM(ST_AREA(ST_BUFFER(geometria,5)))
FROM obiekty
WHERE ST_HASARC(geometria)=false;
SELECT ST_asText(geometria) FROM obiekty;





