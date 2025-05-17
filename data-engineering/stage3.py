import snowflake.snowpark as snowpark
from snowflake.snowpark.functions import col
import pandas as pd
import random
from datetime import datetime, timedelta
import io

# Generate a random past date in "Month DD, YYYY" format
def random_date():
    start = datetime(2020, 1, 1)
    end = datetime(2024, 12, 31)
    return (start + timedelta(days=random.randint(0, (end - start).days))).strftime("%B %d, %Y")

def main(session: snowpark.Session):
    # Sample data definitions
    types = ["Movie", "TV Show"]
    ratings = ["TV-MA", "PG-13", "R", "G", "TV-PG"]
    genres = [
        "Dramas, International Movies",
        "Comedies, Stand-Up",
        "Action & Adventure, Sci-Fi",
        "Documentaries, Sports",
        "Kids' TV, Animation"
    ]
    countries = ["India", "Canada", "United States", "Australia", "United Kingdom"]
    durations = ["120 min", "10 Seasons", "90 min", "3 Seasons", "1 Season"]
    cast_samples = [
        "Chester Benneton, Jesse James, Crispin Glover, ",
        "Ali Abbas, Sara Bhai, Martin Landau,  Alan Oppenheimer",
        "Roberto Carlos, Andy Lee, Fred Tatasciore",
        "Tsongpo Lee, Brad Khan, Tom Kane"
    ]
    directors = ["Souvik Das", "Baker Borris", "Aron Finch", "Aron Writer", "Mike Shinoda"]
    movie_titles = [
    "Dil Se: Echoes in Manhattan",
    "Mission: Masala Impossible",
    "Chalte Chalte: Midnight Run",
    "Sholay: The Last Outpost",
    "Andaz Apna Apna: Agents Assemble",
    "Queen of Wakanda Nagar",
    "Lagaan: Fury Road",
    "Kabhi Khushi Kabhi Gotham",
    "Zindagi Na Milegi Dobara: Infinity Drive",
    "Kaho Naa… Interstellar Hai"
    ]
    movie_descriptions = [
    "A passionate radio host in New York receives mysterious love messages from a woman in Delhi — bridging two worlds across time and space, with soulful songs and thrilling chases.",
    "An undercover MI6 agent turned street food vendor in Mumbai fights shadowy villains using spicy secrets and high-tech gadgets to save the city from destruction.",
    "A runaway bride fleeing an arranged marriage accidentally hijacks a CIA mission, sparking a cross-country chase filled with romance, humor, and breathtaking stunts.",
    "Two former outlaws are called upon to protect a small Texas town from a ruthless cyber gang — blending rustic courage with epic Bollywood dance battles.",
    "Two bumbling friends stumble into the Avengers’ headquarters, mixing Bollywood comedy and Hollywood heroism to save the world with heart and laughter.",
    "A spirited Punjabi girl escapes her traditional life only to discover a hidden portal to Wakanda, where she embraces her destiny as a queen of two vibrant cultures.",
    "In a drought-stricken village, a cricket match turns into a battle of honor and survival as villagers confront warlords — with emotional storytelling and explosive action sequences.",
    "Bruce Wayne is raised in a Bollywood family, learning the power of love, melodrama, and dance to fight crime in Gotham’s neon-lit streets.",
    "Three friends embark on a carefree road trip across Europe that turns into a cosmic adventure when they find a car with alien technology and a portal to alternate realities.",
    "A dreamy boy falls for a mysterious girl who exists only across black holes, as they sing heartfelt songs and race through galaxies to be together."
    ]

    # List to maintian new and updated records
    records = []

    # Generate 10 records which will be later used to update the dimensionally modelled tables
    for i in range(10):
        records.append({
            "show_id": f"s{101 + i}",
            "type": random.choice(types),
            "title": random.choice(movie_titles),
            "director": random.choice(directors),
            "cast": random.choice(cast_samples),
            "country": random.choice(countries),
            "date_added": random_date(),
            "release_year": random.randint(2015, 2023),
            "rating": random.choice(ratings),
            "duration": random.choice(durations),
            "listed_in": random.choice(genres),
            "description": random.choice(movie_descriptions)
        })

    # Generate 10 new records
    for i in range(10):
        records.append({
            "show_id": f"s{7791 + i}",
            "type": random.choice(types),
            "title": random.choice(movie_titles),
            "director": random.choice(directors),
            "cast": random.choice(cast_samples),
            "country": random.choice(countries),
            "date_added": random_date(),
            "release_year": random.randint(2015, 2024),
            "rating": random.choice(ratings),
            "duration": random.choice(durations),
            "listed_in": random.choice(genres),
            "description": random.choice(movie_descriptions)
        })

    # Converting the records to pandas DataFrame
    dataframe = pd.DataFrame(records)

    # Convert to CSV in memory
    string_buffer = io.StringIO()
    dataframe.to_csv(string_buffer, index=False)

    # Convert to BytesIO for Snowflake upload
    csv_buffer = io.BytesIO(string_buffer.getvalue().encode('utf-8'))
    csv_buffer.seek(0)

    # Upload the records to the Snowflake stage
    file_name = "netflix_updated_titles.csv"
    session.file.put_stream(csv_buffer, f"@netflix_shows_stage/{file_name}", overwrite=False, auto_compress=False)

    # Print the output message in python console
    print(f"The new file '{file_name}' has been successfully written to stage @netflix_shows_stage with {len(dataframe)} records.")

    return session.create_dataframe(dataframe)
