import mysql.connector
from mysql.connector import Error
import random
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("recipe_db.log"),
        logging.StreamHandler()
    ]
)

try:
    userName = "root"
    pswd = "2255"

    conn = mysql.connector.connect(
        host="localhost",
        port=3306,
        user=userName,
        password=pswd,
        database="recipeDB"
    )

    if conn.is_connected():
        logging.info("Successfully connected to the database with mysql.connector")

        cursor = conn.cursor()

        # SQL queries
        get_all_cuisines_query = "SELECT national_cuisine_ID FROM national_cuisine"
        get_all_cooks_query = "SELECT cook_ID FROM cook"
        get_expertise_query = "SELECT cook_ID, national_cuisine_ID FROM expertise"

        # Execute SQL queries and fetch results
        cursor.execute(get_all_cuisines_query)
        all_cuisines = [row[0] for row in cursor.fetchall()]

        cursor.execute(get_all_cooks_query)
        all_cooks = [row[0] for row in cursor.fetchall()]

        cursor.execute(get_expertise_query)
        expertise = [(row[0], row[1]) for row in cursor.fetchall()]

        def is_valid_selection(selected_id, history, ep_num):
            count = 0
            for i in range(len(history)):
                if selected_id in history[0]:
                    count +=1
            return count < 3

        def update_history(history, selection):
            history.append(selection)
            if len(history) > 3:
                history.pop(0)

        def create_new_season(year, num_episodes=10):
            try:
                cursor.execute("SELECT IFNULL(MAX(season), 0) + 1 FROM episode")
                new_season_number = cursor.fetchone()[0]
            except Error as e:
                logging.error(f"Error retrieving new season number: {e}")
                return

            cuisine_history, recipe_history, cook_judge_history = [], [], []

            for episode_num in range(1, num_episodes + 1):
                cuisines = []
                for cuis in all_cuisines:
                    cuisines.append(cuis)
                try:
                    selected_cuisines = []
                    selected_recipes = []
                    selected_cooks = []
                    selected_judges = []
                    # Select 10 unique random cuisines
                    if len(all_cuisines) < 10:
                        logging.error("Not enough cuisines available to select 10 unique cuisines.")
                        continue  # Skip to the next episode
                    for i in range(10):
                        while(True):
                            cuisine_ID = random.choice(cuisines)
                            #print('1: ', is_valid_selection(cuisine_ID, cuisine_history, episode_num))
                            #print('2: ',(cuisine_ID not in selected_cuisines))
                            #print(f'Episode {episode_num}: ', is_valid_selection(cuisine_ID, cuisine_history, episode_num) and (cuisine_ID not in selected_cuisines) and cuisine_ID != 20)
                            if(is_valid_selection(cuisine_ID, cuisine_history, episode_num) and (cuisine_ID not in selected_cuisines)):
                                selected_cuisines.append(cuisine_ID)
                                cuisines.remove(cuisine_ID)
                                #print(selected_cuisines)
                                break
                    update_history(cuisine_history, selected_cuisines)

                    logging.debug(f"Episode {episode_num}: Selected cuisines: {selected_cuisines}")

                    # Select 1 recipe from each selected cuisine using SQL JOIN
                    for cuisine in selected_cuisines:
                        try:
                            while(True):
                                query = """
                                SELECT r.recipe_ID 
                                FROM recipe AS r
                                JOIN national_cuisine AS nc ON r.national_cuisine_ID = nc.national_cuisine_ID
                                WHERE r.national_cuisine_ID = %s
                                ORDER BY RAND()
                                LIMIT 1
                                """
                                cursor.execute(query, (cuisine,))
                                recipe_ID = [row[0] for row in cursor.fetchall()][0]
                                if is_valid_selection(recipe_ID, recipe_history, episode_num) and recipe_ID not in selected_recipes:
                                    selected_recipes.append(recipe_ID)
                                    break
                                else:
                                    #logging.warning(f"No recipes found for cuisine ID: {cuisine}")
                                    continue  # Skip to the next cuisine
                        except Error as e:
                            logging.error(f"Error retrieving recipes for cuisine {cuisine}: {e}")
                            continue  # Skip to the next cuisine

                    update_history(recipe_history, selected_recipes)
                    logging.debug(f"Episode {episode_num}: Selected recipes: {selected_recipes}")

                    # Select 10 cooks based on their expertise
                    for cuisine in selected_cuisines:
                        while(True):
                            query = """
                                SELECT c.cook_ID
                                FROM cook AS c
                                JOIN (national_cuisine AS nc JOIN expertise as e ON e.national_cuisine_ID = nc.national_cuisine_ID) ON c.cook_ID = e.cook_ID
                                WHERE nc.national_cuisine_ID = %s
                                ORDER BY RAND()
                                LIMIT 1;
                                """
                            cursor.execute(query, (cuisine,))
                            cook_ID = [row[0] for row in cursor.fetchall()][0]
                            if is_valid_selection(cook_ID, cook_judge_history, episode_num) and cook_ID not in selected_cooks:
                                selected_cooks.append(cook_ID)
                                break
                            else:
                                logging.warning(f"Duplicate cook found with expertise in cuisine ID: {cuisine}. Searching again...")
                                continue  # Skip to the next cuisine
                    logging.debug(f"Episode {episode_num}: Selected cooks: {selected_cooks}")
                    
                    selected_cooks_judges = selected_cooks

                    # Select Judges
                    for i in range(3):
                        while(True):
                            get_judges_query = """
                                SELECT cook_ID
                                FROM cook
                                WHERE cook_ID NOT IN (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                                ORDER BY RAND()
                                LIMIT 1;
                                """
                            cursor.execute(get_judges_query, (selected_cooks[0], selected_cooks[1], selected_cooks[2], selected_cooks[3], selected_cooks[4], selected_cooks[5], selected_cooks[6], selected_cooks[7], selected_cooks[8], selected_cooks[9]))
                            valid_judge = [row[0] for row in cursor.fetchall()][0]
                            if is_valid_selection(valid_judge, cook_judge_history, episode_num) and valid_judge not in selected_cooks_judges:
                                selected_judges.append(valid_judge)
                                selected_cooks_judges.append(valid_judge)
                                break
                            else:
                                continue

                    update_history(cook_judge_history, selected_cooks_judges)
                    logging.debug(f"Episode {episode_num}: Selected judges: {selected_judges}")

                    insert_episode_query = """
                    INSERT INTO episode (image_ID, judge_1, judge_2, judge_3, season, episode)
                    VALUES (1, %s, %s, %s, %s, %s)
                    """
                    cursor.execute(insert_episode_query, (
                        selected_judges[0], selected_judges[1], selected_judges[2], new_season_number, episode_num
                    ))
                    conn.commit()
                    new_episode_id = cursor.lastrowid

                    # Assign recipes to cooks and insert ep_info
                    for cook, recipe in zip(selected_cooks, selected_recipes):
                        insert_ep_info_query = """
                        INSERT INTO ep_info (ep_ID, cook_ID, recipe_ID, rating_1, rating_2, rating_3, avg_rating)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                        """
                        ratings = [random.randint(1, 5) for _ in range(3)]
                        avg_rating = sum(ratings) / 3
                        cursor.execute(insert_ep_info_query, (
                            new_episode_id, cook, recipe, ratings[0], ratings[1], ratings[2], avg_rating
                        ))
                    conn.commit()
                    logging.info(f"Episode {episode_num} for season {new_season_number} created successfully.")
                except Exception as e:
                    logging.error(f"Error while creating episode {episode_num} for season {new_season_number}: {e}")
                    conn.rollback()
                    continue  # Skip to the next episode

        if __name__ == "__main__":
            create_new_season(2025)

except Error as e:
    logging.error(f"Error while connecting to MariaDB with mysql.connector: {e}")
finally:
    try:
        if conn.is_connected():
            cursor.close()
            conn.close()
            logging.info("Database connection closed.")
    except NameError:
        logging.error("Connection or cursor not properly initialized.")
