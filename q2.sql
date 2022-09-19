-- Q2. Refunds!

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2 (
    airline CHAR(2),
    name VARCHAR(50),
    year CHAR(4),
    seat_class seat_class,
    refund REAL
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS flight_country CASCADE;
DROP VIEW IF EXISTS flight_delay CASCADE;
DROP VIEW IF EXISTS dom_refund CASCADE;
DROP VIEW IF EXISTS int_refund CASCADE;
DROP VIEW IF EXISTS total_refund CASCADE;


-- Define views for your intermediate steps here:

CREATE VIEW flight_country AS (
    SELECT Flight.id, 
        airline, Airline.name, 
        A1.country AS outbound, A2.country AS inbound,
        price, seat_class,
        s_dep, s_arv
    FROM Flight 
        JOIN Airport A1 ON Flight.outbound = A1.code 
        JOIN Airport A2 ON Flight.inbound = A2.code
        JOIN Airline ON Airline.code = Flight.airline
        JOIN Booking ON Booking.flight_id = Flight.id
);

CREATE VIEW flight_delay AS (
    SELECT flight_country.id, airline, name, outbound = inbound AS dom,
        EXTRACT(year FROM Departure.datetime) AS year, seat_class, price,
        Departure.datetime - s_dep AS dep_delay,
        Arrival.datetime - s_arv AS arv_delay
    FROM flight_country 
        JOIN Departure ON flight_country.id = Departure.flight_id
        JOIN Arrival ON flight_country.id = Arrival.flight_id
);

-- below are refunds not including flights pilots make up times
CREATE VIEW dom_refund AS (
    (
        SELECT airline, name, year, seat_class, 0.35 * price as refund, dep_delay, arv_delay
        FROM flight_delay
        WHERE dom AND dep_delay >= '5:00:00' AND dep_delay < '10:00:00'
    ) 
    UNION
    (
        SELECT airline, name, year, seat_class, 0.5 * price as refund, dep_delay, arv_delay
        FROM flight_delay
        WHERE dom AND dep_delay >= '10:00:00'
    )
);

CREATE VIEW int_refund AS (
    (
        SELECT airline, name, year, seat_class, 0.35 * price as refund, dep_delay, arv_delay
        FROM flight_delay
        WHERE NOT dom AND dep_delay >= '8:00:00' AND dep_delay < '12:00:00'
    ) 
    UNION
    (
        SELECT airline, name, year, seat_class, 0.5 * price as refund, dep_delay, arv_delay
        FROM flight_delay
        WHERE NOT dom AND dep_delay >= '12:00:00'
    )
);

CREATE VIEW total_refund AS (
    (SELECT * FROM dom_refund) 
    UNION 
    (SELECT * FROM int_refund)
);


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2
(
    SELECT airline, name, year, seat_class, sum(refund) as refund
    FROM total_refund
    WHERE 2 * arv_delay > dep_delay
    GROUP BY airline, name, year, seat_class
);
