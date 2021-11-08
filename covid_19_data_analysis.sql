
-- select required data
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
WHERE total_cases <= 0 AND NOT ISNULL(continent,'') = ''
ORDER BY 1,2

-- total cases vs total deaths
CREATE VIEW total_cases_vs_total_deaths AS
	SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_percentage
	FROM covid_deaths
	WHERE total_cases > 0 AND NOT ISNULL(continent,'') = ''
	--ORDER BY 1,2;

-- total cases vs population
-- shows what percentage of pupulation got covid
CREATE VIEW total_cases_vs_population AS
	SELECT location, date, population, total_cases, (total_cases/population) * 100 AS infected_percentage
	FROM covid_deaths
	WHERE population > 0 AND NOT ISNULL(continent,'') = ''
	--ORDER BY 1,2

-- countries with highest infection rate compared to population
CREATE VIEW countries_highest_infection AS
	SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)) * 100 as infected_percentage
	FROM covid_deaths
	WHERE population > 0 AND NOT ISNULL(continent,'') = ''
	GROUP BY location, population
	--ORDER BY infected_percentage DESC

-- countries with highest death count per 1M
CREATE VIEW countries_highest_death AS
	SELECT location, MAX(total_deaths) AS total_death_count, MAX(total_deaths/population) * 1000000 AS deaths_per_million
	FROM covid_deaths
	WHERE  population > 0 AND NOT ISNULL(continent,'') = ''
	GROUP BY location
	--ORDER BY deaths_per_million DESC


-- continents with highest death count per 1M
CREATE VIEW continents_highest_death AS
	SELECT location, MAX(total_deaths) AS total_death_count, MAX(total_deaths/population) * 1000000 AS deaths_per_million
	FROM covid_deaths
	WHERE  population > 0 AND 
		ISNULL(continent,'') = '' AND
		location <> 'High income' AND
		location <> 'Upper middle income' AND
		location <> 'World' AND
		location <> 'Low income' AND
		location <> 'European Union' AND
		location <> 'Lower middle income'
	GROUP BY location
	--ORDER BY deaths_per_million DESC

-- global numbers
CREATE VIEW global_numbers AS
	SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 AS death_percentage
	FROM covid_deaths
	WHERE new_cases > 0 AND NOT ISNULL(continent,'') = ''
	--GROUP BY date
	--ORDER BY date --, death_percentage

-- daily vaccinations - using CTE - common table expression
CREATE VIEW daily_vaccinations AS
	WITH pop_vs_vac (continent, location, date, population, daily_vaccinations, total_vaccinations )
	AS
	(
		SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
			SUM(new_vaccinations) OVER 
				(PARTITION BY dea.location ORDER BY dea.location, dea.date) 
		FROM covid_deaths dea
		JOIN covid_vaccinations vac ON
			dea.location = vac.location and
			dea.date = vac.date
		WHERE NOT ISNULL(dea.continent,'') = '' AND dea.population > 0
		--ORDER BY 2,3
	)
	SELECT * , (total_vaccinations / population) * 100 AS vaccinate_percent
	FROM pop_vs_vac
	--ORDER BY 2,3

-- daily vaccinations - using TEMP tables
DROP TABLE IF EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	daily_vaccinations numeric,
	total_vaccinations numeric
)

INSERT INTO #percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(new_vaccinations) OVER 
		(PARTITION BY dea.location ORDER BY dea.location, dea.date) 
FROM covid_deaths dea
JOIN covid_vaccinations vac ON
	dea.location = vac.location and
	dea.date = vac.date
WHERE NOT ISNULL(dea.continent,'') = '' AND dea.population > 0

SELECT * , (total_vaccinations / population) * 100 AS vaccinate_percent
FROM #percent_population_vaccinated
ORDER BY 2,3



