-- Drop tables if they exist to avoid errors
-- SET FOREIGN_KEY_CHECKS = 0;

-- -- Drop tables in § order of dependency (least dependent first)
-- DROP TABLE IF EXISTS recipe_img, label_recipe, meal_recipe, steps, episode, ep_info;
-- DROP TABLE IF EXISTS recipe, user, label, meal_type;
-- DROP TABLE IF EXISTS ingredient, equipment;
-- DROP TABLE IF EXISTS images, food_group, user_group, cook, national_cuisine, thematic_section, expertise;

-- -- Re-enable foreign key checks after operations
-- SET FOREIGN_KEY_CHECKS = 1;


DROP DATABASE IF EXISTS RecipeDB;

-- Create database
CREATE DATABASE IF NOT EXISTS RecipeDB;

-- Use the created database
USE RecipeDB;

-- Drop tables if they exist to avoid errors
SET FOREIGN_KEY_CHECKS = 0;

-- Drop tables in order of dependency (least dependent first)
DROP TABLE IF EXISTS recipe_img, label_recipe, meal_recipe, steps, episode, ep_info;
DROP TABLE IF EXISTS recipe, user_table, label, meal_type;
DROP TABLE IF EXISTS ingredient, equipment;
DROP TABLE IF EXISTS images, food_group, user_group, cook, national_cuisine, theme, theme_recipe, recipe_ingr, recipe_eq, expertise;

-- Re-enable foreign key checks after operations
SET FOREIGN_KEY_CHECKS = 1;

-- Images table
CREATE  TABLE images (
    image_ID INT AUTO_INCREMENT PRIMARY KEY,
    image_desc TEXT,
    image_url TEXT UNIQUE NOT NULL
) ENGINE=InnoDB;

-- Food Group table
CREATE  TABLE food_group (
    food_group_ID INT AUTO_INCREMENT PRIMARY KEY,
    image_ID INT NOT NULL ,
    food_group_name VARCHAR(255) NOT NULL UNIQUE,
    food_group_desc TEXT ,
    category VARCHAR(255) NOT NULL, /*UNIQUE?*/
    INDEX fk_image_id_idx (image_ID ASC),
    FOREIGN KEY (image_ID) REFERENCES images(image_ID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Ingredients table 
CREATE  TABLE ingredient (
    ingredient_ID INT AUTO_INCREMENT PRIMARY KEY,
    food_group_ID INT NOT NULL,
    image_ID INT NOT NULL ,
    ingr_name VARCHAR(255) NOT NULL UNIQUE ,
    calories DECIMAL(10, 2) NOT NULL CHECK( calories >= 0 AND calories <= 1000),
    unit ENUM('mL', 'L', 'gr' ,'table spoon' , 'tea spoon' , 'N/A'),
    UNIQUE INDEX ingr_group_image_idx (ingredient_ID ASC, food_group_ID ASC),
    INDEX fk_image_ID_idx (image_ID ASC),
    INDEX fk_food_group_ID_idx (food_group_ID ASC),
    FOREIGN KEY (image_ID) REFERENCES images(image_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (food_group_ID) REFERENCES food_group(food_group_ID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Equipment table
CREATE  TABLE equipment (
    eq_ID INT AUTO_INCREMENT PRIMARY KEY,
    image_ID INT NOT NULL ,
    eq_name VARCHAR(255) NOT NULL UNIQUE,
    instructions TEXT NOT NULL,
    INDEX fk_image_id_idx (image_ID ASC),
    INDEX eq_name_idx (eq_name ASC),
    FOREIGN KEY (image_ID) REFERENCES images(image_ID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Meal Type table
CREATE  TABLE meal_type (
    meal_type_ID INT AUTO_INCREMENT PRIMARY KEY,
    meal_type_name ENUM('breakfast', 'lunch', 'dinner', 'snack', 'dessert') NOT NULL
) ENGINE=InnoDB;

-- Cook table
CREATE  TABLE cook (
    cook_ID INT AUTO_INCREMENT PRIMARY KEY,
    user_ID INT NOT NULL,
    image_ID INT ,
    firstname VARCHAR(255) NOT NULL,
    lastname VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    date_of_birth DATE NOT NULL, 
    experience INT NOT NULL CHECK(experience >= 0 AND experience <=100),  
    rank ENUM('cook C', 'cook B' , 'cook A' , 'assistant chef' , 'chef')  NOT NULL,
    UNIQUE INDEX cook_user_idx (cook_ID ASC, user_ID ASC),
    INDEX fk_image_id_idx (image_ID ASC),
    INDEX cook_name_idx (firstname ASC, lastname ASC),
    FOREIGN KEY (image_ID) REFERENCES images(image_ID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- National Cuisine table
CREATE  TABLE national_cuisine (
    national_cuisine_ID INT AUTO_INCREMENT PRIMARY KEY,
    cuisine_name VARCHAR(255)
) ENGINE=InnoDB;

-- Recipes table
CREATE  TABLE recipe (
    recipe_ID INT AUTO_INCREMENT PRIMARY KEY,
    national_cuisine_ID INT NOT NULL,
    main_ingredient_ID INT NOT NULL,
    recipe_name VARCHAR(255) NOT NULL ,
    difficulty_level INT NOT NULL CHECK(difficulty_level>=1 AND difficulty_level <= 5),
    recipe_description TEXT NOT NULL UNIQUE,
    prep_time INT NOT NULL CHECK(prep_time>=0),
    cook_time INT NOT NULL CHECK(cook_time>=0),
    portions INT NOT NULL CHECK(portions>=1),
    tip_1 TEXT , /* isos kai auto varchar*/
    tip_2 TEXT ,
    tip_3 TEXT ,
    fat DECIMAL(10, 1) NOT NULL,
    carbs DECIMAL(10, 1) NOT NULL,
    proteins DECIMAL(10, 1) NOT NULL,
    /*CONSTRAINT t1_not_t2 CHECK (tip_1 <> tip_2),
    CONSTRAINT t1_not_t3 CHECK (tip_1 <> tip_3),
    CONSTRAINT t3_not_t2 CHECK (tip_2 <> tip_3),*/
    UNIQUE INDEX recipe_cuisine_main_ingr (recipe_ID ASC, national_cuisine_ID ASC, main_ingredient_ID ASC),
    INDEX fk_main_ingredient_ID (main_ingredient_ID ASC),
    INDEX national_cuisine_ID (national_cuisine_ID ASC),
    INDEX recipe_name_idx (recipe_name ASC),
    FOREIGN KEY (national_cuisine_ID) REFERENCES national_cuisine(national_cuisine_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (main_ingredient_ID) REFERENCES ingredient(ingredient_ID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Meal Type Recipes table
CREATE  TABLE meal_recipe (
    meal_type_ID INT NOT NULL,
    recipe_ID INT NOT NULL,
    PRIMARY KEY (meal_type_ID, recipe_ID),
    -- UNIQUE INDEX 'meal_type_recipe_idx' ('meal_type_ID' ASC, 'recipe_ID' ASC),
    FOREIGN KEY (meal_type_ID) REFERENCES meal_type(meal_type_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (recipe_ID) REFERENCES recipe(recipe_ID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Labels table
CREATE  TABLE label (
    label_ID INT AUTO_INCREMENT PRIMARY KEY,
    label_description TEXT NOT NULL
) ENGINE=InnoDB;

-- Label Recipes table
CREATE  TABLE label_recipe (
    label_ID INT NOT NULL,
    recipe_ID INT NOT NULL,
    /*PRIMARY KEY (label_ID, recipe_ID),*/
    UNIQUE INDEX recipe_label_idx (label_ID ASC, recipe_ID ASC),
    FOREIGN KEY (label_ID) REFERENCES label(label_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (recipe_ID) REFERENCES recipe(recipe_ID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Steps table
CREATE  TABLE steps (
    step_ID INT AUTO_INCREMENT PRIMARY KEY,
    recipe_ID INT NOT NULL,
    sequence_number INT NOT NULL,
    step_description TEXT NOT NULL,
    UNIQUE INDEX steps_recipe (step_ID ASC, recipe_ID ASC, sequence_number ASC), /*Maybe Primary Key?*/
    FOREIGN KEY (recipe_ID) REFERENCES recipe(recipe_ID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- User table
CREATE  TABLE user_table (
    user_ID INT AUTO_INCREMENT PRIMARY KEY,    
    username VARCHAR(255) NOT NULL UNIQUE ,
    group_name ENUM( 'user' , 'admin') NOT NULL  DEFAULT 'user',
    user_password CHAR(64) NOT NULL
) ENGINE=InnoDB;

-- Episodes table
CREATE  TABLE episode (
    ep_ID INT AUTO_INCREMENT PRIMARY KEY,
    image_ID INT NOT NULL,
    judge_1 INT NOT NULL,
    judge_2 INT NOT NULL,
    judge_3 INT NOT NULL,
    season INT NOT NULL CHECK(season >=1),
    episode INT NOT NULL CHECK(episode >=1 AND episode<=10),
    -- maybe needs a unique index that combines all FKs
    INDEX fk_image_ID_idx (image_ID ASC),
    INDEX fk_judge_1_idx (judge_1 ASC),
    INDEX fk_judge_2_idx (judge_2 ASC),
    INDEX fk_judge_3_idx (judge_3 ASC),
    FOREIGN KEY (image_ID) REFERENCES images(image_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (judge_1) REFERENCES cook(cook_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (judge_2) REFERENCES cook(cook_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (judge_3) REFERENCES cook(cook_ID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Theme table
CREATE  TABLE theme (
    theme_ID INT AUTO_INCREMENT PRIMARY KEY,
    image_ID INT NOT NULL ,
    theme_name TEXT NOT NULL UNIQUE,
    theme_desc TEXT NOT NULL UNIQUE,
    INDEX fk_image_ID_idx (image_ID ASC),
    FOREIGN KEY (image_ID) REFERENCES images(image_ID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Theme Recipes table
CREATE  TABLE theme_recipe (
    theme_ID INT NOT NULL,
    recipe_ID INT NOT NULL,
    PRIMARY KEY (theme_ID, recipe_ID),
    /*UNIQUE INDEX 'theme_recipe_idx' ('theme_ID' ASC, 'recipe_ID' ASC),*/
    INDEX fk_theme_ID_idx (theme_ID ASC),
    INDEX fk_recipe_ID_idx (recipe_ID ASC),
    FOREIGN KEY (theme_ID) REFERENCES theme(theme_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (recipe_ID) REFERENCES recipe(recipe_ID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Recipe Ingredients table
CREATE  TABLE recipe_ingr (
    recipe_ID INT NOT NULL,
    ingredient_ID INT NOT NULL,
    quantity VARCHAR(255) NOT NULL,
    PRIMARY KEY (recipe_ID, ingredient_ID),
    INDEX fk_recipe_ID_idx (recipe_ID ASC),
    INDEX fk_ingr_ID_idx (ingredient_ID ASC),
    FOREIGN KEY (recipe_ID) REFERENCES recipe(recipe_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (ingredient_ID) REFERENCES ingredient(ingredient_ID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Recipe Equipment table
CREATE  TABLE recipe_eq (
    eq_ID INT NOT NULL ,
    recipe_ID INT NOT NULL,
    PRIMARY KEY (eq_ID, recipe_ID),
    INDEX fk_recipe_ID_idx (recipe_ID ASC),
    INDEX fk_eq_ID_idx (eq_ID ASC),
    FOREIGN KEY (eq_ID) REFERENCES equipment(eq_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (recipe_ID) REFERENCES recipe(recipe_ID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Expertise table
CREATE  TABLE expertise (
    cook_ID INT NOT NULL,
    national_cuisine_ID INT NOT NULL,
    PRIMARY KEY (cook_ID, national_cuisine_ID),
    INDEX fk_cook_ID_idx (cook_ID ASC),
    INDEX fk_cuisine_ID_idx (national_cuisine_ID ASC),
    FOREIGN KEY (cook_ID) REFERENCES cook(cook_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (national_cuisine_ID) REFERENCES national_cuisine(national_cuisine_ID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Episode Information table
CREATE  TABLE ep_info (
    ep_ID INT NOT NULL,
    cook_ID INT NOT NULL,
    recipe_ID INT NOT NULL,
    rating_1 TINYINT NOT NULL CHECK (rating_1 >=1 AND rating_1 <=5),
    rating_2 TINYINT NOT NULL CHECK (rating_2 >=1 AND rating_2 <=5),
    rating_3 TINYINT NOT NULL CHECK (rating_3 >=1 AND rating_3 <=5),
    avg_rating DECIMAL(10, 2) NOT NULL, /*ti tha kanoume ???*/
    PRIMARY KEY (ep_ID, cook_ID),
    UNIQUE INDEX ep_info_idx (ep_ID ASC, cook_ID ASC, recipe_ID ASC),
    INDEX ep_ID_idx (ep_ID ASC),
    INDEX fk_cook_ID_idx (cook_ID ASC),
    INDEX fk_recipe_ID_idx (recipe_ID ASC),
    FOREIGN KEY (ep_ID) REFERENCES episode(ep_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (cook_ID) REFERENCES cook(cook_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (recipe_ID) REFERENCES recipe(recipe_ID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;