/*

DATA EXPLORATION OF COVID DATA AND SQL QUERY REVIEW

https://ourworldindata.org/covid-deaths

Data collection began in January 2020 before Covid cases were identified in the U.S. Data continues to be collected, but the data for this
  analysis ends on 09/06/2021.

Skills: converting data types, aggregate functions, Windows functions, JOINs, CTE's, temp tables, views

Data is subsetted to two Excel files and then stored as two databases: CovidDeaths and CovidVaccinations

*/




--EXPLORING COVID DEATHS



--Select columns of interest, ordered by Continent, Location, and Date

SELECT Continent, Location, Date, Total_cases, New_cases, Total_deaths, Population
FROM PortfolioProject1..CovidDeaths
ORDER BY 1,2,3

--Continent has many NULL values so will not be used; Location specifies the country which is sufficient 



SELECT Location, Date, Total_cases, New_cases, Total_deaths, Population
FROM PortfolioProject1..CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 1,2



--Find countries with highest likelihood of Covid contraction

SELECT Location, MAX(CAST(Total_cases AS INT)) AS Totalcases, Population, (MAX(CAST(Total_cases AS INT)/Population))*100 AS MaxContractionRate
FROM PortfolioProject1..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Location, Population
ORDER BY MaxContractionRate DESC

--Seychelles has the highest contraction rate at 20.45%; the U.S. has the 12th highest rate at 12.02%.



--Find the likelihood of Covid contraction in the U.S.

SELECT Location, Date, MAX(CAST(Total_cases AS INT)) AS USTotalcases, Population, (MAX(CAST(Total_cases AS INT)/Population))*100 AS USContractionRate
FROM PortfolioProject1..CovidDeaths
WHERE Location LIKE 'United States'
GROUP BY Location, Population, Date
ORDER BY USContractionRate desc

--The highest contraction rate is 12.02%, recorded on the last day of data collection, 09/06/2021.



--Find the likelihood of mortality in the U.S. given contraction of Covid

SELECT Location, Date, Total_cases, Total_deaths, (Total_deaths/Total_cases)*100 AS USMortalityRate
FROM PortfolioProject1..CovidDeaths
WHERE Location LIKE 'United States'
ORDER BY Date

SELECT Location, Date, Total_cases, Total_deaths, (Total_deaths/Total_cases)*100 AS USMortalityRate
FROM PortfolioProject1..CovidDeaths
WHERE Location LIKE 'United States'
ORDER BY USMortalityRate DESC

--The first death is recorded on 02/29/2020. After the first five days of recorded deaths, the mortality rate ranges from 6.25% to 1.62%,
--generally decreasing over time.



--Find the countries with the highest mortality count

SELECT Location, MAX(CAST(Total_deaths AS INT)) AS TotalMorality
FROM PortfolioProject1..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Location
ORDER BY 2 DESC

--Total number of deaths ranks highest for the U.S., followed by Brazil and India. However, this is misleading, and population size needs
--consideration.



SELECT Location, MAX(CAST(Total_deaths AS INT)) AS TotalMorality, Population, 
 (MAX(CAST(Total_deaths AS INT))/Population) * 100 AS MortalityRate
FROM PortfolioProject1..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Location, Population
ORDER BY MortalityRate DESC

--When mortality rate based on population is calculated, the highest rate is for Peru at 0.60%, and U.S. ranks 23rd at 0.19%. 
--Brazil now ranks 8th at 0.27%; India ranks 100th at 0.03%.



--Find mortality rate for continents across entire population

SELECT Location, MAX(CAST(Total_deaths AS INT)/Population)*100 AS MortalityRate
FROM PortfolioProject1..CovidDeaths
WHERE Continent IS NULL
GROUP BY Location
ORDER BY MortalityRate DESC

--Continent totals are listed under Location where Continent is coded as NULL.
--Highest mortality rate is in South America at 0.26%, followed by Europe at 0.16% and North America at 0.17%.



--Find the total mortality rate across the world

SELECT SUM(New_cases) AS Total_cases, SUM(CAST(New_deaths AS INT)) AS Total_deaths, SUM(CAST(New_deaths AS INT))/SUM(New_cases)*100 AS GlobalMortalityRate
FROM PortfolioProject1..CovidDeaths
WHERE Continent IS NOT NULL
--GROUP BY Date
--ORDER BY 1,2

--The total mortality rate across the world is 2.07%




--EXPLORING COVID VACCINATIONS



--Join CovidVaccinations with CovidDeaths

SELECT Deaths.Continent, Deaths.Location, Deaths.Date, Deaths.Population, Vacs.New_vaccinations
FROM PortfolioProject1..CovidDeaths Deaths
JOIN PortfolioProject1..CovidVaccinations Vacs
	ON Deaths.Location = Vacs.Location
	AND Deaths.Date = Vacs.Date
WHERE Deaths.Continent IS NOT NULL
ORDER BY Location, Date



--Find count of population who have received at least one vaccination

SELECT Deaths.Continent, Deaths.Location, Deaths.Date, Deaths.Population, Vacs.New_vaccinations,
 SUM(CAST(Vacs.New_vaccinations AS INT)) OVER (PARTITION BY Deaths.Location ORDER BY deaths.Location,
 Deaths.Date) AS CumulativeVaccinated
--PARTITION BY Deaths.Location ensures that the running total of New_vaccinations is reset for each country.
FROM PortfolioProject1..CovidDeaths Deaths
JOIN PortfolioProject1..CovidVaccinations Vacs
	ON Deaths.Location = Vacs.Location
	AND Deaths.Date = Vacs.Date
WHERE Deaths.Continent IS NOT NULL
ORDER BY Deaths.Location, Deaths.Date



--Alternative way using CONVERT function

SELECT Deaths.Continent, Deaths.Location, Deaths.Date, Deaths.Population, Vacs.New_vaccinations,
 SUM(CONVERT(INT, Vacs.New_vaccinations)) OVER (PARTITION BY Deaths.Location ORDER BY Deaths.Location,
 Deaths.Date) AS CumulativeVaccinated
--Would like to use CummulativeVaccinated/Population * 100 here for vaccination rate, but a variable just created
--cannot be used in the SELECT statement so this code will be used as a CTE.
FROM PortfolioProject1..CovidDeaths Deaths
JOIN PortfolioProject1..CovidVaccinations Vacs
	ON Deaths.Location = Vacs.Location
	AND Deaths.Date = Vacs.Date
WHERE Deaths.Continent IS NOT NULL
ORDER BY Deaths.Location, Deaths.Date



--Use CTE to calculate a cumulative vaccination rate for each country using last query

WITH VacPerPop (Continent, Location, Date, Population, New_Vaccinations, CumulativeVaccinated)
AS
--Note that VacPerPop must have the same number of variables AS the SELECT statement
(
SELECT Deaths.Continent, Deaths.Location, Deaths.Date, Deaths.Population, Vacs.New_vaccinations,
 SUM(CONVERT(INT, Vacs.New_vaccinations)) OVER (PARTITION BY Deaths.Location ORDER BY deaths.Location,
 Deaths.Date) AS CumulativeVaccinated
FROM PortfolioProject1..CovidDeaths Deaths
JOIN PortfolioProject1..CovidVaccinations Vacs
	ON Deaths.Location = Vacs.Location
	AND Deaths.Date = Vacs.Date
WHERE Deaths.Continent IS NOT NULL
--ORDER BY Deaths.Continent, Deaths.Location
--the ORDER statement can not be in the CTE
)
SELECT *, (CumulativeVaccinated/Population) * 100 AS VacRate
FROM VacPerPop

--Upon closer examination the New_vaccinations field must include initial and sometimes subsequent vaccinations
--for an individual because the final vaccination rate for the U.S. is 108.08%. For future data analysis investigate
--other variables that differentitate between intial and subsequent vaccinations for an individual.



--Create a temp table for cumulative vaccination count

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_vaccinations NUMERIC,
CumulativeVaccinated NUMERIC
)
INSERT INTO #PercentPopulationVaccinated
SELECT Deaths.Continent, Deaths.Location, Deaths.Date, Deaths.Population, Vacs.New_vaccinations,
 SUM(CONVERT(INT, Vacs.new_vaccinations)) OVER (PARTITION BY Deaths.Location ORDER BY deaths.Location,
 Deaths.Date) AS CumulativeVaccinated
FROM PortfolioProject1..CovidDeaths Deaths
JOIN PortfolioProject1..CovidVaccinations Vacs
	ON Deaths.Location = Vacs.Location
	AND Deaths.Date = Vacs.Date
WHERE Deaths.Continent IS NOT NULL



--Use temp table #PercentPopulationVaccinated to calculate vaccination rate

SELECT *, (CumulativeVaccinated/Population) * 100 AS VacRate
FROM #PercentPopulationVaccinated



--Create a view to store data of vaccination totals for each country for visualization

CREATE VIEW TotalVaccinations AS
SELECT Deaths.Continent, Deaths.Location, Deaths.Date, Deaths.Population, Vacs.new_vaccinations,
 SUM(CONVERT(INT, Vacs.New_vaccinations)) OVER (PARTITION BY Deaths.Location ORDER BY Deaths.Location,
 Deaths.Date) AS CumulativeVaccinated
FROM PortfolioProject1..CovidDeaths Deaths
JOIN PortfolioProject1..CovidVaccinations Vacs
	ON Deaths.Location = Vacs.Location
	AND Deaths.Date = Vacs.Date
WHERE Deaths.Continent IS NOT NULL 


--Check with a SELECT statement
SELECT * FROM TotalVaccinations
ORDER BY 2,3



--CONCLUSION

--Serious analysis requires investigation of other variables not addressed in this EDA, particularly to undertand how the data was
--collected regarding cases, deaths, and vaccinations recorded to get accurate statistics.



