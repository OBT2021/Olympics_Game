CREATE TABLE olympics_history (
  id INT
 ,name VARCHAR
 ,sex VARCHAR
 ,age VARCHAR
 ,height VARCHAR
 ,weight VARCHAR
 ,team VARCHAR
 ,noc VARCHAR
 ,ganes VARCHAR
 ,year INT
 ,season VARCHAR
 ,city VARCHAR
 ,sport VARCHAR
 ,event VARCHAR
 ,medal VARCHAR
);



CREATE TABLE olympics_history_noc_regions (
  noc VARCHAR
 ,region VARCHAR
 ,notes VARCHAR
);

ALTER TABLE olympics_history RENAME COLUMN ganes TO games;

SELECT *
FROM olympics_history;

SELECT *
FROM olympics_history_noc_regions;

-- 1. How many olympics games have been held?
SELECT
  COUNT(*) AS total_olympic_games
FROM olympics_history;

-- 2. List down all Olympics games held so far.
SELECT
  year
 ,season
 ,city
FROM olympics_history
ORDER BY year DESC;

-- 3. Mention the total no of nations who participated in each olympics game?

SELECT
  games
 ,COUNT(DISTINCT noc) AS total_no_of_countries
FROM olympics_history
GROUP BY games;


-- 4. Which year saw the highest and lowest no of countries participating in olympics

-- CTE to calculate the total number of unique participating countries (NOCs) per Olympic Games
WITH participating_countries AS (
    SELECT 
        COUNT(DISTINCT noc) AS total_participating,  -- Count of distinct participating countries
        games  -- Olympic Games edition
    FROM olympics_history
    GROUP BY games
),
-- CTE to determine the games with the lowest and highest participating countries
low_high_participating_countries AS (
    SELECT 
        -- Find the Olympic Games edition with the **lowest** participation
        MIN(games) FILTER (WHERE total_participating = (SELECT MIN(total_participating) FROM participating_countries)) AS lowest_games,

        -- Get the minimum number of participating countries across all games
        MIN(total_participating) AS low_participating,

        -- Find the Olympic Games edition with the **highest** participation
        MIN(games) FILTER (WHERE total_participating = (SELECT MAX(total_participating) FROM participating_countries)) AS highest_games,

        -- Get the maximum number of participating countries across all games
        MAX(total_participating) AS high_participating
    FROM participating_countries
)

-- Final selection to format the result
SELECT 
    -- Format the lowest participating Olympics as "Olympic Edition - Participation Count"
    CONCAT(lowest_games, ' - ', low_participating) AS lowest_participating,

    -- Format the highest participating Olympics as "Olympic Edition - Participation Count"
    CONCAT(highest_games, ' - ', high_participating) AS highest_participating
FROM low_high_participating_countries;


-- 5. Which region(s) has participated in all of the olympic games

-- CTE to calculate the total number of unique Olympic Games each region has participated in
WITH country_participation AS (
    SELECT 
        COUNT(DISTINCT games) AS total_participated_games,  -- Count of distinct Olympic Games editions
        region  -- Country or region name
    FROM olympics_history oh
    JOIN olympics_history_noc_regions ohnc
    ON oh.noc = ohnc.noc
    GROUP BY region  -- Grouping by region to count participation per country
),

-- CTE to determine the maximum number of Olympic Games participated in by any region
max_participation AS (
    SELECT MAX(total_participated_games) AS max_games FROM country_participation
)

-- Selecting only the regions that have participated in the maximum number of Olympic Games
SELECT 
    region, 
    total_participated_games
FROM country_participation
WHERE total_participated_games = (SELECT max_games FROM max_participation);

-- 6. Identify the sport which was played in all summer olympics.
WITH olympics_sport AS (
    -- This CTE calculates the total number of distinct sports and their participation across different Olympic Games
    SELECT
        COUNT(DISTINCT sport) AS total_sports, -- Count the distinct sports in each Olympic Games
        sport, -- The sport being played
        games -- The Olympic Games (Edition)
    FROM olympics_history
    GROUP BY sport, games -- Grouping by sport and Olympic Games
),

summer_games AS (
    -- This CTE filters the sports that were played only in the Summer Olympics
    SELECT
        COUNT(DISTINCT games) AS no_of_summer_games, -- Count the number of distinct Summer Olympic Games a sport was played in
        sport, -- The sport being played
        total_sports -- The total number of sports (for reference)
    FROM olympics_sport
    WHERE games LIKE '%Summer' -- Filter only Summer Olympics (games names with 'Summer')
    GROUP BY sport, total_sports -- Group by sport and total number of sports
)

-- Final selection to identify sports played in all Summer Olympics
SELECT
    no_of_summer_games, -- The count of distinct Summer Games the sport participated in
    sport -- The sport name
FROM summer_games
-- Group by sport and the number of summer games
GROUP BY no_of_summer_games, sport
ORDER BY no_of_summer_games DESC; -- Order by the number of Summer Games in descending order to find the most common sports

-- 7. Which Sports were just played only once in the olympics.

WITH olympics_sport AS (
    -- This CTE calculates the number of distinct Olympic Games each sport was played in
    SELECT
        sport,  -- The sport being played
        games  -- The specific Olympic Games the sport was played in
    FROM olympics_history
    GROUP BY sport, games  -- Grouping by sport and games to get each sport per game
),

sports_played_once AS (
    -- This CTE identifies sports that were played only once in the Olympics
    SELECT 
        sport,  -- The sport
        COUNT(DISTINCT games) AS no_of_games  -- Count the number of distinct games for each sport
    FROM olympics_sport
    GROUP BY sport  -- Grouping by sport to count participation
    HAVING COUNT(DISTINCT games) = 1  -- Only keep sports that appeared once
)

-- Final query to get the specific Olympic Games where the sport was played only once
SELECT
    sp.sport,  -- The sport played
    os.games,  -- The specific Olympic Games the sport was played in
	no_of_games
FROM olympics_sport os
JOIN sports_played_once sp
    ON os.sport = sp.sport  -- Join to get only those sports that appeared once in the Olympics
ORDER BY os.sport;  -- Order the results by sport for better readability


-- 8. Fetch the total no of sports played in each olympic games.
SELECT
  games
 ,COUNT(DISTINCT sport) AS no_of_sports
FROM olympics_history
GROUP BY games
ORDER BY no_of_sports DESC;

-- 9. Fetch oldest athletes to win a gold medal
WITH athletes
AS
(SELECT
    name
   ,sex
   ,age
   ,team
   ,games
   ,city
   ,sport
   ,event
   ,medal
  FROM olympics_history
  WHERE medal = 'Gold'
  AND age IS NOT NULL
  AND age != 'NA'),

oldest_gold_medal_athletes
AS
(SELECT
    MAX(age) AS athlete_age
  FROM athletes)

SELECT
  name
 ,sex
 ,age
 ,team
 ,games
 ,city
 ,sport
 ,event
 ,medal
FROM athletes
WHERE age = (SELECT
    athlete_age
  FROM oldest_gold_medal_athletes)  

-- 10. Find the Ratio of male and female athletes participated in all olympic games.
SELECT
  COUNT(CASE
    WHEN sex = 'M' THEN 1
  END) AS total_males
 ,COUNT(CASE
    WHEN sex = 'F' THEN 1
  END) AS total_females
 ,CONCAT(ROUND(COUNT(CASE
    WHEN sex = 'M' THEN 1
  END) * 1.0 / COUNT(CASE
    WHEN sex = 'F' THEN 1
  END), 2), ':1') AS male_to_female_ratio
FROM olympics_history;


-- 11. Fetch the top 5 athletes who have won the most gold medals.
SELECT 
    name, 
    sex, 
    team, 
    COUNT(medal) AS total_gold_medals
FROM olympics_history
WHERE medal = 'Gold'
GROUP BY name, sex, team
ORDER BY total_gold_medals DESC
LIMIT 5;

-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
SELECT 
    name, 
    sex, 
    team, 
    COUNT(medal) AS total_medals
FROM olympics_history
WHERE medal IN ('Gold', 'Silver', 'Bronze')
GROUP BY name, sex, team
ORDER BY total_medals DESC
LIMIT 5;

-- 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

SELECT  
    team, 
	noc,
   	COUNT(medal) AS total_medals
FROM olympics_history
WHERE medal IS NOT NULL  -- Ensures only valid medals are counted
AND medal != 'NA'
GROUP BY noc, team
ORDER BY total_medals DESC;

-- 14. List down total gold, silver and bronze medals won by each country.

SELECT  
    team, 
	noc,
    COUNT(CASE WHEN medal = 'Gold' THEN 1 END) AS gold_medals,
	COUNT(CASE WHEN medal = 'Silver' THEN 1 END) AS silver_medals,
	COUNT(CASE WHEN medal = 'Bronze' THEN 1 END) AS bronze_medals,
	COUNT(medal) AS total_medals
FROM olympics_history
WHERE medal IS NOT NULL  -- Ensures only valid medals are counted
AND medal != 'NA'
GROUP BY noc, team
ORDER BY total_medals DESC;


-- 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.

SELECT  
    team, 
	noc,
	games,
    COUNT(CASE WHEN medal = 'Gold' THEN 1 END) AS gold_medals,
	COUNT(CASE WHEN medal = 'Silver' THEN 1 END) AS silver_medals,
	COUNT(CASE WHEN medal = 'Bronze' THEN 1 END) AS bronze_medals,
	COUNT(medal) AS total_medals
FROM olympics_history
WHERE medal IS NOT NULL  -- Ensures only valid medals are counted
AND medal != 'NA'
GROUP BY noc, team, games
ORDER BY games;


-- 16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.

WITH medal_tally AS (
    SELECT  
        games,
        team, 
        noc,
        COUNT(CASE WHEN medal = 'Gold' THEN 1 END) AS gold_medals,
        COUNT(CASE WHEN medal = 'Silver' THEN 1 END) AS silver_medals,
        COUNT(CASE WHEN medal = 'Bronze' THEN 1 END) AS bronze_medals
    FROM olympics_history
    WHERE medal IS NOT NULL AND medal != 'NA'
    GROUP BY games, team, noc
),
ranked_medals AS (
    SELECT 
        games, 
        team, 
        noc,
        gold_medals, 
        silver_medals, 
        bronze_medals,
        RANK() OVER (PARTITION BY games ORDER BY gold_medals DESC) AS gold_rank,
        RANK() OVER (PARTITION BY games ORDER BY silver_medals DESC) AS silver_rank,
        RANK() OVER (PARTITION BY games ORDER BY bronze_medals DESC) AS bronze_rank
    FROM medal_tally
)
SELECT 
    games,
    MAX(CASE WHEN gold_rank = 1 THEN CONCAT(team, ' - ', gold_medals) END) AS most_gold_medals,
    MAX(CASE WHEN silver_rank = 1 THEN CONCAT(team, ' - ', silver_medals) END) AS most_silver_medals,
    MAX(CASE WHEN bronze_rank = 1 THEN CONCAT(team, ' - ', bronze_medals) END) AS most_bronze_medals
FROM ranked_medals
GROUP BY games
ORDER BY games;

-- 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

WITH medal_tally AS (
    SELECT  
        games,
        team, 
        noc,
        COUNT(CASE WHEN medal = 'Gold' THEN 1 END) AS gold_medals,
        COUNT(CASE WHEN medal = 'Silver' THEN 1 END) AS silver_medals,
        COUNT(CASE WHEN medal = 'Bronze' THEN 1 END) AS bronze_medals,
		COUNT(medal) AS total_medals
    FROM olympics_history
    WHERE medal IS NOT NULL AND medal != 'NA'
    GROUP BY games, team, noc
),
ranked_medals AS (
    SELECT 
        games, 
        team, 
        noc,
        gold_medals, 
        silver_medals, 
        bronze_medals,
		total_medals,
        RANK() OVER (PARTITION BY games ORDER BY gold_medals DESC) AS gold_rank,
        RANK() OVER (PARTITION BY games ORDER BY silver_medals DESC) AS silver_rank,
        RANK() OVER (PARTITION BY games ORDER BY bronze_medals DESC) AS bronze_rank,
		RANK() OVER (PARTITION BY games ORDER BY total_medals DESC) AS noc_rank
    FROM medal_tally
)
SELECT 
    games,
    MAX(CASE WHEN gold_rank = 1 THEN CONCAT(team, ' - ', gold_medals) END) AS most_gold_medals,
    MAX(CASE WHEN silver_rank = 1 THEN CONCAT(team, ' - ', silver_medals) END) AS most_silver_medals,
    MAX(CASE WHEN bronze_rank = 1 THEN CONCAT(team, ' - ', bronze_medals) END) AS most_bronze_medals,
	MAX(CASE WHEN noc_rank = 1 THEN CONCAT(team, ' - ', total_medals) END) AS most_noc_medals
FROM ranked_medals
GROUP BY games
ORDER BY games;

-- 18. Which countries have never won gold medal but have won silver/bronze medals?

WITH medal_tally AS (
    SELECT  
        team, 
        noc,
        COUNT(CASE WHEN medal = 'Gold' THEN 1 END) AS gold_medals,
        COUNT(CASE WHEN medal = 'Silver' THEN 1 END) AS silver_medals,
        COUNT(CASE WHEN medal = 'Bronze' THEN 1 END) AS bronze_medals
    FROM olympics_history
    WHERE medal IS NOT NULL AND medal != 'NA'
    GROUP BY team, noc
)

SELECT team, noc, silver_medals, bronze_medals
FROM medal_tally
WHERE gold_medals = 0  -- Ensures the country has **never** won a gold medal
AND (silver_medals > 0 OR bronze_medals > 0)  -- Ensures the country has at least one silver or bronze
ORDER BY silver_medals DESC, bronze_medals DESC;


-- 19. In which Sport/event, India has won highest medals.
SELECT 
    sport, 
    event,  
    COUNT(medal) AS total_medals
FROM olympics_history
WHERE noc = 'IND'  
AND medal IS NOT NULL  
AND medal != 'NA'  
GROUP BY sport, event
ORDER BY total_medals DESC
LIMIT 1;

-- 20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games

SELECT
  sport
 ,games
 ,event
 ,COUNT(medal) AS total_medals
FROM olympics_history
WHERE noc = 'IND'
AND medal IS NOT NULL
AND medal != 'NA'
GROUP BY sport
        ,event
        ,games
ORDER BY total_medals DESC
;