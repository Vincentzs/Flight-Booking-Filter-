-- Q1. Airlines
-- You must not change the next 2 lines or the TABLE definition.

SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1 ( 
    pass_id INT, 
    name VARCHAR(100), 
    airlines INT 
);
-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.

DROP VIEW IF EXISTS flight_info CASCADE;
-- Define views for your intermediate steps here:


-- Your query that answers the question goes below the "INSERT INTO" line:
INSERT INTO q1
(
    SELECT  Passenger.id AS pass_id, firstname || ' ' || surname AS name, count(DISTINCT airline) AS airlines
    FROM Passenger LEFT JOIN Booking ON Passenger.id = pass_id 
        JOIN Flight ON flight_id = Flight.id
    GROUP BY Passenger.id, firstname, surname
);