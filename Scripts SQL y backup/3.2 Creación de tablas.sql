USE master
GO

DROP DATABASE IF EXISTS SteamApplicationsDB
GO

CREATE DATABASE SteamApplicationsDB
GO

USE SteamApplicationsDB
GO

/*Schemas*/
DROP SCHEMA IF EXISTS dataFromCSV
GO

CREATE SCHEMA dataFromCSV
GO

/*----------Creación de tablas----------*/

/* 1. Tabla AgeClassification: Tabla que va a almacenar el tipo de público recomendado	
	según la edad*/
DROP TABLE IF EXISTS AgeClassification
GO

CREATE TABLE AgeClassification
(
	ageClassificationID INT IDENTITY(1, 1),
	classDescription VARCHAR(16) NOT NULL,
	minimumAge TINYINT NOT NULL
)
GO

ALTER TABLE AgeClassification
	ADD CONSTRAINT pk_AgeClassification PRIMARY KEY (ageClassificationID)
GO

/* 2. Tabla en donde acoge todos los géneros que conforman una aplicación de Steam. Es asignado
	por la empresa desarrolladora de la aplicación*/
DROP TABLE IF EXISTS Genre
GO

CREATE TABLE Genre
(
	genreID INT IDENTITY(1, 1),
	genreDescription VARCHAR(128) NOT NULL
)
GO

ALTER TABLE Genre
	ADD CONSTRAINT pk_Genre PRIMARY KEY (genreID) 
GO

/* 3. Tabla en donde acoge todos los géneros que conforman una aplicación de Steam, con la diferencia
	de que son asignados por los usuarios de Steam*/
/*DROP TABLE IF EXISTS GenreByVoting
GO

CREATE TABLE GenreByVoting
(
	genreByVotingID INT IDENTITY(1, 1),
	genreDescription VARCHAR(128) NOT NULL
)
GO

ALTER TABLE GenreByVoting
	ADD CONSTRAINT pk_GenreByVoting PRIMARY KEY (genreByVotingID) 
GO*/

/*4. Category: Tabla que contiene las categorías de las aplicaciones de Steam*/
DROP TABLE IF EXISTS Category
GO

CREATE TABLE Category
(
	categoryID INT IDENTITY(1, 1),
	categoryDescription VARCHAR(64) NOT NULL
)
GO

ALTER TABLE Category
	ADD CONSTRAINT pk_categoryID PRIMARY KEY (categoryID) 
GO

/*5. Platform: Tabla que contiene a todas las plataformas disponibles para una aplicación*/
DROP TABLE IF EXISTS SupportedPlatform
GO

CREATE TABLE SupportedPlatform
(
	supportedPlatformID INT IDENTITY(1, 1),
	supportedPlatformDescription VARCHAR(32) NOT NULL
)
GO

ALTER TABLE SupportedPlatform
	ADD CONSTRAINT pk_SupportedPlatform PRIMARY KEY (supportedPlatformID) 
GO

/*6. SupportInfo: Tabla que contiene la información de soporte del juego. */
DROP TABLE IF EXISTS SupportInfo
GO

CREATE TABLE SupportInfo
(
	supportInfoID INT IDENTITY(1, 1),
	supportWebsite VARCHAR(512),
	supportURLContact VARCHAR(512),
	supportEmail VARCHAR(512),
)
GO

ALTER TABLE SupportInfo
	ADD CONSTRAINT pk_SupportInfo PRIMARY KEY (supportInfoID) 
GO

/*7. Tag: Tabla que aloja todas las etiquetas que fueron asignadas por las usuarios. Las etiquetas
	describen, de algún modo, las principales características dentro del juego.*/
DROP TABLE IF EXISTS Tag
GO

CREATE TABLE Tag
(
	tagID INT IDENTITY(1, 1),
	tagDescription VARCHAR(64) NOT NULL
)
GO

ALTER TABLE Tag
	ADD CONSTRAINT pk_Tag PRIMARY KEY (tagID) 
GO

/*8. Publisher: Tabla que aloja todas principales compañías que se encargan de la creación
	y diseño del juego.*/
DROP TABLE IF EXISTS Publisher
GO

CREATE TABLE Publisher
(
	publisherID INT IDENTITY(1, 1),
	publisherName VARCHAR(512) NOT NULL
)
GO

ALTER TABLE Publisher
	ADD CONSTRAINT pk_Publisher PRIMARY KEY (publisherID) 
GO

/*9. Developer: Tabla que almacena a las desarrolladoras de los juegos.*/
DROP TABLE IF EXISTS Developer
GO

CREATE TABLE Developer
(
	developerID INT IDENTITY(1, 1),
	developerName VARCHAR(512) NOT NULL
)
GO

ALTER TABLE Developer
	ADD CONSTRAINT pk_Developer PRIMARY KEY (developerID) 
GO

/*10. ApplicationMediaFileType: Tabla que contiene los tipos de archivos multimedia que puede tener
	un juego de Steam.*/
DROP TABLE IF EXISTS ApplicationMediaFileType
GO

CREATE TABLE ApplicationMediaFileType
(
	applicationMediaFileTypeID INT IDENTITY(1, 1),
	applicationMediaFileTypeDescription VARCHAR(512) NOT NULL
)
GO

ALTER TABLE ApplicationMediaFileType
	ADD CONSTRAINT pk_ApplicationMediaFileType PRIMARY KEY (applicationMediaFileTypeID) 
GO

/*11. SteamApplication: Tabla que contiene la información general y detallada de cada aplicación 
	existente en la plataforma Steam.*/
DROP TABLE IF EXISTS SteamApplication
GO

CREATE TABLE SteamApplication
(
	steamApplicationID VARCHAR(16) NOT NULL,
	applicationName VARCHAR(1024) NOT NULL,
	/*aboutTheGame NVARCHAR,
	shortDescription NVARCHAR,
	extendedDescription NVARCHAR,*/
	releaseDate DATE,
	numberArchievements SMALLINT NOT NULL,
	positiveRatings INT	NOT NULL,
	negativeRatings INT	NOT NULL,
	avgPlaytime DECIMAL (9, 2) NOT NULL,
	apprNumberOwners INT NOT NULL,
	price DECIMAL (6, 2) NOT NULL,
	ageClassificationID INT NOT NULL,
	supportInfoID INT -- NOT NULL
)
GO

ALTER TABLE SteamApplication
	ADD CONSTRAINT pk_SteamApplication PRIMARY KEY (steamApplicationID),
		CONSTRAINT fk_SteamApplication_AgeClassification FOREIGN KEY (ageClassificationID) REFERENCES AgeClassification (ageClassificationID) ON DELETE CASCADE,
		CONSTRAINT fk_SteamApplication_SupportInfo FOREIGN KEY (supportInfoID) REFERENCES SupportInfo (supportInfoID) ON DELETE CASCADE
GO

/*12. Requirement: Tabla que especifica qué requisitos debe tener cada tipo PC en donde se ejecutará
	el juego.*/
DROP TABLE IF EXISTS Requirement
GO

CREATE TABLE Requirement
(
	requirementID INT IDENTITY(1, 1),
	onWindows NVARCHAR,
	onMac NVARCHAR,
	onLinux NVARCHAR,
	recommendedRequirement NVARCHAR,
	steamApplicationID VARCHAR(16) NOT NULL
)
GO

ALTER TABLE Requirement
	ADD CONSTRAINT pk_Requirement PRIMARY KEY (requirementID),
		CONSTRAINT fk_Requirement_SteamApplication FOREIGN KEY (steamApplicationID) REFERENCES SteamApplication (steamApplicationID) ON DELETE CASCADE
GO

/*13. SteamApplication_Category: Tabla que especifica a qué categorías pertenece cada juego.*/
DROP TABLE IF EXISTS SteamApplication_Category
GO

CREATE TABLE SteamApplication_Category
(
	ID INT IDENTITY(1, 1),
	steamApplicationID VARCHAR(16) NOT NULL,
	categoryID INT NOT NULL
)
GO

ALTER TABLE SteamApplication_Category
	ADD CONSTRAINT pk_SteamApplication_Category PRIMARY KEY (ID),
		CONSTRAINT fk_SAC_SteamApplication FOREIGN KEY (steamApplicationID) REFERENCES SteamApplication (steamApplicationID) ON DELETE CASCADE,
		CONSTRAINT fk_SAC_Category FOREIGN KEY (categoryID) REFERENCES Category (categoryID) ON DELETE CASCADE
GO

/*14. SteamApplication_GenreByVoting: Tabla que va a almacenar los géneros elegidos por los usuarios, por
	cada aplicación. Esto debido que existe una relación de muchos a muchos entre SteamApplication y 
	GenreByVoting.*/
/*DROP TABLE IF EXISTS SteamApplication_GenreByVoting
GO

CREATE TABLE SteamApplication_GenreByVoting
(
	ID INT IDENTITY(1, 1),
	steamApplicationID VARCHAR(16),
	genreByVotingID INT NOT NULL
)
GO

ALTER TABLE SteamApplication_GenreByVoting
	ADD CONSTRAINT pk_SteamApplication_GenreByVoting PRIMARY KEY (ID),
		CONSTRAINT fk_SAGBV_SteamApplication FOREIGN KEY (steamApplicationID) REFERENCES SteamApplication (steamApplicationID) ON DELETE CASCADE,
		CONSTRAINT fk_SAGBV_GenreByVoting FOREIGN KEY (genreByVotingID) REFERENCES GenreByVoting (genreByVotingID) ON DELETE CASCADE
GO*/

/*15. SteamApplication_Genre: Tabla que va a almacenar los géneros establecidos por las desarrolladores, por
	cada aplicación. Esto debido que existe una relación de muchos a muchos entre SteamApplication y 
	Genre.*/
DROP TABLE IF EXISTS SteamApplication_Genre
GO

CREATE TABLE SteamApplication_Genre
(
	ID INT IDENTITY(1, 1),
	steamApplicationID VARCHAR(16) NOT NULL,
	genreID INT NOT NULL
)
GO

ALTER TABLE SteamApplication_Genre
	ADD CONSTRAINT pk_SteamApplication_Genre PRIMARY KEY (ID),
		CONSTRAINT fk_SAG_SteamApplication FOREIGN KEY (steamApplicationID) REFERENCES SteamApplication (steamApplicationID) ON DELETE CASCADE,
		CONSTRAINT fk_SAG_Genre FOREIGN KEY (genreID) REFERENCES Genre (genreID) ON DELETE CASCADE
GO

/*16. SteamApplication_Tag: Tabla que va a almacenar las etiquetas de cada juego que existe en Steam, 
	esto se debe a que existe una relación de muchos a muchos entre SteamApplication y Tag.*/
DROP TABLE IF EXISTS SteamApplication_Tag
GO

CREATE TABLE SteamApplication_Tag
(
	ID INT IDENTITY(1, 1),
	steamApplicationID VARCHAR(16) NOT NULL,
	tagID INT NOT NULL
)
GO

ALTER TABLE SteamApplication_Tag
	ADD CONSTRAINT pk_SteamApplication_Tag PRIMARY KEY (ID),
		CONSTRAINT fk_SAT_SteamApplication FOREIGN KEY (steamApplicationID) REFERENCES SteamApplication (steamApplicationID) ON DELETE CASCADE,
		CONSTRAINT fk_SAT_Tag FOREIGN KEY (tagID) REFERENCES Tag (tagID) ON DELETE CASCADE
GO

/*17. SteamApplication_Publisher: Tabla que va a almacenar las compañías a la que pertenece cada juego que existe en Steam, 
	esto se debe a que existe una relación de muchos a muchos entre SteamApplication y Publisher, siguiendo la logica
	de que en juego puede ser creado y diseñado por varias compañías de videojuegos.*/
DROP TABLE IF EXISTS SteamApplication_Publisher
GO

CREATE TABLE SteamApplication_Publisher
(
	ID INT IDENTITY(1, 1),
	steamApplicationID VARCHAR(16) NOT NULL,
	publisherID INT NOT NULL
)
GO

ALTER TABLE SteamApplication_Publisher
	ADD CONSTRAINT pk_SteamApplication_Publisher PRIMARY KEY (ID),
		CONSTRAINT fk_SAP_SteamApplication FOREIGN KEY (steamApplicationID) REFERENCES SteamApplication (steamApplicationID) ON DELETE CASCADE,
		CONSTRAINT fk_SAP_Publisher FOREIGN KEY (publisherID) REFERENCES Publisher (publisherID) ON DELETE CASCADE
GO

/*18. SteamApplication_Developer: Tabla que va a almacenar las empresas desarrolladoras a la que pertenece cada juego que existe en Steam, 
	esto se debe a que existe una relación de muchos a muchos entre SteamApplication y Developer, siguiendo la logica
	de que en juego puede ser codificado y testeado por varias empresas desarrolladoras.*/
DROP TABLE IF EXISTS SteamApplication_Developer
GO

CREATE TABLE SteamApplication_Developer
(
	ID INT IDENTITY(1, 1),
	steamApplicationID VARCHAR(16) NOT NULL,
	developerID INT NOT NULL
)
GO

ALTER TABLE SteamApplication_Developer
	ADD CONSTRAINT pk_SteamApplication_Developer PRIMARY KEY (ID),
		CONSTRAINT fk_SAD_SteamApplication FOREIGN KEY (steamApplicationID) REFERENCES SteamApplication (steamApplicationID) ON DELETE CASCADE,
		CONSTRAINT fk_SAD_Developer FOREIGN KEY (developerID) REFERENCES Developer (developerID) ON DELETE CASCADE
GO

/*19. SteamApplication_SupportedPlatform: Tabla que va a almacenar a todas las plataformas que puede llegar a ejecutarse
	un juego de Steam. Esto debido a que hay una relación de muchos a muchos entre SteamApplication y SupportedPlatform.*/
DROP TABLE IF EXISTS SteamApplication_SupportedPlatform
GO

CREATE TABLE SteamApplication_SupportedPlatform
(
	ID INT IDENTITY(1, 1),
	steamApplicationID VARCHAR(16),
	supportedPlatformID INT NOT NULL
)
GO

ALTER TABLE SteamApplication_SupportedPlatform
	ADD CONSTRAINT pk_SteamApplication_SupportedPlatform PRIMARY KEY (ID),
		CONSTRAINT fk_SASP_SteamApplication FOREIGN KEY (steamApplicationID) REFERENCES SteamApplication (steamApplicationID) ON DELETE CASCADE,
		CONSTRAINT fk_SASP_SupportedPlatform FOREIGN KEY (supportedPlatformID) REFERENCES SupportedPlatform (supportedPlatformID) ON DELETE CASCADE
GO

/*20. SteamApplication_ApplicationMediaFileType: Tabla que va a almacenar los accesos (URL's) de cada tipo de archivo multimedia
	y de cada aplicación de Steam, como la portada principal, principales screenshots y los tráileres.*/
DROP TABLE IF EXISTS SteamApplication_ApplicationMediaFileType
GO

CREATE TABLE SteamApplication_ApplicationMediaFileType
(
	ID INT IDENTITY(1, 1),
	steamApplicationID VARCHAR(16) NOT NULL,
	applicationMediaFileTypeID INT NOT NULL,
	urlMediaFile NVARCHAR(MAX) NOT NULL
)
GO

ALTER TABLE SteamApplication_ApplicationMediaFileType
	ADD CONSTRAINT pk_SteamApplication_ApplicationMediaFileType PRIMARY KEY (ID),
		CONSTRAINT fk_SAANFT_SteamApplication FOREIGN KEY (steamApplicationID) REFERENCES SteamApplication (steamApplicationID) ON DELETE CASCADE,
		CONSTRAINT fk_SAANFT_ApplicationMediaFileType FOREIGN KEY (applicationMediaFileTypeID) REFERENCES ApplicationMediaFileType (applicationMediaFileTypeID) ON DELETE CASCADE
GO