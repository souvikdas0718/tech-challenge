-- Create a stage
create stage if not exists netflix_shows_stage
file_format = (type = 'CSV' FIELD_DELIMITER = ',' field_optionally_enclosed_by = '"' skip_header = 1);

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
