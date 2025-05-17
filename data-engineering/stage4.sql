USE DATABASE netflix_demo_db;
USE SCHEMA netflix_demo_analytics;

-- Show count of titles aggregate used in decription of the latest staged table created in Stage 3
select description, count(*) AS count, array_agg(title) AS titles
from netflix_shows_stage_table
GROUP BY description
HAVING count(*) > 1;

-- Validate show titles of the latest staged table created in Stage 3 for titles without seasons, i.e. movie.
select show_id, title, duration
from netflix_shows_stage_table
where type = 'TV Show' and lower(duration) NOT LIKE '%season%';

-- Check for missing cast references where castID is used as a foreign key in facts table
select * from fact_netflix_shows f
left join dimension_cast dc on f.castID = dc.castID where dc.castID is null;

-- Check for duplicate records in facts table post recent append as part of stage 3
select titleID, dateID, castID, count(*) as duplicate_count
from fact_netflix_shows group by titleID, dateID, castID having count(*) > 1;

-- Check for titles older than 1950
select distinct t.title, t.releaseYear as release_year
from fact_netflix_shows f
join dimension_title t on f.titleID = t.titleID
where t.releaseYear < 1950 OR t.releaseYear > year(current_date) order by t.releaseYear asc;

-- Validate newly appened inserts to facts and dimension tables via Stage 3 for director name Souvik Das
select
    dt.showID,
    dt.title,
    dt.titleType,
    dt.description,
    dt.releaseYear,
    dd.directorName,
    dc.countryName,
    ddate.fullDate AS date_added,
    dr.ratingCode,
    dg.genreList,
    du.durationType,
    du.durationTime
from 
    fact_netflix_shows f
join 
    dimension_title dt on f.titleID = dt.titleID
join 
    dimension_director dd on f.directorID = dd.directorID
join 
    dimension_country dc on f.countryID = dc.countryID
join 
    dimension_date ddate on f.dateID = ddate.dateID
join 
    dimension_rating dr on f.ratingID = dr.ratingID
join 
    dimension_genre dg on f.genreID = dg.genreID
join 
    dimension_duration du on f.durationID = du.durationID
where 
    dd.directorName = 'Souvik Das';

-- Check for validity of title "Dil Se: Echoes in Manhattan" in the dimension title table by referencing facts table
select dt.title
from fact_netflix_shows f
join dimension_title dt on f.titleID = dt.titleID
where lower(dt.title) = lower('Dil Se: Echoes in Manhattan');
