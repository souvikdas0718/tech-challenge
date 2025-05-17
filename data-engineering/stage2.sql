-- Create a stage 
create or replace stage netflix_shows_stage
file_format = (type = 'CSV' FIELD_DELIMITER = ',' field_optionally_enclosed_by = '"' skip_header = 1 COMPRESSION = 'NONE');

-- Create the staging table
CREATE OR REPLACE TABLE netflix_shows_stage_table (
    show_id STRING,
    type STRING,
    title STRING,
    director STRING,
    cast STRING,
    country STRING,
    date_added STRING,
    release_year INT,
    rating STRING,
    duration STRING,
    listed_in STRING,
    description STRING
);

-- Load the raw data from netflix_titles.csv from the stage to the netflix_shows_stage_table
copy into netflix_shows_stage_table
from @netflix_shows_stage/netflix_titles.csv
file_format = (type = 'CSV' FIELD_DELIMITER = ',' field_optionally_enclosed_by = '"' skip_header = 1)
on_error = 'CONTINUE';

-- Verify the uploaded data
select * from netflix_shows_stage_table limit 10;

-- Create the ELT procedure
create or replace procedure netflix_shows_ETL()
returns STRING
language SQL
as
$$
BEGIN

-- Insert into dimension tables
-- Use DISTINCT to avoid duplicates
-- Use NOT EXISTS to check for duplicates before inserting
-- Use TRY_TO_NUMBER to handle any non-numeric values in the duration
-- Use CASE to determine the duration type (Season or Minute)

INSERT INTO dimension_director (directorName)
SELECT DISTINCT director
FROM netflix_shows_stage_table
WHERE director IS NOT NULL AND director NOT IN (
    SELECT directorName FROM dimension_director
);

INSERT INTO dimension_cast (castNames)
SELECT DISTINCT s.cast
FROM netflix_shows_stage_table s
WHERE s.cast IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 
    FROM dimension_cast d 
    WHERE d.castNames = s.cast
);


INSERT INTO dimension_country (countryName)
SELECT DISTINCT country
FROM netflix_shows_stage_table
WHERE country IS NOT NULL AND country NOT IN (
    SELECT countryName FROM dimension_country
);

INSERT INTO dimension_date (fullDate, year, month, day)
SELECT DISTINCT 
    TO_DATE(TRIM(date_added), 'MMMM DD, YYYY'),
    YEAR(TO_DATE(TRIM(date_added), 'MMMM DD, YYYY')),
    MONTH(TO_DATE(TRIM(date_added), 'MMMM DD, YYYY')),
    DAY(TO_DATE(TRIM(date_added), 'MMMM DD, YYYY'))
FROM netflix_shows_stage_table
WHERE date_added IS NOT NULL 
  AND TO_DATE(TRIM(date_added), 'MMMM DD, YYYY') NOT IN (
      SELECT fullDate FROM dimension_date
  );

INSERT INTO dimension_rating (ratingCode)
SELECT DISTINCT rating
FROM netflix_shows_stage_table
WHERE rating IS NOT NULL AND rating NOT IN (
    SELECT ratingCode FROM dimension_rating
);

INSERT INTO dimension_genre (genreList)
SELECT DISTINCT listed_in
FROM netflix_shows_stage_table
WHERE listed_in IS NOT NULL AND listed_in NOT IN (
    SELECT genreList FROM dimension_genre
);

INSERT INTO dimension_duration (durationType, durationTime)
WITH transformed_durations AS (
    SELECT DISTINCT 
        CASE 
            WHEN duration ILIKE '%Season%' THEN 'Season'
            ELSE 'Minute'
        END AS durationType,
        TRY_TO_NUMBER(REGEXP_SUBSTR(duration, '^[0-9]+')) AS durationTime
    FROM netflix_shows_stage_table
    WHERE duration IS NOT NULL
)
SELECT durationType, durationTime
FROM transformed_durations td
WHERE NOT EXISTS (
    SELECT 1
    FROM dimension_duration dd
    WHERE dd.durationType = td.durationType
      AND dd.durationTime = td.durationTime
);

INSERT INTO dimension_title (showID, title, titleType, description, releaseYear)
SELECT DISTINCT show_id, title, type, description, release_year
FROM netflix_shows_stage_table
WHERE show_id IS NOT NULL AND show_id NOT IN (
    SELECT showID FROM dimension_title
);

-- Insert into facts table and avoid duplicates
-- Use LEFT JOIN to ensure all records from the staging table are considered
-- and only insert those that do not already exist in the fact table
-- Use TRY_TO_NUMBER to handle any non-numeric values in the duration
-- Use CASE to determine the duration type (Season or Minute)

INSERT INTO fact_netflix_shows (
    titleID, directorID, castID, countryID, dateID,
    ratingID, genreID, durationID
)
SELECT
    t.titleID,
    d.directorID,
    c.castID,
    co.countryID,
    da.dateID,
    ra.ratingID,
    g.genreID,
    du.durationID
FROM netflix_shows_stage_table r
JOIN dimension_title t ON t.showID = r.show_id
LEFT JOIN dimension_director d ON d.directorName = r.director
LEFT JOIN dimension_cast c ON c.castNames = r.cast
LEFT JOIN dimension_country co ON co.countryName = r.country
LEFT JOIN dimension_date da 
    ON TO_DATE(TRIM(date_added), 'MMMM DD, YYYY') = da.fullDate
LEFT JOIN dimension_rating ra ON ra.ratingCode = r.rating
LEFT JOIN dimension_genre g ON g.genreList = r.listed_in
LEFT JOIN dimension_duration du 
    ON TRY_TO_NUMBER(REGEXP_SUBSTR(r.duration, '^[0-9]+')) = du.durationTime
   AND CASE 
         WHEN r.duration ILIKE '%Season%' THEN 'Season'
         ELSE 'Minute'
       END = du.durationType
WHERE NOT EXISTS (
    SELECT 1
    FROM fact_netflix_shows f
    WHERE f.titleID = t.titleID
      AND f.directorID = d.directorID
      AND f.castID = c.castID
      AND f.countryID = co.countryID
      AND f.dateID = da.dateID
      AND f.ratingID = ra.ratingID
      AND f.genreID = g.genreID
      AND f.durationID = du.durationID
);

RETURN 'SUCCESS';

END;
$$;

-- Call the procedure manually  
CALL netflix_shows_ETL();