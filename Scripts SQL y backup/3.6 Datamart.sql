USE SteamApplicationsDB
GO

/***********************Tablas de hechos***********************/

DROP SCHEMA IF EXISTS datamart
GO

CREATE SCHEMA datamart
GO

-- Tablas dimensionales

-- 1. Tabla dimensional: dim_ReleaseYear
DROP TABLE IF EXISTS datamart.dim_ReleaseYear
GO

CREATE TABLE datamart.dim_ReleaseYear
(
	dim_ReleaseYear_ID INT IDENTITY(1, 1) PRIMARY KEY,
	dim_year INT NOT NULL
)

INSERT INTO datamart.dim_ReleaseYear (dim_year)
	SELECT
		YEAR(SA.releaseDate)
	FROM SteamApplication SA
	GROUP BY YEAR(SA.releaseDate)
	ORDER BY YEAR(SA.releaseDate) ASC
GO

-- 2. Tabla dimensional: dim_RangePrice
DROP TABLE IF EXISTS datamart.dim_RangePrice
GO

CREATE TABLE datamart.dim_RangePrice
(
	dim_rangePriceID INT IDENTITY(1, 1) PRIMARY KEY,
	rangePriceDescription VARCHAR(64) NOT NULL
)

INSERT INTO datamart.dim_RangePrice (rangePriceDescription) VALUES
	('Free'), 
	('Low'), -- Mayor a $0 y menor a $10
	('Medium'), -- Mayor o igual a $10 y menor a $50
	('High') -- Mayor o igual $50
GO

-- 3. Tabla dimensional: dim_AgeClassification
DROP TABLE IF EXISTS datamart.dim_AgeClassification
GO

CREATE TABLE datamart.dim_AgeClassification
(
	ageClassificationID INT PRIMARY KEY,
	classDescription VARCHAR(16) NOT NULL
)

INSERT INTO datamart.dim_AgeClassification (ageClassificationID, classDescription)
	SELECT
		AC.ageClassificationID,
		AC.classDescription
	FROM AgeClassification AC
	ORDER BY AC.classDescription ASC
GO

-- 4. Tabla dimensional: dim_AppRating
DROP TABLE IF EXISTS datamart.dim_AppRating
GO

CREATE TABLE datamart.dim_AppRating
(
	dim_AppRating_ID INT IDENTITY(1, 1) PRIMARY KEY,
	appRatingDescription VARCHAR(64) NOT NULL
)

INSERT INTO datamart.dim_AppRating (appRatingDescription) VALUES
	('Bajo'), -- Menor al 60% de valoración
	('Medio'), -- Mayor o igual a 60% y menor al 85% de valoración
	('Alto'), -- Mayor o igual a 85% y menor al 95% de valoración
	('Superior') -- Mayor o igual al 95% de valoración
GO

-- 4. Tabla dimensional: dim_RankingByTotalUsers
DROP TABLE IF EXISTS datamart.dim_RankingByTotalUsers
GO

CREATE TABLE datamart.dim_RankingByTotalUsers
(
	dim_RankingByTotalUsers_ID INT IDENTITY(1, 1) PRIMARY KEY,
	rankingDescription VARCHAR(64) NOT NULL
)

INSERT INTO datamart.dim_RankingByTotalUsers (rankingDescription) VALUES
	('Poco alcance'), -- Menos de 10 000 de jugadores
	('Mediano alcance'), -- Mayor o igual a 10 000 y menor a 1 000 000 de jugadores
	('Gran alcance') -- Mayor o igual 1 000 000 de jugadores
GO

-- 5. Tabla de hechos: fact_SteamApplication
DROP TABLE IF EXISTS datamart.fact_SteamApplication
GO

CREATE TABLE datamart.fact_SteamApplication
(
	dim_App_ID VARCHAR(16) PRIMARY KEY,
	appName VARCHAR(256) NOT NULL,
	avgPlaytime DECIMAL(9, 2) NOT NULL,
	dim_ReleaseYear_ID INT NOT NULL REFERENCES datamart.dim_ReleaseYear (dim_ReleaseYear_ID),
	ageClassificationID INT NOT NULL REFERENCES datamart.dim_AgeClassification (ageClassificationID),
	rangePriceID INT NOT NULL REFERENCES datamart.dim_RangePrice (dim_rangePriceID),
	ratingID INT NOT NULL REFERENCES datamart.dim_AppRating (dim_AppRating_ID),
	rankingByTotalUsersID INT NOT NULL REFERENCES datamart.dim_RankingByTotalUsers (dim_RankingByTotalUsers_ID),
	-- isMultiGenre VARCHAR(8) NOT NULL,
	positiveRatings INT NOT NULL,
	negativeRatings INT NOT NULL,-- En %
	numUsers INT NOT NULL
)

INSERT INTO datamart.fact_SteamApplication 
		(dim_App_ID, appName, avgPlaytime, dim_ReleaseYear_ID,
		ageClassificationID, rangePriceID, ratingID, rankingByTotalUsersID,
		positiveRatings, negativeRatings, numUsers)
	SELECT
		SA.steamApplicationID,
		SA.applicationName,
		SA.avgPlaytime,
		DRY.dim_ReleaseYear_ID,
		SA.ageClassificationID, 
		(
			CASE
				WHEN SA.price = 0 
					THEN (SELECT RP.dim_rangePriceID FROM datamart.dim_RangePrice RP WHERE RP.rangePriceDescription = 'Free')
				WHEN SA.price > 0 AND  SA.price < 10
					THEN (SELECT RP.dim_rangePriceID FROM datamart.dim_RangePrice RP WHERE RP.rangePriceDescription = 'Low')
				WHEN SA.price >= 10 AND  SA.price < 50
					THEN (SELECT RP.dim_rangePriceID FROM datamart.dim_RangePrice RP WHERE RP.rangePriceDescription = 'Medium')
				ELSE (SELECT RP.dim_rangePriceID FROM datamart.dim_RangePrice RP WHERE RP.rangePriceDescription = 'High')
			END
		),
		(
			CASE
				WHEN CAST(SA.positiveRatings * 1. / (SA.positiveRatings + SA.negativeRatings) * 100 AS DECIMAL (4, 1)) < 60 
					THEN (SELECT AP.dim_AppRating_ID FROM datamart.dim_AppRating AP WHERE AP.appRatingDescription = 'Bajo')
				WHEN CAST(SA.positiveRatings * 1. / (SA.positiveRatings + SA.negativeRatings) * 100 AS DECIMAL (4, 1)) >= 60 
				AND  CAST(SA.positiveRatings * 1. / (SA.positiveRatings + SA.negativeRatings) * 100 AS DECIMAL (4, 1)) < 85
					THEN (SELECT AP.dim_AppRating_ID FROM datamart.dim_AppRating AP WHERE AP.appRatingDescription = 'Medio')
				WHEN CAST(SA.positiveRatings * 1. / (SA.positiveRatings + SA.negativeRatings) * 100 AS DECIMAL (4, 1)) >= 85 
				AND  CAST(SA.positiveRatings * 1. / (SA.positiveRatings + SA.negativeRatings) * 100 AS DECIMAL (4, 1)) < 95
					THEN (SELECT AP.dim_AppRating_ID FROM datamart.dim_AppRating AP WHERE AP.appRatingDescription = 'Alto')
				ELSE  (SELECT AP.dim_AppRating_ID FROM datamart.dim_AppRating AP WHERE AP.appRatingDescription = 'Superior')
			END
		),
		(
			CASE
				WHEN SA.apprNumberOwners < 10000
					THEN (SELECT RBTU.dim_RankingByTotalUsers_ID FROM datamart.dim_RankingByTotalUsers RBTU WHERE RBTU.rankingDescription = 'Poco alcance')
				WHEN SA.apprNumberOwners >= 10000 AND  SA.apprNumberOwners < 1000000
					THEN (SELECT RBTU.dim_RankingByTotalUsers_ID FROM datamart.dim_RankingByTotalUsers RBTU WHERE RBTU.rankingDescription = 'Mediano alcance')
				ELSE (SELECT RBTU.dim_RankingByTotalUsers_ID FROM datamart.dim_RankingByTotalUsers RBTU WHERE RBTU.rankingDescription = 'Gran alcance')
			END
		),
		SA.positiveRatings,
		SA.negativeRatings,
		SA.apprNumberOwners
	FROM SteamApplication SA
	INNER JOIN datamart.dim_ReleaseYear DRY
		ON YEAR(SA.releaseDate) = DRY.dim_year
	WHERE 
		SA.positiveRatings + SA.negativeRatings > 0
GO
