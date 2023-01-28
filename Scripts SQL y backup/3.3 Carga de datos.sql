USE SteamApplicationsDB
GO

/**********************Carga de datos a las tablas normalizadas**********************/

/*1. Tabla Genre*/
INSERT INTO Genre (genreDescription)
	SELECT
		VALUE AS 'Género'
	FROM dataFromCSV.steam S
		CROSS APPLY STRING_SPLIT(S.genres, ';')
	GROUP BY VALUE
	ORDER BY [Género] ASC
GO

/*2. Tabla Category*/
INSERT INTO Category (categoryDescription)
	SELECT
		VALUE AS 'Categoría'
	FROM dataFromCSV.steam S
		CROSS APPLY STRING_SPLIT(S.categories, ';')
	GROUP BY VALUE
	ORDER BY [Categoría] ASC
GO

/*3. Tabla SupportedPlatform*/
INSERT INTO SupportedPlatform (supportedPlatformDescription)
	SELECT
		VALUE AS 'Plataforma de soporte'
	FROM dataFromCSV.steam S
		CROSS APPLY STRING_SPLIT(S.platforms, ';')
	GROUP BY VALUE
	ORDER BY [Plataforma de soporte] ASC
GO

/*4. Tabla Publisher*/
INSERT INTO Publisher (publisherName)
	SELECT
		VALUE AS 'Compañía de videojuego'
	FROM dataFromCSV.steam S
		CROSS APPLY STRING_SPLIT(S.publisher, ';')
	GROUP BY VALUE
	ORDER BY [Compañía de videojuego] ASC
GO

/*5. Tabla Developer*/
INSERT INTO Developer (developerName)
	SELECT
		VALUE AS 'Compañía desarrolladora'
	FROM dataFromCSV.steam S
		CROSS APPLY STRING_SPLIT(S.developer, ';')
	GROUP BY VALUE
	ORDER BY [Compañía desarrolladora] ASC
GO

/*6. Tabla AgeClassification*/
INSERT INTO AgeClassification (classDescription, minimumAge)
	SELECT CONCAT(S.required_age, '+'), S.required_age AS 'Edad mínima'
	FROM dataFromCSV.steam S
	GROUP BY CONCAT(S.required_age, '+'), S.required_age
	ORDER BY [Edad mínima] ASC
GO

/*7. Tabla ApplicationMediaFileType*/
INSERT INTO ApplicationMediaFileType (applicationMediaFileTypeDescription)
	SELECT 
		ISC.COLUMN_NAME
	FROM INFORMATION_SCHEMA.COLUMNS ISC
	WHERE
		ISC.TABLE_SCHEMA = 'dataFromCSV'
		AND ISC.TABLE_NAME = 'steam_media_data'
		AND ISC.COLUMN_NAME NOT IN ('steam_appid')
GO

/*8. Tabla Tag*/
INSERT INTO Tag (tagDescription)
	SELECT 
		ISC.COLUMN_NAME
	FROM INFORMATION_SCHEMA.COLUMNS ISC
	WHERE
		ISC.TABLE_SCHEMA = 'dataFromCSV'
		AND ISC.TABLE_NAME = 'steamspy_tag_data'
		AND ISC.COLUMN_NAME NOT IN ('appid')
GO

/*9. Tabla SupportInfo*/
INSERT INTO SupportInfo (supportWebsite, supportURLContact, supportEmail)
	SELECT
		SSI.website, 
		SSI.support_url, 
		SSI.support_email
	FROM dataFromCSV.steam_support_info SSI
	GROUP BY SSI.website, SSI.support_url, SSI.support_email
GO

/*10. Tabla SteamApplication*/
DELETE FROM SteamApplication
GO

INSERT INTO SteamApplication 
	(	steamApplicationID, applicationName, releaseDate, numberArchievements,
		positiveRatings, negativeRatings, avgPlaytime, apprNumberOwners, price,
		ageClassificationID, supportInfoID
	)

	SELECT
		S.appid, 
		S.name, 
		S.release_date,
		S.achievements,
		S.positive_ratings,
		S.negative_ratings,
		CAST(S.average_playtime AS DECIMAL(9, 2)),
		(CAST(SUBSTRING(S.owners, 1, PATINDEX('%-%', S.owners) - 1) AS INT) +
		CAST(SUBSTRING(S.owners, PATINDEX('%-%', S.owners) + 1, LEN(S.owners) - PATINDEX('%-%', S.owners)) AS INT)) / 2,
		CAST(S.price AS DECIMAL(6, 2)) * 1.22, 
		AC.ageClassificationID,
		SI.supportInfoID
	FROM dataFromCSV.steam S
	INNER JOIN AgeClassification AC
		ON S.required_age = AC.minimumAge
	LEFT JOIN dataFromCSV.steam_support_info SSI
		ON SSI.steam_appid = S.appid 
	LEFT JOIN SupportInfo SI
		ON SSI.website = SI.supportWebsite
		AND SSI.support_url = SI.supportURLContact
		AND SSI.support_email = SI.supportEmail
GO

/*11. Tabla [dbo].[SteamApplication_Genre]*/
WITH CTE_genresByApp AS
(
	SELECT
		S.appid, 
		VALUE AS 'Género' 
	FROM dataFromCSV.steam S
	CROSS APPLY STRING_SPLIT(S.genres, ';')
)
INSERT INTO SteamApplication_Genre (steamApplicationID, genreID)
	SELECT
		GBA.appid, 
		G.genreID
	FROM Genre G
	INNER JOIN CTE_genresByApp GBA
		ON G.genreDescription = GBA.Género
GO

/*12. Tabla [dbo].[SteamApplication_Category]*/
WITH CTE_categoriesByApp AS
(
	SELECT
		S.appid, 
		VALUE AS 'Categoría' 
	FROM dataFromCSV.steam S
	CROSS APPLY STRING_SPLIT(S.categories, ';')
)
INSERT INTO SteamApplication_Category (steamApplicationID, categoryID)
	SELECT
		CBA.appid, 
		C.categoryID
	FROM Category C
	INNER JOIN CTE_categoriesByApp CBA
		ON C.categoryDescription = CBA.Categoría
GO

/*13. Tabla [dbo].[SteamApplication_SupportedPlatform]*/
WITH CTE_platformsByApp AS
(
	SELECT
		S.appid, 
		VALUE AS 'Plataforma' 
	FROM dataFromCSV.steam S
	CROSS APPLY STRING_SPLIT(S.platforms, ';')
)
INSERT INTO SteamApplication_SupportedPlatform (steamApplicationID, supportedPlatformID)
	SELECT
		cte_P.appid, 
		P.supportedPlatformID
	FROM SupportedPlatform P
	INNER JOIN CTE_platformsByApp cte_P
		ON P.supportedPlatformDescription = cte_P.Plataforma
GO

/*14. Tabla [dbo].[SteamApplication_Publisher]*/
WITH CTE_publishersByApp AS
(
	SELECT
		S.appid, 
		VALUE AS 'Compañía de videojuegos' 
	FROM dataFromCSV.steam S
	CROSS APPLY STRING_SPLIT(S.publisher, ';')
)
INSERT INTO SteamApplication_Publisher (steamApplicationID, publisherID)
	SELECT
		cte_P.appid, 
		P.publisherID
	FROM Publisher P
	INNER JOIN CTE_publishersByApp cte_P
		ON P.publisherName = cte_P.[Compañía de videojuegos]
GO

/*15. Tabla [dbo].[SteamApplication_Developer]*/
WITH CTE_developersByApp AS
(
	SELECT
		S.appid, 
		VALUE AS 'Desarrolladora de videojuegos' 
	FROM dataFromCSV.steam S
	CROSS APPLY STRING_SPLIT(S.developer, ';')
)
INSERT INTO SteamApplication_Developer (steamApplicationID, developerID)
	SELECT
		cte_D.appid, 
		D.developerID
	FROM Developer D
	INNER JOIN CTE_developersByApp cte_D
		ON D.developerName = cte_D.[Desarrolladora de videojuegos]
GO

/*16. Tabla Requirement*/
/*INSERT INTO Requirement (onWindows, onMac, onLinux, recommendedRequirement, steamApplicationID)
	SELECT
		SRD.pc_requirements,
		SRD.mac_requirements,
		SRD.linux_requirements,
		SRD.recommended,
		SRD.steam_appid
	FROM SteamApplication SA
	INNER JOIN dataFromCSV.steam_requirements_data SRD
		ON SA.steamApplicationID = SRD.steam_appid
GO*/

/*17. Tabla [dbo].[SteamApplication_Tag]*/

-- Se procede a crear una tabla temporal
DROP TABLE IF EXISTS #temp_tagsByApp
GO

CREATE TABLE #temp_tagsByApp
(
	appId VARCHAR(16),
	tagDescription VARCHAR(64)
)
GO

/*Almacenamos en la tabla temporal los ID's de las apps junto a sus respectivas etiquetas,
	cuya valoración supere a 0, para mantener la precisión de las etiquetas que verdaramente
	le corresponden. Se ha tenido que analizar cada una de las 371 columnas que conforman la
	tabla dataFromCSV.steamspy_tag_data. Teniendo en cuenta un patrón en donde solo varía el nombre
	de la columna en el query para el INSERT,se hizo uso de Excel para replicar la consulta 
	y reemplazar el nombre de la columna a mapear.*/

INSERT INTO #temp_tagsByApp SELECT TD.appid, '1980s' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[1980s] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, '1990s' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[1990s] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, '2 5d' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[2 5d] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, '2d' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[2d] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, '2d_fighter' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[2d_fighter] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, '360_video' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[360_video] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, '3d' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[3d] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, '3d_platformer' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[3d_platformer] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, '3d_vision' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[3d_vision] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, '4_player_local' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[4_player_local] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, '4x' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[4x] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, '6dof' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[6dof] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'atv' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[atv] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'abstract' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[abstract] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'action' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[action] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'action_rpg' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[action_rpg] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'action_adventure' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[action_adventure] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'addictive' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[addictive] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'adventure' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[adventure] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'agriculture' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[agriculture] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'aliens' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[aliens] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'alternate_history' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[alternate_history] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'america' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[america] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'animation_&_modeling' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[animation_&_modeling] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'anime' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[anime] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'arcade' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[arcade] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'arena_shooter' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[arena_shooter] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'artificial_intelligence' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[artificial_intelligence] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'assassin' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[assassin] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'asynchronous_multiplayer' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[asynchronous_multiplayer] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'atmospheric' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[atmospheric] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'audio_production' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[audio_production] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'bmx' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[bmx] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'base_building' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[base_building] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'baseball' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[baseball] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'based_on_a_novel' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[based_on_a_novel] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'basketball' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[basketball] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'batman' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[batman] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'battle_royale' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[battle_royale] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'beat_em_up' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[beat_em_up] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'beautiful' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[beautiful] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'benchmark' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[benchmark] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'bikes' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[bikes] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'blood' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[blood] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'board_game' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[board_game] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'bowling' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[bowling] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'building' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[building] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'bullet_hell' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[bullet_hell] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'bullet_time' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[bullet_time] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'crpg' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[crpg] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'capitalism' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[capitalism] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'card_game' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[card_game] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'cartoon' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[cartoon] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'cartoony' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[cartoony] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'casual' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[casual] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'cats' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[cats] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'character_action_game' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[character_action_game] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'character_customization' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[character_customization] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'chess' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[chess] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'choices_matter' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[choices_matter] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'choose_your_own_adventure' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[choose_your_own_adventure] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'cinematic' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[cinematic] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'city_builder' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[city_builder] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'class_based' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[class_based] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'classic' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[classic] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'clicker' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[clicker] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'co_op' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[co_op] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'co_op_campaign' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[co_op_campaign] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'cold_war' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[cold_war] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'colorful' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[colorful] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'comedy' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[comedy] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'comic_book' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[comic_book] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'competitive' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[competitive] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'conspiracy' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[conspiracy] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'controller' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[controller] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'conversation' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[conversation] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'crafting' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[crafting] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'crime' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[crime] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'crowdfunded' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[crowdfunded] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'cult_classic' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[cult_classic] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'cute' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[cute] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'cyberpunk' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[cyberpunk] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'cycling' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[cycling] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'dark' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[dark] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'dark_comedy' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[dark_comedy] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'dark_fantasy' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[dark_fantasy] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'dark_humor' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[dark_humor] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'dating_sim' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[dating_sim] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'demons' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[demons] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'design_&_illustration' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[design_&_illustration] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'destruction' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[destruction] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'detective' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[detective] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'difficult' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[difficult] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'dinosaurs' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[dinosaurs] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'diplomacy' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[diplomacy] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'documentary' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[documentary] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'dog' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[dog] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'dragons' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[dragons] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'drama' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[drama] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'driving' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[driving] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'dungeon_crawler' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[dungeon_crawler] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'dungeons_&_dragons' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[dungeons_&_dragons] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'dynamic_narration' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[dynamic_narration] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'dystopian_' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[dystopian_] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'early_access' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[early_access] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'economy' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[economy] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'education' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[education] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'emotional' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[emotional] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'epic' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[epic] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'episodic' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[episodic] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'experience' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[experience] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'experimental' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[experimental] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'exploration' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[exploration] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'fmv' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[fmv] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'fps' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[fps] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'faith' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[faith] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'family_friendly' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[family_friendly] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'fantasy' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[fantasy] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'fast_paced' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[fast_paced] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'feature_film' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[feature_film] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'female_protagonist' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[female_protagonist] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'fighting' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[fighting] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'first_person' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[first_person] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'fishing' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[fishing] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'flight' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[flight] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'football' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[football] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'foreign' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[foreign] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'free_to_play' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[free_to_play] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'funny' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[funny] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'futuristic' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[futuristic] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'gambling' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[gambling] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'game_development' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[game_development] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'gamemaker' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[gamemaker] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'games_workshop' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[games_workshop] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'gaming' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[gaming] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'god_game' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[god_game] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'golf' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[golf] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'gore' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[gore] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'gothic' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[gothic] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'grand_strategy' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[grand_strategy] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'great_soundtrack' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[great_soundtrack] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'grid_based_movement' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[grid_based_movement] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'gun_customization' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[gun_customization] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'hack_and_slash' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[hack_and_slash] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'hacking' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[hacking] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'hand_drawn' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[hand_drawn] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'hardware' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[hardware] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'heist' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[heist] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'hex_grid' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[hex_grid] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'hidden_object' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[hidden_object] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'historical' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[historical] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'hockey' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[hockey] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'horror' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[horror] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'horses' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[horses] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'hunting' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[hunting] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'illuminati' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[illuminati] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'indie' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[indie] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'intentionally_awkward_controls' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[intentionally_awkward_controls] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'interactive_fiction' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[interactive_fiction] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'inventory_management' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[inventory_management] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'investigation' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[investigation] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'isometric' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[isometric] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'jrpg' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[jrpg] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'jet' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[jet] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'kickstarter' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[kickstarter] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'lego' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[lego] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'lara_croft' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[lara_croft] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'lemmings' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[lemmings] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'level_editor' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[level_editor] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'linear' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[linear] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'local_co_op' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[local_co_op] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'local_multiplayer' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[local_multiplayer] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'logic' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[logic] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'loot' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[loot] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'lore_rich' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[lore_rich] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'lovecraftian' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[lovecraftian] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'mmorpg' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[mmorpg] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'moba' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[moba] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'magic' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[magic] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'management' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[management] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'mars' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[mars] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'martial_arts' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[martial_arts] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'massively_multiplayer' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[massively_multiplayer] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'masterpiece' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[masterpiece] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'match_3' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[match_3] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'mature' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[mature] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'mechs' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[mechs] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'medieval' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[medieval] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'memes' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[memes] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'metroidvania' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[metroidvania] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'military' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[military] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'mini_golf' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[mini_golf] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'minigames' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[minigames] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'minimalist' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[minimalist] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'mining' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[mining] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'mod' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[mod] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'moddable' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[moddable] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'modern' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[modern] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'motocross' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[motocross] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'motorbike' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[motorbike] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'mouse_only' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[mouse_only] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'movie' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[movie] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'multiplayer' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[multiplayer] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'multiple_endings' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[multiple_endings] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'music' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[music] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'music_based_procedural_generation' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[music_based_procedural_generation] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'mystery' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[mystery] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'mystery_dungeon' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[mystery_dungeon] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'mythology' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[mythology] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'nsfw' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[nsfw] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'narration' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[narration] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'naval' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[naval] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'ninja' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[ninja] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'noir' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[noir] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'nonlinear' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[nonlinear] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'nudity' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[nudity] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'offroad' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[offroad] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'old_school' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[old_school] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'on_rails_shooter' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[on_rails_shooter] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'online_co_op' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[online_co_op] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'open_world' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[open_world] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'otome' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[otome] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'parkour' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[parkour] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'parody_' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[parody_] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'party_based_rpg' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[party_based_rpg] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'perma_death' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[perma_death] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'philisophical' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[philisophical] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'photo_editing' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[photo_editing] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'physics' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[physics] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'pinball' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[pinball] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'pirates' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[pirates] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'pixel_graphics' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[pixel_graphics] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'platformer' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[platformer] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'point_&_click' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[point_&_click] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'political' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[political] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'politics' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[politics] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'pool' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[pool] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'post_apocalyptic' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[post_apocalyptic] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'procedural_generation' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[procedural_generation] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'programming' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[programming] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'psychedelic' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[psychedelic] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'psychological' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[psychological] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'psychological_horror' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[psychological_horror] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'puzzle' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[puzzle] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'puzzle_platformer' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[puzzle_platformer] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'pve' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[pve] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'pvp' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[pvp] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'quick_time_events' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[quick_time_events] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'rpg' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[rpg] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'rpgmaker' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[rpgmaker] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'rts' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[rts] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'racing' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[racing] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'real_time_tactics' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[real_time_tactics] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'real_time' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[real_time] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'real_time_with_pause' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[real_time_with_pause] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'realistic' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[realistic] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'relaxing' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[relaxing] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'remake' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[remake] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'replay_value' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[replay_value] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'resource_management' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[resource_management] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'retro' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[retro] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'rhythm' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[rhythm] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'robots' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[robots] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'rogue_like' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[rogue_like] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'rogue_lite' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[rogue_lite] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'romance' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[romance] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'rome' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[rome] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'runner' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[runner] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'sailing' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[sailing] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'sandbox' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[sandbox] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'satire' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[satire] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'sci_fi' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[sci_fi] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'science' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[science] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'score_attack' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[score_attack] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'sequel' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[sequel] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'sexual_content' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[sexual_content] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'shoot_em_up' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[shoot_em_up] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'shooter' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[shooter] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'short' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[short] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'side_scroller' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[side_scroller] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'silent_protagonist' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[silent_protagonist] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'simulation' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[simulation] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'singleplayer' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[singleplayer] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'skateboarding' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[skateboarding] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'skating' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[skating] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'skiing' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[skiing] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'sniper' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[sniper] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'snow' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[snow] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'snowboarding' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[snowboarding] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'soccer' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[soccer] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'software' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[software] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'software_training' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[software_training] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'sokoban' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[sokoban] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'souls_like' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[souls_like] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'soundtrack' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[soundtrack] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'space' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[space] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'space_sim' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[space_sim] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'spectacle_fighter' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[spectacle_fighter] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'spelling' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[spelling] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'split_screen' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[split_screen] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'sports' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[sports] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'star_wars' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[star_wars] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'stealth' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[stealth] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'steam_machine' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[steam_machine] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'steampunk' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[steampunk] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'story_rich' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[story_rich] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'strategy' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[strategy] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'strategy_rpg' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[strategy_rpg] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'stylized' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[stylized] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'submarine' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[submarine] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'superhero' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[superhero] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'supernatural' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[supernatural] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'surreal' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[surreal] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'survival' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[survival] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'survival_horror' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[survival_horror] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'swordplay' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[swordplay] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'tactical' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[tactical] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'tactical_rpg' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[tactical_rpg] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'tanks' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[tanks] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'team_based' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[team_based] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'tennis' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[tennis] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'text_based' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[text_based] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'third_person' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[third_person] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'third_person_shooter' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[third_person_shooter] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'thriller' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[thriller] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'time_attack' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[time_attack] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'time_management' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[time_management] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'time_manipulation' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[time_manipulation] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'time_travel' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[time_travel] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'top_down' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[top_down] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'top_down_shooter' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[top_down_shooter] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'touch_friendly' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[touch_friendly] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'tower_defense' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[tower_defense] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'trackir' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[trackir] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'trading' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[trading] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'trading_card_game' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[trading_card_game] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'trains' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[trains] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'transhumanism' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[transhumanism] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'turn_based' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[turn_based] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'turn_based_combat' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[turn_based_combat] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'turn_based_strategy' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[turn_based_strategy] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'turn_based_tactics' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[turn_based_tactics] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'tutorial' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[tutorial] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'twin_stick_shooter' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[twin_stick_shooter] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'typing' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[typing] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'underground' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[underground] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'underwater' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[underwater] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'unforgiving' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[unforgiving] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'utilities' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[utilities] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'vr' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[vr] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'vr_only' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[vr_only] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'vampire' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[vampire] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'video_production' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[video_production] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'villain_protagonist' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[villain_protagonist] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'violent' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[violent] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'visual_novel' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[visual_novel] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'voice_control' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[voice_control] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'voxel' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[voxel] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'walking_simulator' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[walking_simulator] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'war' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[war] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'wargame' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[wargame] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'warhammer_40k' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[warhammer_40k] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'web_publishing' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[web_publishing] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'werewolves' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[werewolves] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'western' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[western] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'word_game' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[word_game] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'world_war_i' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[world_war_i] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'world_war_ii' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[world_war_ii] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'wrestling' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[wrestling] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'zombies' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[zombies] > 0
INSERT INTO #temp_tagsByApp SELECT TD.appid, 'e_sports' FROM dataFromCSV.steamspy_tag_data TD WHERE TD.[e_sports] > 0

-- Finalmente cargamos los datos en SteamApplication_Tag
INSERT INTO SteamApplication_Tag (steamApplicationID, tagID)
	SELECT
		SA.steamApplicationID, T.tagID
	FROM Tag T
	INNER JOIN #temp_tagsByApp TBA 
		ON T.tagDescription = TBA.tagDescription
	INNER JOIN SteamApplication SA
		ON TBA.appId = SA.steamApplicationID
GO

/*18. Tabla [dbo].[SteamApplication_ApplicationMediaFileType]*/

/* Se procede a crear una tabla temporal para el mapeo de tipo de archivo multimedia y el
 ID de la aplicación*/
DROP TABLE IF EXISTS #temp_mediaFileTypesByApp

CREATE TABLE #temp_mediaFileTypesByApp
(
	appId VARCHAR(16),
	applicationMediaFileTypeDescription VARCHAR(64),
	urls nvarchar(max)
)
GO

/*Se realiza el mapeo por columna para todas las aplicaciones que tengan información sobre los archivos
	multimedia aplicación de Steam y lo almacenamos en la tabla temporal #temp_mediaFileTypesByApp*/
INSERT INTO #temp_mediaFileTypesByApp SELECT SMD.steam_appid, 'header_image', SMD.header_image FROM dataFromCSV.steam_media_data SMD WHERE SMD.[header_image] NOT LIKE ''
INSERT INTO #temp_mediaFileTypesByApp SELECT SMD.steam_appid, 'screenshots', SMD.screenshots FROM dataFromCSV.steam_media_data SMD WHERE SMD.[screenshots] NOT LIKE ''
INSERT INTO #temp_mediaFileTypesByApp SELECT SMD.steam_appid, 'background', SMD.background FROM dataFromCSV.steam_media_data SMD WHERE SMD.[background] NOT LIKE ''
INSERT INTO #temp_mediaFileTypesByApp SELECT SMD.steam_appid, 'movies', SMD.movies FROM dataFromCSV.steam_media_data SMD WHERE SMD.[movies] NOT LIKE ''

/*1º reaujuste. Actualizamos el caracter ' y lo reeemplazamos con ", para que pueda ser leído como formato JSON*/
SELECT * FROM #temp_mediaFileTypesByApp
GO
UPDATE #temp_mediaFileTypesByApp SET urls = REPLACE(urls, CHAR(39), '"')
GO
/*2º reaujuste.*/
UPDATE #temp_mediaFileTypesByApp SET urls = REPLACE(urls,'"highlight": True', '"highlight": 1')
WHERE
	urls NOT LIKE 'https%'
	AND applicationMediaFileTypeDescription = 'movies'
GO

UPDATE #temp_mediaFileTypesByApp SET urls = REPLACE(urls,'"highlight": False', '"highlight": 0')
WHERE
	urls NOT LIKE 'https%'
	AND applicationMediaFileTypeDescription = 'movies'
GO

/*3º reaujuste. Modificar atributo JSON webm.480 a webm._480 de movies*/
UPDATE #temp_mediaFileTypesByApp SET urls = REPLACE(urls,'"480"', '"_480"')
WHERE
	urls NOT LIKE 'https%'
	AND applicationMediaFileTypeDescription = 'movies'
GO

/*REGISTROS PENDIENTES POR MAPEAR. Anomalía de las comillas dobles que impide ser
	interpretado como formato JSON por SQL SERVER*/
SELECT
	MFT.appId,
	MFT.applicationMediaFileTypeDescription,
	MFT.urls,
	(
		CASE
			WHEN ISJSON(MFT.urls) = 1 THEN 'SÍ'
			ELSE 'NO'
		END
	) AS 'Es JSON'
FROM #temp_mediaFileTypesByApp MFT
WHERE
	MFT.urls NOT LIKE 'https%'AND MFT.applicationMediaFileTypeDescription = 'movies'
	AND ISJSON(MFT.urls) = 0
ORDER BY [Es JSON] ASC
GO

/*Creamos un CTE*/
/*Se codifica la consulta para extender otra columna en donde detalle cada URL de screenshots
	de cada appID y de cada tipo de archivo multimedia. screenshots - Thumb_nails*/
WITH CTE_allUrlMediaById_and_mediaFileType AS
(
	SELECT
		MFT.appId,
		MFT.applicationMediaFileTypeDescription,
		UrlsJsonData.path_thumbnail as 'URL'
	FROM #temp_mediaFileTypesByApp MFT
	CROSS APPLY OPENJSON(MFT.urls)
	WITH (
		ID VARCHAR(200) N'$.id',
		path_thumbnail VARCHAR(1024) N'$.path_thumbnail',
		path_full VARCHAR(1024) N'$.path_full'
	  ) AS UrlsJsonData
	WHERE
		MFT.urls NOT LIKE 'https%'
		AND MFT.applicationMediaFileTypeDescription = 'screenshots'

	UNION

	/*Se codifica la consulta para extender otra columna en donde detalle cada URL de screenshots
		de cada appID y de cada tipo de archivo multimedia. screenshots - path_full*/
	SELECT
		MFT.appId,
		MFT.applicationMediaFileTypeDescription,
		UrlsJsonData.path_full
	FROM #temp_mediaFileTypesByApp MFT
	CROSS APPLY OPENJSON(MFT.urls)
	WITH (
		ID VARCHAR(200) N'$.id',
		path_thumbnail VARCHAR(1024) N'$.path_thumbnail',
		path_full VARCHAR(1024) N'$.path_full'
	  ) AS UrlsJsonData
	WHERE
		MFT.urls NOT LIKE 'https%'
		AND MFT.applicationMediaFileTypeDescription = 'screenshots'

	UNION

	/*movies - thumbnail*/
	SELECT
		MFT.appId,
		MFT.applicationMediaFileTypeDescription,
		UrlsJsonData.thumbnail
	FROM #temp_mediaFileTypesByApp MFT
	CROSS APPLY OPENJSON(MFT.urls)
	WITH (
		thumbnail VARCHAR(1024) N'$.thumbnail'
	  ) AS UrlsJsonData
	WHERE
		MFT.urls NOT LIKE 'https%'
		AND MFT.applicationMediaFileTypeDescription = 'movies'
		AND ISJSON(MFT.urls) = 1

	UNION

	/*movies - webm - 480*/
	SELECT
		MFT.appId,
		MFT.applicationMediaFileTypeDescription,
		UrlsJsonData.webm_480
	FROM #temp_mediaFileTypesByApp MFT
	CROSS APPLY OPENJSON(MFT.urls)
	WITH (
		webm_480 VARCHAR(1024) N'$.webm._480'
	  ) AS UrlsJsonData
	WHERE
		MFT.urls NOT LIKE 'https%'
		AND MFT.applicationMediaFileTypeDescription = 'movies'
		AND ISJSON(MFT.urls) = 1

	UNION

	/*movies - webm - max*/
	SELECT
		MFT.appId,
		MFT.applicationMediaFileTypeDescription,
		UrlsJsonData.webm_max
	FROM #temp_mediaFileTypesByApp MFT
	CROSS APPLY OPENJSON(MFT.urls)
	WITH (
		webm_max VARCHAR(1024) N'$.webm.max'
	  ) AS UrlsJsonData
	WHERE
		MFT.urls NOT LIKE 'https%'
		AND MFT.applicationMediaFileTypeDescription = 'movies'
		AND ISJSON(MFT.urls) = 1

	UNION

	/*Finalmente, unimos aquellas filas en donde solo tienen direcciones url, mas no 
		jsons*/
	SELECT
		MFT.appId,
		MFT.applicationMediaFileTypeDescription,
		MFT.urls
	FROM #temp_mediaFileTypesByApp MFT
	WHERE
		MFT.urls LIKE 'https%'
)
INSERT INTO SteamApplication_ApplicationMediaFileType (steamApplicationID, applicationMediaFileTypeID, urlMediaFile)
	SELECT
		SA.steamApplicationID,
		MFT.applicationMediaFileTypeID,
		CTE.URL
	FROM SteamApplication SA
	INNER JOIN CTE_allUrlMediaById_and_mediaFileType CTE
		ON SA.steamApplicationID =  CTE.appId
	INNER JOIN ApplicationMediaFileType MFT
		ON MFT.applicationMediaFileTypeDescription = CTE.applicationMediaFileTypeDescription
GO
