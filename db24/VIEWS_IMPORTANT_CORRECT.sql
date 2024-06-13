CREATE VIEW 3_1_1 AS
SELECT cook.cook_ID, (AVG(rating_1 + rating_2 + rating_3)) / 3 AS avgrating
FROM cook 
INNER JOIN ep_info ON ep_info.cook_id = cook.cook_id
GROUP BY cook.cook_ID;

CREATE VIEW 3_1_2 AS
SELECT national_cuisine.national_cuisine_ID, national_cuisine.cuisine_name, AVG(rating_1 + rating_2 + rating_3) /3 
FROM ep_info 
INNER JOIN recipe ON recipe.recipe_id = ep_info.recipe_id
INNER JOIN national_cuisine ON national_cuisine.national_cuisine_ID = recipe.national_cuisine_ID
GROUP BY national_cuisine.national_cuisine_ID, national_cuisine.cuisine_name;

CREATE VIEW 3_2 AS
WITH cooks_with_expertise AS (
    SELECT 
        c.cook_ID,
        CONCAT(c.firstname, ' ', c.lastname) AS name
    FROM 
        cook c
    JOIN 
        expertise cc ON c.cook_ID = cc.cook_ID
    WHERE 
        cc.national_cuisine_ID = 1
),
participation AS (
    SELECT 
        c.cook_ID,
        'yes' AS participated
    FROM 
        cooks_with_expertise c
    LEFT JOIN ep_info ei ON c.cook_ID = ei.cook_ID
    LEFT JOIN episode e1 ON ei.ep_ID = e1.ep_ID AND e1.season = 1
    LEFT JOIN episode e2 ON e2.season = 1
        AND (e2.judge_1 = c.cook_ID OR e2.judge_2 = c.cook_ID OR e2.judge_3 = c.cook_ID)
    WHERE 
        e1.ep_ID IS NOT NULL OR e2.ep_ID IS NOT NULL
)
SELECT DISTINCT
    c.name,
    COALESCE(p.participated, 'no') AS participated
FROM 
    cooks_with_expertise c
LEFT JOIN 
    participation p ON c.cook_ID = p.cook_ID;


CREATE VIEW 3_3 AS
SELECT cook.cook_id, CONCAT(cook.firstname, ' ', cook.lastname) AS full_name, COUNT(*)
FROM cook 
INNER JOIN ep_info ON ep_info.cook_id = cook.cook_id
WHERE (YEAR(NOW()) - YEAR(CAST(cook.date_of_birth AS DATETIME))) <= 30
GROUP BY cook.cook_id;

CREATE VIEW 3_4 AS
SELECT 
    cook.cook_ID,  
    CONCAT(cook.firstname, ' ', cook.lastname) AS full_name
FROM 
    cook
WHERE 
    NOT EXISTS (
        SELECT 1
        FROM episode e
        WHERE e.judge_1 = cook.cook_ID 
           OR e.judge_2 = cook.cook_ID 
           OR e.judge_3 = cook.cook_ID
    );
    
CREATE VIEW 3_5 AS
SELECT 
    e.season,
    CONCAT(c.firstname, ' ', c.lastname) AS judge_name,
    COUNT(*) AS appearances
FROM 
    episode e
JOIN 
    cook c ON e.judge_1 = c.cook_ID
        OR e.judge_2 = c.cook_ID
        OR e.judge_3 = c.cook_ID
GROUP BY 
    e.season, c.cook_ID
HAVING 
    appearances > 3
ORDER BY 
    e.season, appearances DESC;

CREATE VIEW 3_6_1 AS
SELECT l1.label_description AS label1, l2.label_description AS label2, COUNT(*) AS count
FROM label_recipe lr1
JOIN label_recipe lr2 ON lr1.recipe_ID = lr2.recipe_ID AND lr1.label_ID < lr2.label_ID
JOIN ep_info ei ON lr1.recipe_ID = ei.recipe_ID
JOIN label l1 ON lr1.label_ID = l1.label_ID
JOIN label l2 ON lr2.label_ID = l2.label_ID
GROUP BY l1.label_description, l2.label_description
ORDER BY count DESC
LIMIT 3;

CREATE VIEW 3_6_2 AS
SELECT STRAIGHT_JOIN l1.label_description AS label1, l2.label_description AS label2, COUNT(*) AS count
FROM label_recipe lr1
FORCE INDEX (recipe_label_idx)
JOIN label_recipe lr2 FORCE INDEX (recipe_label_idx)
ON lr1.recipe_ID = lr2.recipe_ID AND lr1.label_ID < lr2.label_ID
JOIN ep_info ei FORCE INDEX (fk_recipe_ID_idx)
ON lr1.recipe_ID = ei.recipe_ID
JOIN label l1 ON lr1.label_ID = l1.label_ID
JOIN label l2 ON lr2.label_ID = l2.label_ID
GROUP BY l1.label_description, l2.label_description
ORDER BY count DESC
LIMIT 3;

CREATE VIEW 3_6_3 AS
SELECT l1.label_description AS label1, l2.label_description AS label2, COUNT(*) AS count
FROM label_recipe lr1
JOIN label_recipe lr2 ON lr1.recipe_ID = lr2.recipe_ID AND lr1.label_ID < lr2.label_ID
JOIN ep_info ei ON lr1.recipe_ID = ei.recipe_ID
JOIN label l1 ON lr1.label_ID = l1.label_ID
JOIN label l2 ON lr2.label_ID = l2.label_ID
GROUP BY l1.label_description, l2.label_description
ORDER BY count DESC
LIMIT 3;

CREATE VIEW 3_6_4 AS
SELECT STRAIGHT_JOIN l1.label_description AS label1, l2.label_description AS label2, COUNT(*) AS count
FROM label_recipe lr1
FORCE INDEX (recipe_label_idx)
JOIN label_recipe lr2 FORCE INDEX (recipe_label_idx)
ON lr1.recipe_ID = lr2.recipe_ID AND lr1.label_ID < lr2.label_ID
JOIN ep_info ei FORCE INDEX (fk_recipe_ID_idx)
ON lr1.recipe_ID = ei.recipe_ID
JOIN label l1 ON lr1.label_ID = l1.label_ID
JOIN label l2 ON lr2.label_ID = l2.label_ID
GROUP BY l1.label_description, l2.label_description
ORDER BY count DESC
LIMIT 3;


CREATE VIEW 3_7 AS
SELECT 
    c1.cook_ID AS cook_id,
    CONCAT(c1.firstname, ' ', c1.lastname) AS cook_name,
    COUNT(e.ep_ID) AS appearances
FROM 
    cook c1
JOIN 
    ep_info ei ON c1.cook_ID = ei.cook_ID
JOIN 
    episode e ON ei.ep_ID = e.ep_ID
GROUP BY 
    c1.cook_ID, c1.firstname, c1.lastname
HAVING 
    COUNT(e.ep_ID) < (SELECT COUNT(ei2.ep_ID)
                      FROM ep_info ei2
                      JOIN cook c2 ON ei2.cook_ID = c2.cook_ID
                      GROUP BY c2.cook_ID
                      ORDER BY COUNT(ei2.ep_ID) DESC
                      LIMIT 1) - 5
ORDER BY appearances DESC ;

CREATE VIEW 3_8_1 AS
SELECT e.ep_ID, e.season, e.episode, COUNT(re.eq_ID) AS equipment_count
FROM episode e
JOIN ep_info ei ON e.ep_ID = ei.ep_ID
JOIN recipe_eq re ON ei.recipe_ID = re.recipe_ID
GROUP BY e.ep_ID, e.season, e.episode
ORDER BY equipment_count DESC
LIMIT 1;

CREATE VIEW 3_8_2 AS
SELECT STRAIGHT_JOIN e.ep_ID, e.season, e.episode, COUNT(re.eq_ID) AS equipment_count
FROM episode e
JOIN ep_info ei FORCE INDEX (ep_ID_idx) ON e.ep_ID = ei.ep_ID
JOIN recipe_eq re FORCE INDEX (fk_recipe_ID_idx) ON ei.recipe_ID = re.recipe_ID
GROUP BY e.ep_ID, e.season, e.episode
ORDER BY equipment_count DESC;


CREATE VIEW 3_8_3 AS
SELECT e.ep_ID, e.season, e.episode, COUNT(re.eq_ID) AS equipment_count
FROM episode e
JOIN ep_info ei ON e.ep_ID = ei.ep_ID
JOIN recipe_eq re ON ei.recipe_ID = re.recipe_ID
GROUP BY e.ep_ID, e.season, e.episode
ORDER BY equipment_count DESC
LIMIT 1;


CREATE VIEW 3_8_4 AS
SELECT STRAIGHT_JOIN e.ep_ID, e.season, e.episode, COUNT(re.eq_ID) AS equipment_count
FROM episode e
JOIN ep_info ei FORCE INDEX (ep_ID_idx)
ON e.ep_ID = ei.ep_ID
JOIN recipe_eq re FORCE INDEX (fk_recipe_ID_idx)
ON ei.recipe_ID = re.recipe_ID
GROUP BY e.ep_ID, e.season, e.episode
ORDER BY equipment_count DESC
LIMIT 1;



CREATE VIEW 3_9 AS
SELECT 
    e.season,
    AVG(r.carbs) AS average_carbs
FROM 
    episode e
JOIN 
    ep_info ei ON e.ep_ID = ei.ep_ID
JOIN 
    recipe r ON ei.recipe_ID = r.recipe_ID
GROUP BY 
    e.season;

CREATE VIEW 3_10 AS 
SELECT 
    CONCAT(e1.season, '-', e2.season) AS consecutive_seasons,
    nc.cuisine_name AS national_cuisine,
    COUNT(*) AS appearances
FROM 
    episode e1
JOIN 
    episode e2 ON e1.season + 1 = e2.season AND e1.episode = e2.episode
JOIN 
    ep_info ei1 ON e1.ep_ID = ei1.ep_ID
JOIN 
    ep_info ei2 ON e2.ep_ID = ei2.ep_ID
JOIN 
    national_cuisine nc ON ei1.recipe_ID = ei2.recipe_ID
WHERE 
    ei1.rating_1 + ei1.rating_2 + ei1.rating_3 > 3
    AND ei2.rating_1 + ei2.rating_2 + ei2.rating_3 > 3
GROUP BY 
    consecutive_seasons, nc.national_cuisine_ID
ORDER BY 
    consecutive_seasons, appearances DESC;


CREATE VIEW 3_11 AS
SELECT 
    CONCAT(j.firstname, ' ', j.lastname) AS judge_name,
    CONCAT(c.firstname, ' ', c.lastname) AS cook_name,
    SUM(
        CASE
            WHEN e.judge_1 = j.cook_ID THEN ei.rating_1
            WHEN e.judge_2 = j.cook_ID THEN ei.rating_2
            WHEN e.judge_3 = j.cook_ID THEN ei.rating_3
            ELSE 0
        END
    ) AS total_rating
FROM 
    ep_info ei
JOIN 
    cook c ON ei.cook_ID = c.cook_ID
JOIN 
    episode e ON ei.ep_ID = e.ep_ID
JOIN 
    cook j ON e.judge_1 = j.cook_ID OR e.judge_2 = j.cook_ID OR e.judge_3 = j.cook_ID
GROUP BY 
    j.cook_ID, j.firstname, j.lastname, c.cook_ID, c.firstname, c.lastname
ORDER BY 
    total_rating DESC
LIMIT 5;

CREATE VIEW 3_12 AS
SELECT episode_difficulty.ep_ID
FROM (
    SELECT e.ep_ID, SUM(r.difficulty_level) AS total_difficulty
    FROM episode e
    INNER JOIN ep_info ei ON e.ep_ID = ei.ep_ID
    INNER JOIN recipe r ON ei.recipe_ID = r.recipe_ID
    GROUP BY e.ep_ID
) AS episode_difficulty
ORDER BY episode_difficulty.total_difficulty DESC
LIMIT 1;
---------------- 3.12 corrected 
WITH EpisodeDifficulty AS (
    SELECT 
        e.season,
        e.episode,
        SUM(r.difficulty_level) AS total_difficulty
    FROM 
        ep_info ei
    JOIN 
        episode e ON ei.ep_ID = e.ep_ID
    JOIN 
        recipe r ON ei.recipe_ID = r.recipe_ID
    GROUP BY 
        e.season, e.episode
),
MaxDifficultyPerSeason AS (
    SELECT 
        season,
        MAX(total_difficulty) AS max_difficulty
    FROM 
        EpisodeDifficulty
    GROUP BY 
        season
)
SELECT 
    ed.season,
    ed.episode,
    ed.total_difficulty
FROM 
    EpisodeDifficulty ed
JOIN 
    MaxDifficultyPerSeason mds ON ed.season = mds.season AND ed.total_difficulty = mds.max_difficulty
ORDER BY 
    ed.season, ed.episode;


CREATE VIEW 3_13 AS
SELECT episode,avg_rank_level
FROM (
    SELECT e.ep_ID AS episode,
           (SUM(CASE j.rank 
                    WHEN 'cook C' THEN 1 
                    WHEN 'cook B' THEN 2 
                    WHEN 'cook A' THEN 3 
                    WHEN 'assistant chef' THEN 4 
                    WHEN 'chef' THEN 5 
                END) + 
                SUM(CASE c.rank 
                    WHEN 'cook C' THEN 1 
                    WHEN 'cook B' THEN 2 
                    WHEN 'cook A' THEN 3 
                    WHEN 'assistant chef' THEN 4 
                    WHEN 'chef' THEN 5 
                END)) / 13 AS avg_rank_level
    FROM episode e
    INNER JOIN cook j ON e.judge_1 = j.cook_ID OR e.judge_2 = j.cook_ID OR e.judge_3 = j.cook_ID
    INNER JOIN ep_info ei ON e.ep_ID = ei.ep_ID
    INNER JOIN cook c ON ei.cook_ID = c.cook_ID
    GROUP BY e.ep_ID
) AS avg_ranks_per_episode
ORDER BY avg_rank_level ASC
LIMIT 1;


---- corrected 
WITH ranked_cooks_and_judges AS (
    SELECT 
        e.ep_ID,
        e.season,
        CASE 
            WHEN c.rank = 'cook C' THEN 1 
            WHEN c.rank = 'cook B' THEN 2 
            WHEN c.rank = 'cook A' THEN 3 
            WHEN c.rank = 'assistant chef' THEN 4 
            WHEN c.rank = 'chef' THEN 5 
            ELSE 0 
        END AS rank
    FROM 
        ep_info ei
    JOIN 
        cook c ON ei.cook_ID = c.cook_ID
    JOIN 
        episode e ON ei.ep_ID = e.ep_ID

    UNION ALL

    SELECT 
        e.ep_ID,
        e.season,
        CASE 
            WHEN j.rank = 'cook C' THEN 1 
            WHEN j.rank = 'cook B' THEN 2 
            WHEN j.rank = 'cook A' THEN 3 
            WHEN j.rank = 'assistant chef' THEN 4 
            WHEN j.rank = 'chef' THEN 5 
            ELSE 0 
        END AS rank
    FROM 
        episode e
    JOIN 
        cook j ON j.cook_ID IN (e.judge_1, e.judge_2, e.judge_3)
),
episode_avg_ranks AS (
    SELECT 
        ep_ID,
        season,
        AVG(rank) AS average_rank
    FROM 
        ranked_cooks_and_judges
    GROUP BY 
        ep_ID, season
),
ranked_episodes AS (
    SELECT 
        ep_ID,
        season,
        average_rank,
        RANK() OVER (PARTITION BY season ORDER BY average_rank DESC) AS rank_within_season
    FROM 
        episode_avg_ranks
)
SELECT 
    ep_ID,
    season,
    average_rank
FROM 
    ranked_episodes
WHERE 
    rank_within_season = 1
ORDER BY 
    season;




CREATE VIEW 3_14 AS
SELECT theme_name, c as appearances
FROM (
    SELECT theme.theme_ID, theme_name, COUNT(DISTINCT ep_id) AS c
    FROM theme
    INNER JOIN theme_recipe ON theme_recipe.theme_ID = theme.theme_ID
    INNER JOIN recipe ON theme_recipe.recipe_id = recipe.recipe_id
    INNER JOIN ep_info ON ep_info.recipe_id = recipe.recipe_id
    GROUP BY theme_ID, theme_name
    ORDER BY c DESC
    LIMIT 1
) AS xx;

CREATE VIEW 3_15 AS
SELECT fg.food_group_name
FROM food_group fg
WHERE fg.food_group_ID NOT IN (
    SELECT DISTINCT i.food_group_ID
    FROM ingredient i
    JOIN recipe_ingr ri ON i.ingredient_ID = ri.ingredient_ID
    JOIN recipe r ON ri.recipe_ID = r.recipe_ID
    JOIN ep_info ei ON r.recipe_ID = ei.recipe_ID
);



------- PROCEDURES FOR 3.2 AND 3.10
DELIMITER //

CREATE PROCEDURE GetCuisineAppearances(IN max_season INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE j INT DEFAULT 2;
    DECLARE done INT DEFAULT 0;

    DROP TEMPORARY TABLE IF EXISTS cuisine_appearances;
    CREATE TEMPORARY TABLE cuisine_appearances (
        national_cuisine_ID INT,
        cuisine_name VARCHAR(255),
        appearances INT,
        seasons VARCHAR(10)
    );

    DECLARE cur CURSOR FOR
        SELECT nc.national_cuisine_ID, nc.cuisine_name,
               COUNT(DISTINCT e.ep_ID) AS appearances,
               CONCAT('season', i, '-', j) AS seasons
        FROM episode e
        JOIN ep_info ei ON e.ep_ID = ei.ep_ID
        JOIN expertise ex ON ei.cook_ID = ex.cook_ID
        JOIN national_cuisine nc ON ex.national_cuisine_ID = nc.national_cuisine_ID
        WHERE e.season IN (i, j)
        GROUP BY nc.national_cuisine_ID, nc.cuisine_name
        HAVING COUNT(DISTINCT e.ep_ID) > 3;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    WHILE j <= max_season DO
        OPEN cur;

        fetch_loop: LOOP
            FETCH cur INTO national_cuisine_ID, cuisine_name, appearances, seasons;
            IF done THEN
                LEAVE fetch_loop;
            END IF;

            INSERT INTO cuisine_appearances (national_cuisine_ID, cuisine_name, appearances, seasons)
            VALUES (national_cuisine_ID, cuisine_name, appearances, seasons);
        END LOOP;

        CLOSE cur;

        SET i = i + 1;
        SET j = j + 1;
        SET done = 0;
    END WHILE;

    SELECT appearances, cuisine_name, seasons
    FROM cuisine_appearances
    WHERE appearances IN (
        SELECT appearances
        FROM cuisine_appearances
        GROUP BY appearances, seasons
        HAVING COUNT(*) > 1
    )
    ORDER BY seasons, appearances DESC, cuisine_name;

    DROP TEMPORARY TABLE cuisine_appearances;
END //

DELIMITER ;

--3.2

DELIMITER //

CREATE PROCEDURE GetCooksWithParticipation(
    IN p_national_cuisine_name VARCHAR(255),
    IN p_season INT
)
BEGIN
    DECLARE v_cuisine_id INT;

    -- Find the ID of the given national cuisine name
    SELECT national_cuisine_ID
    INTO v_cuisine_id
    FROM national_cuisine
    WHERE cuisine_name = p_national_cuisine_name;

    -- Main query to find cooks with participation status
    WITH cooks_with_expertise AS (
        SELECT 
            c.cook_ID,
            CONCAT(c.firstname, ' ', c.lastname) AS name
        FROM 
            cook c
        JOIN 
            expertise cc ON c.cook_ID = cc.cook_ID
        WHERE 
            cc.national_cuisine_ID = v_cuisine_id
    ),
    participation AS (
        SELECT 
            c.cook_ID,
            'yes' AS participated
        FROM 
            cooks_with_expertise c
        LEFT JOIN ep_info ei ON c.cook_ID = ei.cook_ID
        LEFT JOIN episode e1 ON ei.ep_ID = e1.ep_ID AND e1.season = p_season
        LEFT JOIN episode e2 ON e2.season = p_season
            AND (e2.judge_1 = c.cook_ID OR e2.judge_2 = c.cook_ID OR e2.judge_3 = c.cook_ID)
        WHERE 
            e1.ep_ID IS NOT NULL OR e2.ep_ID IS NOT NULL
    )
    SELECT DISTINCT
        c.name,
        COALESCE(p.participated, 'no') AS participated
    FROM 
        cooks_with_expertise c
    LEFT JOIN 
        participation p ON c.cook_ID = p.cook_ID;
END //

DELIMITE


CALL GetCooksWithParticipation('Italian', 1);
