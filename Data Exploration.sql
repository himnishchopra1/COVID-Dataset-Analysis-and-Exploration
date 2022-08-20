-- COVID 19 dataset data exploration

-- Skills used: Aggregate Functions, CTE's, Joins, Creating Views, Data type conversion

-- COVID Deaths and Vaccinations Dataset

Select * 
From PortfolioProject..CovidDeaths
order by 3,4

-- Starting Data
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by Location,date

-- Finding out Total cases vs Total deaths per country
-- Shows the probabaility of dying if a person catches the virus in Candas
Select Location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where location like '%canada%'
and continent is not null
order by 1,2

-- Finding percentage of population that caught Covid compared to total population in a country 
-- and ordering it in descending order
Select Location, date, total_cases,population, (total_cases/population)* 100 as PercentOfPopulationPositive
From PortfolioProject..CovidDeaths
where continent is not null
order by 5 desc

-- Showing the Countries with the highest percentage of population that have the virus
Select Location, Population, MAX(total_cases) as HighestCaseCount, MAX(total_cases/population)* 100 as PercentOfPopulationPositive
From PortfolioProject..CovidDeaths 
where continent is not null
group by Location, Population
order by PercentOfPopulationPositive desc


-- DATA IS NOW BEING SEPARATED BY CONTINENT

-- Showing continents with highest Death Count 
-- SAVING THIS DATA AS A VIEW
Create view ContinentDeathCount as
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths 
where continent is not null
group by continent


-- DATA FOR THE WHOLE GLOBE

-- Amount of new cases, and new deaths that arise each day across the globe. 
-- Then looking at percentage of people who are dying due to the virus
Select date, SUM(new_cases) as NewCasesGlobal, SUM(cast(new_deaths as int)) as NewDeathsGlobal
, ((SUM(cast(new_deaths as int)))/(SUM(new_cases)))*100 as GlobalDeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1,2

-- Total cases and total deaths across the globe since the start of recoring the data
Select SUM(new_cases) as TotalCasesGlobal, SUM(cast(new_deaths as int)) as TotalDeathsGlobal
, round(((SUM(cast(new_deaths as int)))/(SUM(new_cases)))*100,2) as GlobalDeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
order by 1,2


-- COVID VACCINATIONS file

-- Day by day rolling sum of total vacciantaions in a country
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order 
by dea.location,dea.Date) as RollingNewVaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- Using CTE to determine percentage of people vaccinated based on previous query

With PopulationVsVaccination (continent, location, date, population, new_vaccinations
, RollingVaccinationCount)
as
(Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order 
by dea.location,dea.Date) as RollingNewVaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null)
Select *,(RollingVaccinationCount/population)*100 as PercentVaccinatedDaily 
From PopulationVsVaccination


-- TEMP TABLE

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
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order 
by dea.location,dea.Date) as RollingNewVaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null

Select *,(RollingPeopleVaccinated/population)*100 as PercentVaccinatedDaily 
From #PercentPopulationVaccinated


-- CREATING VIEW OF ROLLING PERCENT of the amaount of people vaccinated
Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order 
by dea.location,dea.Date) as RollingNewVaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
