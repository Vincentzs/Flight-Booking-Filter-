-- Q5. Flight Hopping

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5 (
	destination CHAR(3),
	num_flights INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS day CASCADE;
DROP VIEW IF EXISTS n CASCADE;
DROP VIEW IF EXISTS hopping CASCADE;

CREATE VIEW day AS
SELECT day::date as day FROM q5_parameters;
-- can get the given date using: (SELECT day from day)

CREATE VIEW n AS
SELECT n FROM q5_parameters;
-- can get the given number of flights using: (SELECT n from n)

-- HINT: You can answer the question by writing one recursive query below, without any more views.
-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q5 

WITH RECURSIVE hopping AS (
	(SELECT inbound AS destination, 1 AS num_flights, s_arv
	FROM Flight JOIN day ON s_dep::date = day.day
	WHERE outbound = 'YYZ')
	UNION ALL 
	(SELECT inbound AS destination, (num_flights + 1), Flight.s_arv
	FROM hopping JOIN Flight ON hopping.destination = Flight.outbound 
	WHERE Flight.s_dep - hopping.s_arv < '24:00:00' AND Flight.s_dep - hopping.s_arv >= '0')
)

SELECT DISTINCT destination, num_flights 
FROM hopping
WHERE num_flights > 0;