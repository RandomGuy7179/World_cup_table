/* Joining the original 2 datasets (results and shootouts) into one.*/
CREATE OR REPLACE VIEW games AS
(
    SELECT results.date, results.home_team,results.away_team,home_score,away_score,
    CASE 
        WHEN results.home_score > results.away_score THEN results.home_team 
        WHEN results.away_score > results.home_score THEN results.away_team
        ELSE 'Draw'
    END AS winner,
    CASE 
        WHEN results.home_score > results.away_score THEN results.away_team 
        WHEN results.away_score > results.home_score THEN results.home_team
        ELSE 'Draw'
    END AS loser,
    tournament,city,country,neutral,
    CASE 
        WHEN winner IS NOT NULL THEN 1 ELSE 0 
    END AS shootout,
    winner as shootout_winner,
    CASE
        WHEN winner = results.home_team THEN results.away_team
        WHEN winner = results.away_team THEN results.home_team
    END AS shootout_loser
    
    FROM results
    LEFT JOIN shootouts ON results.date = shootouts.date
        AND results.home_team = shootouts.home_team
        AND results.away_team = shootouts.away_team
)

/* Data from wikipedia. Holds information on all the world cup winners */
CREATE TABLE world_cup_winners(  
    team VARCHAR(30),  
    world_cups_won INT,  
    runner_ups INT,
  	finals_played INT,
    PRIMARY KEY(team)  
);
INSERT INTO world_cup_winners (team,world_cups_won,runner_ups,finals_played)
VALUES
	('Brazil',5,2,7),
	('Germany',4,4,8),
	('Italy',4,2,6),
	('Argentina',2,3,5),
    ('France',2,1,3),
    ('Uruguay',2,0,2),
    ('Spain',1,0,1),
    ('England',1,0,1),
    ('Netherlands',0,3,3),
    ('Czechoslovakia',0,2,2),
    ('Hungary',0,2,2),
    ('Sweden',0,1,1),
    ('Croatia',0,1,1);

/* Creating end_result table that will be a table where each row holds statistics for every team that has played at the world cup */
CREATE TABLE end_result AS(
  -- win rate for world cup matches
  WITH win_table AS(
    SELECT 
        winner,
        COUNT(winner) AS wins,
        (SELECT count(*) FROM games as g WHERE (home_team = games.winner OR away_team = games.winner) AND tournament = 'FIFA World Cup') AS games_played,
        CAST((COUNT(winner) / (SELECT count(*) FROM games as g WHERE (home_team = games.winner OR away_team = games.winner) AND tournament = 'FIFA World Cup')) * 100 AS DECIMAL(12,2)) AS win_rate
    FROM games
    WHERE winner != 'Draw' AND tournament = 'FIFA World Cup'
    GROUP BY winner
    ORDER BY winner
  ),

  -- loss rate for world cup matches
  loss_table AS(
  SELECT 
      loser,
      COUNT(loser) AS losses,
      (SELECT count(*) FROM games as g WHERE (home_team = games.loser OR away_team = games.loser) AND tournament = 'FIFA World Cup') AS games_played,
      CAST((COUNT(loser) / (SELECT count(*) FROM games as g WHERE (home_team = games.loser OR away_team = games.loser) AND tournament = 'FIFA World Cup')) * 100 AS DECIMAL(12,2)) AS loss_rate
  FROM games
  WHERE loser != 'Draw' AND tournament = 'FIFA World Cup'
  GROUP BY loser
  ORDER BY loser
  ),

  -- goals scored and conceded
  goals_scored_conceded AS(
    SELECT 
        loser AS team,
        (SELECT
            SUM(
                CASE
                    WHEN games.loser = home_team THEN home_score
                    WHEN games.loser = away_team THEN away_score
                END
            ) AS goals_scored
         FROM games g
         WHERE tournament = 'FIFA World Cup'
        ) AS goals_scored,

        (SELECT
            SUM(
                CASE
                    WHEN games.loser = home_team THEN away_score
                    WHEN games.loser = away_team THEN home_score
                END
            ) AS goals_conceded
         FROM games g
         WHERE tournament = 'FIFA World Cup'
        ) AS goals_conceded    
    FROM games
    WHERE loser <> 'Draw' AND tournament = 'FIFA World Cup'
    GROUP BY loser
    ORDER BY loser
  ),

  -- shootout wins
  shootout_wins AS(
  SELECT 
      shootout_winner,
      COUNT(shootout_winner) AS shootout_wins,
      (SELECT count(*) FROM games as g WHERE (home_team = games.shootout_winner OR away_team = games.shootout_winner) AND tournament = 'FIFA World Cup' AND shootout = 1) AS shootouts_played,
      CAST((COUNT(shootout_winner) / (SELECT count(*) FROM games as g WHERE (home_team = games.shootout_winner OR away_team = games.shootout_winner) AND tournament = 'FIFA World Cup' AND shootout = 1)) * 100 AS DECIMAL(12,2)) AS shootout_win_rate
  FROM games
  WHERE tournament = 'FIFA World Cup' AND shootout = 1
  GROUP BY shootout_winner
  ORDER BY shootout_wins DESC, shootout_win_rate DESC
  ),

  -- shootout losses
  shootout_losses AS(
  SELECT 
      shootout_loser,
      COUNT(shootout_loser) AS shootout_losses,
      (SELECT count(*) FROM games as g WHERE (home_team = games.shootout_loser OR away_team = games.shootout_loser) AND tournament = 'FIFA World Cup' AND shootout = 1) AS shootouts_played,
      CAST((COUNT(shootout_loser) / (SELECT count(*) FROM games as g WHERE (home_team = games.shootout_loser OR away_team = games.shootout_loser) AND tournament = 'FIFA World Cup' AND shootout = 1)) * 100 AS DECIMAL(12,2)) AS shootout_loss_rate
  FROM games
  WHERE tournament = 'FIFA World Cup' AND shootout = 1
  GROUP BY shootout_loser
  ORDER BY shootout_losses DESC, shootout_loss_rate DESC
  )

  SELECT loser AS team,
  	  world_cups_won,
      runner_ups,
      finals_played,
      win_table.wins, 
      win_rate, 
      losses, 
      loss_rate, 
      loss_table.games_played, 
      goals_scored, 
      goals_conceded, 
      shootout_wins,
      shootout_win_rate,
      shootout_losses,
      shootout_loss_rate,
      CASE
          WHEN shootout_wins.shootouts_played IS NOT NULL THEN shootout_wins.shootouts_played
          WHEN shootout_losses.shootouts_played IS NOT NULL THEN shootout_losses.shootouts_played
          ELSE 0
      END AS shootouts_played
  FROM win_table
  -- Right join needed because not all teams have won a game while all teams have at least lost onece
  RIGHT JOIN loss_table ON winner = loser
  RIGHT JOIN goals_scored_conceded ON loser = team
  LEFT JOIN shootout_wins ON loser = shootout_winner
  LEFT JOIN shootout_losses ON loser = shootout_loser
  LEFT JOIN world_cup_winners ON loser = world_cup_winners.team

  -- Gets rid of team Yugoslavia which has been succeeded and Czech Republic which doesn't include the record from its predecessor Czechoslovakia.
  WHERE loser NOT IN ('Yugoslavia', 'Czech Republic')
)
  -- interesting to note that pks dont count as wins according to wikipedia

/*FINAL CLEANING OF end_results TABLE */
-- setting values to 0 for teams that haven't played in a world cup final
UPDATE end_result
SET world_cups_won = 0, runner_ups = 0, finals_played = 0
WHERE finals_played IS NULL;

-- setting values to 0 for teams that have been to a world cup but never won a match
UPDATE end_result
SET wins = 0, win_rate = 0.00
WHERE wins IS NULL;

-- setting values to 0 for teams that haven't won a world cup shootout
UPDATE end_result
SET shootout_wins = 0, shootout_win_rate = 0.00
WHERE shootout_wins IS NULL;

-- setting vales to 0 for teams that haven't lost a world cup shootout
UPDATE end_result
SET shootout_losses = 0, shootout_loss_rate = 0.00
WHERE shootout_losses IS NULL;

-- updating Serbia's values to included Yugoslavia's record at the world cup since Serbia is the successor to Yugoslavia.
-- Got this information from wikipedia
UPDATE end_result
SET games_played = 46, wins = 18, win_rate = 39.13, losses = 20, loss_rate = 43.48, goals_scored = 66, goals_conceded = 63,
	shootout_losses = 1, shootout_loss_rate = 100.00, shootouts_played = 1
WHERE team = 'Serbia'

-- Updating Czechoslovakia to Czech Republic because the latter is the successor of the former
UPDATE end_result
SET games_played = 33, wins = 12, win_rate = 36.36, losses = 16, loss_rate = 48.48, goals_scored = 47, goals_conceded = 49,
	team = 'Czech Republic'
WHERE team = 'Czechoslovakia'

-- changing German DR name to East Germany since it is most commonly known as such
UPDATE end_result
SET team = 'East Germany'
WHERE team = 'German DR'


-- final table with number of draws column, draw_rate column, goal difference column, and total points earned column added
-- This is the table used for the Tableau Dashboard.
SELECT
	ROW_NUMBER() OVER (ORDER BY (wins * 3) + (games_played - (wins + losses)) DESC, goals_scored - goals_conceded DESC, goals_scored DESC) AS ranking,
	team,
    world_cups_won,
    runner_ups,
    finals_played,
    (wins * 3) + (games_played - (wins + losses)) AS total_points,
    wins,
    win_rate,
    losses,
    loss_rate,
    games_played - (wins + losses) AS draws,
    100.00 - (win_rate + loss_rate) AS draw_rate,
    games_played,
    goals_scored,
    goals_conceded,
    goals_scored - goals_conceded AS goal_difference,
    shootout_wins,
    shootout_win_rate,
    shootout_losses,
    shootout_loss_rate,
    shootouts_played
FROM end_result










