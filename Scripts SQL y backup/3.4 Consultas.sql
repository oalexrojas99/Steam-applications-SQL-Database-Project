USE SteamApplicationsDB
GO

/*1. Géneros de juegos que tienen mayor preferencia por los
	usuarios de Steam. Dichos géneros deben estar presentes,
	al menos, en el 10% de los juegos que han sido registrados en la plataforma Steam.*/

DECLARE @vNumtotal AS INT
SET @vNumtotal = (SELECT COUNT(*) FROM SteamApplication SA_2)

SELECT
	G.genreDescription AS 'Género',
	CONCAT(CAST((COUNT(*) * 1. / @vNumtotal) * 100 AS DECIMAL (7, 4)), '%') AS 'Presencia',
	CONCAT(CAST(AVG(SA.positiveRatings * 1. / (SA.positiveRatings + SA.negativeRatings)) * 100 AS DECIMAL (4, 1)), '%') AS 'Promedio de aprobación'
FROM SteamApplication SA
INNER JOIN SteamApplication_Genre SAG
	ON SA.steamApplicationID = SAG.steamApplicationID
INNER JOIN Genre G
	ON G.genreID = SAG.genreID
GROUP BY G.genreDescription
HAVING
	COUNT(G.genreDescription) > CAST(@vNumtotal * 1. * 0.1 AS INT) 
ORDER BY [Promedio de aprobación] DESC
GO

/*2. Top 50 de los juegos con mejor valoración. Dichos
	juegos deben ser jugados por, al menos, 3 millones de jugadores
	y mostrados de forma detallada.*/
SELECT TOP 50
	SA.applicationName AS 'Videojuego',
	CONCAT
	(
		DAY(SA.releaseDate), ' de ',
		CASE
			WHEN MONTH(SA.releaseDate) = 1 THEN 'enero'
			WHEN MONTH(SA.releaseDate) = 2 THEN 'febrero'
			WHEN MONTH(SA.releaseDate) = 3 THEN 'marzo'
			WHEN MONTH(SA.releaseDate) = 4 THEN 'abril'
			WHEN MONTH(SA.releaseDate) = 5 THEN 'mayo'
			WHEN MONTH(SA.releaseDate) = 6 THEN 'junio'
			WHEN MONTH(SA.releaseDate) = 7 THEN 'julio'
			WHEN MONTH(SA.releaseDate) = 8 THEN 'agosto'
			WHEN MONTH(SA.releaseDate) = 9 THEN 'septiembre'
			WHEN MONTH(SA.releaseDate) = 10 THEN 'octubre'
			WHEN MONTH(SA.releaseDate) = 11 THEN 'noviembre'
			ELSE 'diciembre'
		END, ' de ',
		YEAR(SA.releaseDate)
	) AS 'Fecha de lanzamiento',
	(
		SELECT
			STRING_AGG(P.publisherName, ', ')
		FROM SteamApplication_Publisher SAP
		INNER JOIN Publisher P
			ON SAP.publisherID = P.publisherID
		WHERE SAP.steamApplicationID = SA.steamApplicationID
	) AS 'Distribuidores',
	(
		SELECT
			STRING_AGG(G.genreDescription, ', ')
		FROM SteamApplication_Genre SAG
		INNER JOIN Genre G
			ON SAG.genreID = G.genreID
		WHERE SAG.steamApplicationID = SA.steamApplicationID
	) AS 'Géneros',
	(
		SELECT
			STRING_AGG(T.tagDescription, ', ')
		FROM SteamApplication_Tag SAT
		INNER JOIN Tag T
			ON SAT.tagID = T.tagID
		WHERE SAT.steamApplicationID = SA.steamApplicationID
	) AS 'Etiquetas',
	AG.classDescription AS 'Clasificación de edad',
	-- CONCAT(CAST(SA.apprNumberOwners * 1. / 1000000 AS DECIMAL (5, 1)), ' millones')
	(
		CASE
			WHEN SA.apprNumberOwners >= 1000000 THEN CONCAT(CAST(SA.apprNumberOwners * 1. / 1000000 AS DECIMAL (5, 1)), ' millones')
			ELSE CONCAT(CAST(SA.apprNumberOwners * 1. / 100000 AS DECIMAL (4, 1)), ' miles')
		END
	) AS 'Número aproximado de jugadores',
	CONCAT(CAST(SA.positiveRatings * 1. / (SA.positiveRatings + SA.negativeRatings) * 100 AS DECIMAL (4, 1)), '%') AS 'Valoración'
FROM SteamApplication SA
INNER JOIN AgeClassification AG
	ON AG.ageClassificationID = SA.ageClassificationID
WHERE
	SA.apprNumberOwners >= 3000000
ORDER BY [Valoración] DESC

/*3. Mostrar detalladamente la información de cada juego registrado. Mencionar los SO's compatibles,
	características (tags, géneros, distribuidores y desarrolladores).*/
DROP VIEW IF EXISTS vInfoBySteamApp
GO

CREATE VIEW vInfoBySteamApp
AS
	SELECT
		SA.steamApplicationID AS 'ID',
		SA.applicationName AS 'Videojuego',
		CONCAT
		(
			DAY(SA.releaseDate), ' de ',
			CASE
				WHEN MONTH(SA.releaseDate) = 1 THEN 'enero'
				WHEN MONTH(SA.releaseDate) = 2 THEN 'febrero'
				WHEN MONTH(SA.releaseDate) = 3 THEN 'marzo'
				WHEN MONTH(SA.releaseDate) = 4 THEN 'abril'
				WHEN MONTH(SA.releaseDate) = 5 THEN 'mayo'
				WHEN MONTH(SA.releaseDate) = 6 THEN 'junio'
				WHEN MONTH(SA.releaseDate) = 7 THEN 'julio'
				WHEN MONTH(SA.releaseDate) = 8 THEN 'agosto'
				WHEN MONTH(SA.releaseDate) = 9 THEN 'septiembre'
				WHEN MONTH(SA.releaseDate) = 10 THEN 'octubre'
				WHEN MONTH(SA.releaseDate) = 11 THEN 'noviembre'
				ELSE 'diciembre'
			END, ' de ',
			YEAR(SA.releaseDate)
		) AS 'Fecha de lanzamiento',
		(
			SELECT
				STRING_AGG(C.categoryDescription, ', ')
			FROM SteamApplication_Category SAC
			INNER JOIN Category C
				ON SAC.categoryID = C.categoryID
			WHERE SAC.steamApplicationID = SA.steamApplicationID
		) AS 'Categorías',
		(
			SELECT
				STRING_AGG(P.publisherName, ', ')
			FROM SteamApplication_Publisher SAP
			INNER JOIN Publisher P
				ON SAP.publisherID = P.publisherID
			WHERE SAP.steamApplicationID = SA.steamApplicationID
		) AS 'Distribuidores',
		(
			SELECT
				STRING_AGG(D.developerName, ', ')
			FROM SteamApplication_Developer SAD
			INNER JOIN Developer D
				ON SAD.developerID = D.developerID
			WHERE SAD.steamApplicationID = SA.steamApplicationID
		) AS 'Desarrolladores',
		(
			SELECT
				STRING_AGG(G.genreDescription, ', ')
			FROM SteamApplication_Genre SAG
			INNER JOIN Genre G
				ON SAG.genreID = G.genreID
			WHERE SAG.steamApplicationID = SA.steamApplicationID
		) AS 'Géneros',
		(
			SELECT
				STRING_AGG(T.tagDescription, ', ')
			FROM SteamApplication_Tag SAT
			INNER JOIN Tag T
				ON SAT.tagID = T.tagID
			WHERE SAT.steamApplicationID = SA.steamApplicationID
		) AS 'Etiquetas',
		(
			SELECT
				STRING_AGG(SP.supportedPlatformDescription, ', ')
			FROM SteamApplication_SupportedPlatform SASP
			INNER JOIN SupportedPlatform SP
				ON SASP.supportedPlatformID = SP.supportedPlatformID
			WHERE SASP.steamApplicationID = SA.steamApplicationID
		) AS 'Sistemas operativos compatibles',
		AC.classDescription AS 'Clasificación de edad',
		(
			CASE
				WHEN SA.apprNumberOwners >= 1000000 THEN CONCAT(CAST(SA.apprNumberOwners * 1. / 1000000 AS DECIMAL (5, 1)), ' millones')
				ELSE CONCAT(CAST(SA.apprNumberOwners * 1. / 100000 AS DECIMAL (5, 2)), ' miles')
			END
		) AS 'Número aproximado de jugadores',
		CONCAT(CAST(SA.positiveRatings * 1. / (SA.positiveRatings + SA.negativeRatings) * 100 AS DECIMAL (4, 1)), '%') AS 'Valoración',
		CONCAT('$ ', SA.price) AS 'Precio en USD',
		SI.supportEmail AS 'Email de contacto de soporte'
	FROM SteamApplication SA
	INNER JOIN AgeClassification AC
		ON SA.ageClassificationID= AC.ageClassificationID
	LEFT JOIN SupportInfo SI
		ON SA.supportInfoID = SI.supportInfoID
GO

SELECT * FROM vInfoBySteamApp
GO

/*4. Determinar el porcentaje de cada género asociado a una categoría de 
	un videojuego.*/
SELECT
	C.categoryDescription AS 'Categoría',
	G.genreDescription AS 'Género',
	CAST(COUNT(*) * 100. / SUM(COUNT(*)) OVER (PARTITION BY C.categoryDescription) AS DECIMAL (5, 2))
		AS '% que pertenecen a este género dentro de esta categoría'

FROM SteamApplication SA
INNER JOIN SteamApplication_Category SAC
	ON SA.steamApplicationID = SAC.steamApplicationID
INNER JOIN Category C
	ON SAC.categoryID = C.categoryID
INNER JOIN SteamApplication_Genre SAG
	ON SA.steamApplicationID = SAG.steamApplicationID
INNER JOIN Genre G
	ON SAG.genreID = G.genreID
GROUP BY C.categoryDescription, G.genreDescription
ORDER BY C.categoryDescription ASC, [% que pertenecen a este género dentro de esta categoría] DESC
GO

/*5. Consultar toda la información relacioanada a un juego según su nombre. Esto 
	puede extenderse a más registros ya que puede haber una coincidencia en el
	nombre con otros juego. Es necesario crear Stored Procedure.*/

DROP PROCEDURE IF EXISTS SP_AppInfo_By_Name
GO

CREATE PROCEDURE SP_AppInfo_By_Name (@appName VARCHAR(512))
AS
BEGIN
	SELECT
		SA.steamApplicationID AS 'ID',
		SA.applicationName AS 'Videojuego',
		CONCAT
		(
			DAY(SA.releaseDate), ' de ',
			CASE
				WHEN MONTH(SA.releaseDate) = 1 THEN 'enero'
				WHEN MONTH(SA.releaseDate) = 2 THEN 'febrero'
				WHEN MONTH(SA.releaseDate) = 3 THEN 'marzo'
				WHEN MONTH(SA.releaseDate) = 4 THEN 'abril'
				WHEN MONTH(SA.releaseDate) = 5 THEN 'mayo'
				WHEN MONTH(SA.releaseDate) = 6 THEN 'junio'
				WHEN MONTH(SA.releaseDate) = 7 THEN 'julio'
				WHEN MONTH(SA.releaseDate) = 8 THEN 'agosto'
				WHEN MONTH(SA.releaseDate) = 9 THEN 'septiembre'
				WHEN MONTH(SA.releaseDate) = 10 THEN 'octubre'
				WHEN MONTH(SA.releaseDate) = 11 THEN 'noviembre'
				ELSE 'diciembre'
			END, ' de ',
			YEAR(SA.releaseDate)
		) AS 'Fecha de lanzamiento',
		(
			SELECT
				STRING_AGG(C.categoryDescription, ', ')
			FROM SteamApplication_Category SAC
			INNER JOIN Category C
				ON SAC.categoryID = C.categoryID
			WHERE SAC.steamApplicationID = SA.steamApplicationID
		) AS 'Categorías',
		(
			SELECT
				STRING_AGG(P.publisherName, ', ')
			FROM SteamApplication_Publisher SAP
			INNER JOIN Publisher P
				ON SAP.publisherID = P.publisherID
			WHERE SAP.steamApplicationID = SA.steamApplicationID
		) AS 'Distribuidores',
		(
			SELECT
				STRING_AGG(D.developerName, ', ')
			FROM SteamApplication_Developer SAD
			INNER JOIN Developer D
				ON SAD.developerID = D.developerID
			WHERE SAD.steamApplicationID = SA.steamApplicationID
		) AS 'Desarrolladores',
		(
			SELECT
				STRING_AGG(G.genreDescription, ', ')
			FROM SteamApplication_Genre SAG
			INNER JOIN Genre G
				ON SAG.genreID = G.genreID
			WHERE SAG.steamApplicationID = SA.steamApplicationID
		) AS 'Géneros',
		(
			SELECT
				STRING_AGG(T.tagDescription, ', ')
			FROM SteamApplication_Tag SAT
			INNER JOIN Tag T
				ON SAT.tagID = T.tagID
			WHERE SAT.steamApplicationID = SA.steamApplicationID
		) AS 'Etiquetas',
		(
			SELECT
				STRING_AGG(SP.supportedPlatformDescription, ', ')
			FROM SteamApplication_SupportedPlatform SASP
			INNER JOIN SupportedPlatform SP
				ON SASP.supportedPlatformID = SP.supportedPlatformID
			WHERE SASP.steamApplicationID = SA.steamApplicationID
		) AS 'Sistemas operativos compatibles',
		AC.classDescription AS 'Clasificación de edad',
		(
			SELECT
				STRING_AGG(SAAMFT.urlMediaFile, ', ')
			FROM SteamApplication_ApplicationMediaFileType SAAMFT
			INNER JOIN ApplicationMediaFileType AMFT
				ON SAAMFT.applicationMediaFileTypeID = AMFT.applicationMediaFileTypeID
			WHERE 
				SAAMFT.steamApplicationID = SA.steamApplicationID
				AND AMFT.applicationMediaFileTypeDescription = 'header_image'
		) AS 'Portada',
		(
			SELECT
				STRING_AGG(SAAMFT.urlMediaFile, ', ')
			FROM SteamApplication_ApplicationMediaFileType SAAMFT
			INNER JOIN ApplicationMediaFileType AMFT
				ON SAAMFT.applicationMediaFileTypeID = AMFT.applicationMediaFileTypeID
			WHERE 
				SAAMFT.steamApplicationID = SA.steamApplicationID
				AND AMFT.applicationMediaFileTypeDescription = 'background'
		) AS 'Fondo',
		(
			SELECT
				STRING_AGG(SAAMFT.urlMediaFile, ', ')
			FROM SteamApplication_ApplicationMediaFileType SAAMFT
			INNER JOIN ApplicationMediaFileType AMFT
				ON SAAMFT.applicationMediaFileTypeID = AMFT.applicationMediaFileTypeID
			WHERE 
				SAAMFT.steamApplicationID = SA.steamApplicationID
				AND AMFT.applicationMediaFileTypeDescription = 'screenshots'
		) AS 'Capturas de pantalla',
		(
			SELECT
				STRING_AGG(SAAMFT.urlMediaFile, ', ')
			FROM SteamApplication_ApplicationMediaFileType SAAMFT
			INNER JOIN ApplicationMediaFileType AMFT
				ON SAAMFT.applicationMediaFileTypeID = AMFT.applicationMediaFileTypeID
			WHERE 
				SAAMFT.steamApplicationID = SA.steamApplicationID
				AND AMFT.applicationMediaFileTypeDescription = 'movies'
		) AS 'Tráileres',
		(
			CASE
				WHEN SA.apprNumberOwners >= 1000000 THEN CONCAT(CAST(SA.apprNumberOwners * 1. / 1000000 AS DECIMAL (5, 1)), ' millones')
				ELSE CONCAT(CAST(SA.apprNumberOwners * 1. / 100000 AS DECIMAL (5, 2)), ' miles')
			END
		) AS 'Número aproximado de jugadores',
		CONCAT(CAST(SA.positiveRatings * 1. / (SA.positiveRatings + SA.negativeRatings) * 100 AS DECIMAL (4, 1)), '%') AS 'Valoración',
		CONCAT('$ ', SA.price) AS 'Precio en USD',
		SI.supportEmail AS 'Email de contacto de soporte'
	FROM SteamApplication SA
	INNER JOIN AgeClassification AC
		ON SA.ageClassificationID= AC.ageClassificationID
	LEFT JOIN SupportInfo SI
		ON SA.supportInfoID = SI.supportInfoID
	WHERE
		SA.applicationName LIKE CONCAT('%', @appName, '%')
END
GO

EXEC SP_AppInfo_By_Name 'stardew'
GO
