-- Q4. Plane Capacity Histogram

-- You must not change the next 2 lines or the table definitiOn.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
	airline CHAR(2),
	tail_number CHAR(5),
	very_low INT,
	low INT,
	fair INT,
	normal INT,
	high INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS depart CASCADE;
DROP VIEW IF EXISTS no_depart CASCADE;
DROP VIEW IF EXISTS very_low CASCADE;
DROP VIEW IF EXISTS low CASCADE;
DROP VIEW IF EXISTS fair CASCADE;
DROP VIEW IF EXISTS normal CASCADE;
DROP VIEW IF EXISTS high CASCADE;
DROP VIEW IF EXISTS all_depart CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW depart As
Select flight.airline, tail_number, count(booking.id) As occupied,
capacity_economy + capacity_business + capacity_first As capacity
From flight, plane, booking, departure
Where flight.plane = plane.tail_number
and booking.flight_id = flight.id
and departure.flight_id = flight.id
Group By flight.airline, tail_number;

CREATE VIEW no_depart As
Select airline, tail_number, 
0 As very_low, 0 As low, 0 As fair, 0 As normal, 0 As high
From plane
Where (airline, tail_number) not in 
(Select airline, tail_number From depart);

CREATE VIEW very_low As
Select airline, tail_number, 
1 As very_low, 0 As low, 0 As fair, 0 As normal, 0 As high
From depart
Where occupied/capacity >= 0
and occupied/capacity < 0.2;

CREATE VIEW low As
Select airline, tail_number, 
0 As very_low, 1 As low, 0 As fair, 0 As normal, 0 As high
From depart
Where occupied/capacity >= 0.2
and occupied/capacity < 0.4;

CREATE VIEW fair As
Select airline, tail_number, 
0 As very_low, 0 As low, 1 As fair, 0 As normal, 0 As high
From depart
Where occupied/capacity >= 0.4
and occupied/capacity < 0.6;

CREATE VIEW normal As
Select airline, tail_number, 
0 As very_low, 0 As low, 0 As fair, 1 As normal, 0 As high
From depart
Where occupied/capacity >= 0.6
and occupied/capacity < 0.8;

CREATE VIEW high As
Select airline, tail_number, 
0 As very_low, 0 As low, 0 As fair, 1 As normal, 0 As high
From depart
Where occupied/capacity >= 0.8
and occupied/capacity <= 1.0;


CREATE VIEW all_depart As
(Select * From no_depart)
UNION
(Select * From very_low)
UNION
(Select * From low)
UNION
(Select * From fair)
UNION
(Select * From normal)
UNION
(Select * From high);

-- Your query that answers the questiOn goes below the "insert into" line:
INSERT INTO q4
Select * From all_depart;
