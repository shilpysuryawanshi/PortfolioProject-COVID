-- CHECKING THE COUNT OF RECORDS IMPORTED
Select count(*)
From CovidPortfolioProject..CovidDeaths

--Select count(*)
--From CovidPortfolioProject..CovidVaccination

--  CHECKING THE DATA IMPORTED IS CORRECT OR NOT?
Select *
From CovidPortfolioProject..CovidDeaths
where continent is not NULL
order by 3,4 

--Select *
--FROM CovidPortfolioProject..CovidVaccination
--order by 3,4 

-- SELECTING THE DATA TO BE USED
Select [location],[date],total_cases,new_cases,total_deaths,population  
From CovidPortfolioProject..CovidDeaths
where continent is not NULL
order by 1, 2

-- ANALYZING TOTAL CASES VS TOTAL DEATHS
Select [location],[date],total_cases,total_deaths,(total_deaths/CAST (total_cases as FLOAT))*100 AS DeathPercentage
From CovidPortfolioProject..CovidDeaths
order by 1, 2

--------Likelihood of dying due to covid in your country------
Select [location],[date],total_cases,total_deaths,(total_deaths/CAST (total_cases as FLOAT))*100 AS DeathPercentage
From CovidPortfolioProject..CovidDeaths
where [location] like '%states%'
order by 1, 2
-------------------------------------------------------------

--ANALYZING TOTAL CASES VS POPULATION
Select [location],[date],population, total_cases,(total_cases/CAST (population as FLOAT))*100 AS PercentPopulationInfected
From CovidPortfolioProject..CovidDeaths
--where [location] like '%states%'
order by 1, 2

--Analyzing countries with highest infection rate 
Select [location],population, MAX(total_cases) as highestInfectionCount, MAX(total_cases/CAST (population as FLOAT))*100 AS PercentPopulationInfected
From CovidPortfolioProject..CovidDeaths
--where [location] like '%states%'
where continent is not NULL
Group by [location],population
order by 4 DESC

--Analyzing countries with highest death count per population 
Select [location], MAX(total_deaths) as totaldeathCount
From CovidPortfolioProject..CovidDeaths
--where [location] like '%states%'
--where continent is NULL
where continent is not NULL
Group by [location]
order by 2 DESC

--Analyzing deaths by Continent
Select [continent], MAX(total_deaths) as totaldeathCount
From CovidPortfolioProject..CovidDeaths
--where [location] like '%states%'
where continent is not NULL
Group by [continent]
order by 2 DESC

--Analyzing global numbers
Select [date],SUM(new_cases) as totalCases, SUM(new_deaths) as totalDeaths, SUM(new_deaths)/CAST(SUM(new_cases)as FLOAT)* 100 AS GlobalDeathPercentage
From CovidPortfolioProject..CovidDeaths
where continent is not NULL
Group By [date]
order by 1,2

--Analyzing global numbers till today
Select SUM(new_cases) as totalCases, SUM(new_deaths) as totalDeaths, SUM(new_deaths)/CAST(SUM(new_cases)as FLOAT)* 100 AS GlobalDeathPercentage
From CovidPortfolioProject..CovidDeaths
where continent is not NULL
--Group By [date]
order by 1,2

-- Analyzing total population vs vaccination

Select d.continent,d.location,d.date, d.population, v.new_vaccinations
From CovidPortfolioProject..CovidDeaths d
Join CovidPortfolioProject..CovidVaccination v
on  d.[location]= v.[location]
and d.[date] = v.[date]
where d.continent is not NULL
order by 2,3

-- Analyzing rolling vaccinations(summing) by location

Select d.continent,d.location,d.date, d.population, v.new_vaccinations, 
        SUM (v.new_vaccinations) over (PARTITION by d.[location] order by d.LOCATION, d.date ) as rolling_vac_people
From CovidPortfolioProject..CovidDeaths d
Join CovidPortfolioProject..CovidVaccination v
on  d.[location]= v.[location]
and d.[date] = v.[date]
where d.continent is not NULL
order by 2,3 

--Using CTE (common table expression) to calculate % of population vaccinated

With popvsvac (Continent,location,date,population,new_vaccinations,rolling_vac_people)
as
(Select d.continent,d.location,d.date, d.population, v.new_vaccinations, 
        SUM (v.new_vaccinations) over (PARTITION by d.[location] order by d.LOCATION, d.date ) as rolling_vac_people
From CovidPortfolioProject..CovidDeaths d
Join CovidPortfolioProject..CovidVaccination v
on  d.[location]= v.[location]
and d.[date] = v.[date]
where d.continent is not NULL
)
--order by 2,3 ) 
Select * , (rolling_vac_people/ Cast (population as float))*100 as perc_people_vac
From popvsvac
order by 2,3

--Using Temp Table

Drop Table if exists #percentpopvac
Create Table #percentpopvac
 ( Continent nvarchar(255),
 location nvarchar (255),
 date date,
 population numeric,
  new_vaccinations numeric,
   rolling_vac_people numeric)

Insert into #percentpopvac 
Select d.continent,d.location,d.date, d.population, v.new_vaccinations, 
        SUM (v.new_vaccinations) over (PARTITION by d.[location] order by d.LOCATION, d.date ) as rolling_vac_people
From CovidPortfolioProject..CovidDeaths d
Join CovidPortfolioProject..CovidVaccination v
on  d.[location]= v.[location]
and d.[date] = v.[date]
--where d.continent is not NULL

Select * , (rolling_vac_people/ Cast (population as float))*100 as perc_people_vac
From #percentpopvac 
order by 2,3

----- Creating VIEW to store data for later use

Create VIEW percentpopvac AS
Select d.continent,d.location,d.date, d.population, v.new_vaccinations, 
        SUM (v.new_vaccinations) over (PARTITION by d.[location] order by d.LOCATION, d.date ) as rolling_vac_people
From CovidPortfolioProject..CovidDeaths d
Join CovidPortfolioProject..CovidVaccination v
on  d.[location]= v.[location]
and d.[date] = v.[date]
where d.continent is not NULL

--- Use view to see results for percentage of population vacinated
Select *
From percentpopvac
     