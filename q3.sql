-- Q3. North and South Connections

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
    outbound VARCHAR(30),
    inbound VARCHAR(30),
    direct INT,
    one_con INT,
    two_con INT,
    earliest timestamp
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS CAIn CASCADE;
DROP VIEW IF EXISTS CAOut CASCADE;
DROP VIEW IF EXISTS USAIn CASCADE;
DROP VIEW IF EXISTS USAOut CASCADE;
DROP VIEW IF EXISTS direct CASCADE;
DROP VIEW IF EXISTS one_con CASCADE;
DROP VIEW IF EXISTS two_con CASCADE;
DROP VIEW IF EXISTS earliest CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW CAIn As
Select flight.id, airline, outbound, airport.city As arv_city, inbound, s_arv, s_dep
From flight, airport
Where inbound = airport.code
and airport.country = 'Canada'
and EXTRACT(Year From flight.s_dep) = 2022
and EXTRACT(Month From flight.s_dep) = 4
and EXTRACT(Day From flight.s_dep) = 30
and EXTRACT(Year From flight.s_arv) = 2022
and EXTRACT(Month From flight.s_arv) = 4
and EXTRACT(Day From flight.s_arv) = 30;

CREATE VIEW CAOut As
Select flight.id, airline, outbound, airport.city As dept_city, inbound, s_arv, s_dep
From flight, airport
Where airport.country = 'Canada'
and outbound = airport.code
and EXTRACT(Year From flight.s_dep) = 2022
and EXTRACT(Month From flight.s_dep) = 4
and EXTRACT(Day From flight.s_dep) = 30
and EXTRACT(Year From flight.s_arv) = 2022
and EXTRACT(Month From flight.s_arv) = 4
and EXTRACT(Day From flight.s_arv) = 30;

CREATE VIEW USAIn As
Select flight.id, airline, outbound, airport.city As arv_city, inbound, s_arv, s_dep
From flight, airport
Where inbound = airport.code
and airport.country = 'USA'
and EXTRACT(Year From flight.s_dep) = 2022
and EXTRACT(Month From flight.s_dep) = 4
and EXTRACT(Day From flight.s_dep) = 30
and EXTRACT(Year From flight.s_arv) = 2022
and EXTRACT(Month From flight.s_arv) = 4
and EXTRACT(Day From flight.s_arv) = 30;

CREATE VIEW USAOut As
Select flight.id, airline, outbound, airport.city As dept_city, inbound, s_arv, s_dep
From flight, airport
Where airport.country = 'USA'
and outbound = airport.code
and EXTRACT(Year From flight.s_dep) = 2022
and EXTRACT(Month From flight.s_dep) = 4
and EXTRACT(Day From flight.s_dep) = 30
and EXTRACT(Year From flight.s_arv) = 2022
and EXTRACT(Month From flight.s_arv) = 4
and EXTRACT(Day From flight.s_arv) = 30;

CREATE VIEW direct As
(Select dept_city As outbound, arv_city As inbound,
Count(CAOut.id) As direct, 0 As one_con, 0 As two_con, min(USAIn.s_arv) As earliest
From CAOut, USAIn
Where CAOut.id = USAIn.id
Group By dept_city, arv_city)
UNION
(Select dept_city As outbound, arv_city As inbound, 
Count(USAOut.id) As direct, 0 As one_con, 0 As two_con, min(CAIn.s_arv) As earliest
From USAOut, CAIn
Where USAOut.id = CAIn.id
Group By dept_city, arv_city);


CREATE VIEW one_con As
(Select dept_city As outbound, arv_city As inbound, 0 As direct,
Count(CAOut.id) As one_con, 0 As two_con, 
min(USAIn.s_arv) As earliest
From CAOut, USAIn
Where CAOut.id <> USAIn.id
and CAOut.inbound = USAIn.outbound
and CAOut.s_arv + interval '30 minutes' <= USAIn.s_dep
Group By dept_city, arv_city)
UNION
(Select dept_city As outbound, arv_city As inbound, 0 As direct,
Count(USAOut.id) As one_con, 0 As two_con, 
min(CAIn.s_arv) As earliest
From USAOut, CAIn
Where USAOut.id <> CAIn.id
and USAOut.inbound = CAIn.outbound
and USAOut.s_arv + interval '30 minutes' <= CAIn.s_dep
Group By dept_city, arv_city);

CREATE VIEW two_con As
(Select dept_city As outbound, arv_city As inbound, 0 As direct, 0 As one_con,
Count(CAOut.id) As two_con, min(USAIn.s_arv) As earliest
From CAOut, USAIn, flight
Where CAOut.id <> USAIn.id
and CAOut.id <> flight.id
and flight.id <> USAIn.id
and CAOut.inbound = flight.outbound
and flight.inbound = USAIn.outbound
and CAOut.s_arv + interval '30 minutes' <= flight.s_dep
and flight.s_arv + interval '30 minutes' <= USAIn.s_dep
Group By dept_city, arv_city)
UNION
(Select dept_city As outbound, arv_city As inbound, 0 As direct, 0 As one_con,
Count(USAOut.id) As two_con, min(CAIn.s_arv) As earliest
From USAOut, CAIn, flight
Where USAOut.id <> CAIn.id
and USAOut.id <> flight.id
and flight.id <> CAIn.id
and USAOut.inbound = flight.outbound
and flight.inbound = CAIn.outbound
and USAOut.s_arv + interval '30 minutes' <= flight.s_dep
and flight.s_arv + interval '30 minutes' <= CAIn.s_dep
Group By dept_city, arv_city);

CREATE VIEW earliest As (Select * From direct) UNION (Select * From one_con) UNION (Select * From two_con);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3
Select outbound, inbound, max(direct), max(one_con), max(two_con), min(earliest)
From earliest
Group By outbound, inbound;
