--SELECT 
--	location,
--	date,
--	total_cases,
--	new_cases,
--	total_deaths,
--	population
--FROM CovidDeaths
--ORDER BY 1, 2

-- Looking at Total Cases vs Total Deaths
-- Show likelihood of dying if you contract covid in your country

--SELECT
--	"location",
--	"date",
--	total_cases,
--	total_deaths,
--	(total_deaths/total_cases)*100 AS DeathPercentage
--FROM CovidDeaths
--WHERE location LIKE '%Argentina%'
--ORDER BY 1, 2 DESC

-- Looking at Total Cases vs Population
-- Shows what percentaje of population got Covid

--SELECT
--	"location",
--	"date",
--	"population",
--	total_cases,
--	(total_cases/population)*100 AS perc_population_infected
--FROM CovidDeaths
--WHERE location LIKE '%Argentina%'
--ORDER BY 1, 2 DESC

-- Looking at Countries with Highest Infection Rate compared to Population

--SELECT
--	"location",
--	"population",
--	MAX(total_cases) AS highest_infection_count,
--	MAX((total_cases/population))*100 AS perc_population_infected
--FROM CovidDeaths
---- WHERE location LIKE '%Argentina%'
--GROUP BY 
--	"location",
--	"population"
--ORDER BY 4 DESC

-- Showing Countries with Highest Death Count per Population

SELECT
	"location",
	MAX(CAST(Total_deaths AS INT)) AS total_death_count
FROM CovidDeaths
-- WHERE location LIKE '%Argentina%'
WHERE continent IS NOT NULL
GROUP BY "location"
ORDER BY 2 DESC

-- Let's break things by continent

-- Showing continents with the highest death count per population

SELECT
	continent,
	MAX(CAST(Total_deaths AS INT)) AS total_death_count
FROM CovidDeaths
-- WHERE location LIKE '%Argentina%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC

-- GLOBAL NUMBER

SELECT
	"date",
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_perc
FROM CovidDeaths
-- WHERE location LIKE '%Argentina%'
WHERE continent IS NOT NULL
GROUP BY "date"
ORDER BY 1, 2 DESC



SELECT
	--"date",
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_perc
FROM CovidDeaths
-- WHERE location LIKE '%Argentina%'
WHERE continent IS NOT NULL
--GROUP BY "date"
ORDER BY 1, 2 DESC


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT
	dea.continent,
	dea."location",
	dea."date",
	dea."population",
	vac.new_vaccinations,
	SUM(CONVERT(INT, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date ROWS UNBOUNDED PRECEDING) AS RollingPeopleVaccinated
	--, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

CREATE VIEW NewPercentPopulationVaccinated AS
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations, 
	SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date ROWS UNBOUNDED PRECEDING) as RollingPeopleVaccinated
	--, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL




/*
Queries used for Tableau Project
*/

-- 1. 

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- Just a double check based off the data provided
-- numbers are extremely close so we will keep them - The Second includes "International"  Location


--Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
--From PortfolioProject..CovidDeaths
----Where location like '%states%'
--where location = 'World'
----Group By date
--order by 1,2


-- 2. 

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From CovidDeaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc


-- 3.

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- 4.


Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc
