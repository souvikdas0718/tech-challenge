-- Create Database and Schema
CREATE DATABASE netflix_demo_db;
CREATE SCHEMA netflix_demo_analytics;

USE DATABASE netflix_demo_db;
USE SCHEMA netflix_demo_analytics;

-- Create Dimension tables
CREATE TABLE dimension_country (
    countryID INT AUTOINCREMENT PRIMARY KEY,
    countryName STRING UNIQUE
);

CREATE TABLE dimension_date (
    dateID INT AUTOINCREMENT PRIMARY KEY,
    fullDate DATE UNIQUE,
    year INT,
    month INT,
    day INT
);

CREATE TABLE dimension_director (
    directorID INT AUTOINCREMENT PRIMARY KEY,
    directorName STRING UNIQUE
);

CREATE TABLE dimension_cast (
    castID INT AUTOINCREMENT PRIMARY KEY,
    castNames STRING
);

CREATE TABLE dimension_rating (
    ratingID INT AUTOINCREMENT PRIMARY KEY,
    ratingCode STRING UNIQUE
);

CREATE TABLE dimension_genre (
    genreID INT AUTOINCREMENT PRIMARY KEY,
    genreList STRING
);

CREATE TABLE dimension_duration (
    durationID INT AUTOINCREMENT PRIMARY KEY,
    durationType STRING,
    time INT
);

CREATE TABLE dimension_title (
    titleID INT AUTOINCREMENT PRIMARY KEY,
    showID STRING UNIQUE,
    title STRING,
    titleType STRING,
    description STRING,
    releaseYear INT
);

-- Facts Table
CREATE TABLE fact_netflix_shows (
    show_factID INT AUTOINCREMENT PRIMARY KEY,
    titleID INT REFERENCES dimension_title(titleID),
    directorID INT REFERENCES dimension_director(directorID),
    castID INT REFERENCES dimension_cast(castID),
    countryID INT REFERENCES dimension_country(countryID),
    dateID INT REFERENCES dimension_date(dateID),
    ratingID INT REFERENCES dimension_rating(ratingID),
    genreID INT REFERENCES dimension_genre(genreID),
    durationID INT REFERENCES dimension_duration(durationID)
)
CLUSTER BY (dateID, ratingID, countryID);
