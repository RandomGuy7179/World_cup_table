# World_cup_table
Project created using SQL to create a table summarizing world cup statistics and Tableau to visualize the table's results.
## Table of Contents
  - [Introduction](#Introduction)
  - [SQL](#SQL)
  - [Tableau](#Tableau)

## Introduction
The goal of this project was to extract statistics on the performance of all the 79 teams that have participated in the world cup from its inception in 1930 to 2018. The data I wanted was extracted from a [dataset](https://www.kaggle.com/datasets/martj42/international-football-results-from-1872-to-2017?select=results.csv) that contains the result data of over 40,000 official national team matches from 1873 to 2022. Using SQL, I queried the dataset and ended up with a table of 79 rows for every team that has played at the world cup. Using this new table, I used Tableau to create a dashboard that visually showcases the data from the table.

## SQL
Using SQL, I queried the original dataset to extract the data I needed to create the table I had in mind. I used different clauses such as CASE, JOIN, GROUP BY, PARTITION BY, WITH, etc. to query relevant information such as the teams that played in a match, score, winner, loser, and type of tournament. When I obtained the data I needed from the original dataset, I created a new [table](https://github.com/RandomGuy7179/World_cup_table/blob/main/world_cup_table_2.csv) by using case statements, windowed functions, CTEs, joins, and subqueries that contains statistics on each team that has played at a world cup. This table includes information such as ranking, number of world cups won, total number of points, total number of wins and losses, and number of games played of a team.

## Tableau
After creating my table, I moved to Tableau to create a [dashboard](https://public.tableau.com/app/profile/hector.penado.jr/viz/world_cup_data_dashboard/Dashboard1) that summarized the performance of teams at the world cup. I created a dashboard that includes a bar chart, pie, chart, scatterplot, and table that are interactive. In the dashboard you can view the win/loss/draw rate, penalty shootout performance, goal difference, performance at the finals for all or specific teams you want to look at.

