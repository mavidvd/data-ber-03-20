CREATE DATABASE coursereport;

CREATE TABLE coursereport.coding (
    date_id DATE,
    bootcamp_type TEXT,
    `rank` INT,
    name TEXT,
    rating FLOAT,
    stars FLOAT,
    reviews INT,
    locations TEXT,
    description TEXT);

CREATE TABLE coursereport.data_science (
    date_id DATE,
    bootcamp_type TEXT,
    `rank` INT,
    name TEXT,
    rating FLOAT,
    stars FLOAT,
    reviews INT,
    locations TEXT,
    description TEXT);

CREATE TABLE coursereport.online (
    date_id DATE,
    bootcamp_type TEXT,
    `rank` INT,
    name TEXT,
    rating FLOAT,
    stars FLOAT,
    reviews INT,
    locations TEXT,
    description TEXT);

INSERT INTO coursereport.coding VALUES
    ('2020-05-12',
     'online',
     1,
     'AcadGild',
     4.30,
     4.0,
     172,
     'Bangalore|Online',
     'AcadGild is an online coding bootcamp offering.'),
     ('2020-05-12',
     'online',
     1,
     'AcadGild',
     4.30,
     4.0,
     172,
     'Bangalore|Online',
     'AcadGild is an online coding bootcamp offering.');

SELECT *
FROM coursereport.coding
WHERE date_id = '2020-05-14';

TRUNCATE TABLE coursereport.coding;


