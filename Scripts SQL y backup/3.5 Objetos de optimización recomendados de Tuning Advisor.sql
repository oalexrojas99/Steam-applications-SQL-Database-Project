USE SteamApplicationsDB
GO

/*Nuevos índices*/
-- 1.
DROP INDEX IF EXISTS [Developer].[_dta_index_Developer_15_805577908__K1_2]
GO

CREATE NONCLUSTERED INDEX [_dta_index_Developer_15_805577908__K1_2] ON [dbo].[Developer]
(
	[developerID] ASC
)
INCLUDE([developerName]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
GO

-- 2.
DROP INDEX IF EXISTS [Publisher].[_dta_index_Publisher_15_773577794__K1_2]
GO

CREATE NONCLUSTERED INDEX [_dta_index_Publisher_15_773577794__K1_2] ON [dbo].[Publisher]
(
	[publisherID] ASC
)
INCLUDE([publisherName]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
GO

-- 3.
DROP INDEX IF EXISTS [SteamApplication].[_dta_index_SteamApplication_15_1557580587__K1]
GO

SET ANSI_PADDING ON

CREATE NONCLUSTERED INDEX [_dta_index_SteamApplication_15_1557580587__K1] ON [dbo].[SteamApplication]
(
	[steamApplicationID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
GO

-- 4.
DROP INDEX IF EXISTS [SteamApplication].[_dta_index_SteamApplication_15_1557580587__K8_K1_K10_2_3_5_6]
GO

SET ANSI_PADDING ON

CREATE NONCLUSTERED INDEX [_dta_index_SteamApplication_15_1557580587__K8_K1_K10_2_3_5_6] ON [dbo].[SteamApplication]
(
	[apprNumberOwners] ASC,
	[steamApplicationID] ASC,
	[ageClassificationID] ASC
)
INCLUDE([applicationName],[releaseDate],[positiveRatings],[negativeRatings]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
GO

-- 5.
DROP INDEX IF EXISTS [SteamApplication].[_dta_index_SteamApplication_15_1557580587__K2_K10_K11_K1_3_5_6_8_9]
GO

SET ANSI_PADDING ON

CREATE NONCLUSTERED INDEX [_dta_index_SteamApplication_15_1557580587__K2_K10_K11_K1_3_5_6_8_9] ON [dbo].[SteamApplication]
(
	[applicationName] ASC,
	[ageClassificationID] ASC,
	[supportInfoID] ASC,
	[steamApplicationID] ASC
)
INCLUDE([releaseDate],[positiveRatings],[negativeRatings],[apprNumberOwners],[price]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
GO

-- 6.
DROP INDEX IF EXISTS [SteamApplication].[_dta_index_SteamApplication_15_1557580587__K10_K11_K1_2_3_5_6_8_9]
GO

SET ANSI_PADDING ON

CREATE NONCLUSTERED INDEX [_dta_index_SteamApplication_15_1557580587__K10_K11_K1_2_3_5_6_8_9] ON [dbo].[SteamApplication]
(
	[ageClassificationID] ASC,
	[supportInfoID] ASC,
	[steamApplicationID] ASC
)
INCLUDE([applicationName],[releaseDate],[positiveRatings],[negativeRatings],[apprNumberOwners],[price]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
GO

-- 7.
DROP INDEX IF EXISTS [SteamApplication_Category].[_dta_index_SteamApplication_Category_15_1669580986__K2_K3]
GO

SET ANSI_PADDING ON

CREATE NONCLUSTERED INDEX [_dta_index_SteamApplication_Category_15_1669580986__K2_K3] ON [dbo].[SteamApplication_Category]
(
	[steamApplicationID] ASC,
	[categoryID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
GO

-- 8.
DROP INDEX IF EXISTS [SteamApplication_Category].[_dta_index_SteamApplication_Category_15_1669580986__K3_K2]
GO

SET ANSI_PADDING ON

CREATE NONCLUSTERED INDEX [_dta_index_SteamApplication_Category_15_1669580986__K3_K2] ON [dbo].[SteamApplication_Category]
(
	[categoryID] ASC,
	[steamApplicationID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
GO

-- 9.
DROP INDEX IF EXISTS [SteamApplication_Developer].[_dta_index_SteamApplication_Developer_15_1925581898__K2_3]
GO

SET ANSI_PADDING ON

CREATE NONCLUSTERED INDEX [_dta_index_SteamApplication_Developer_15_1925581898__K2_3] ON [dbo].[SteamApplication_Developer]
(
	[steamApplicationID] ASC
)
INCLUDE([developerID]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
GO

-- 10.
DROP INDEX IF EXISTS [SteamApplication_Genre].[_dta_index_SteamApplication_Genre_15_1733581214__K2_K3]
GO

SET ANSI_PADDING ON

CREATE NONCLUSTERED INDEX [_dta_index_SteamApplication_Genre_15_1733581214__K2_K3] ON [dbo].[SteamApplication_Genre]
(
	[steamApplicationID] ASC,
	[genreID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
GO

-- 11.
DROP INDEX IF EXISTS [SteamApplication_Publisher].[_dta_index_SteamApplication_Publisher_15_1861581670__K2_K3]
GO

SET ANSI_PADDING ON

CREATE NONCLUSTERED INDEX [_dta_index_SteamApplication_Publisher_15_1861581670__K2_K3] ON [dbo].[SteamApplication_Publisher]
(
	[steamApplicationID] ASC,
	[publisherID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]

-- 12.
DROP INDEX IF EXISTS [SteamApplication_SupportedPlatform].[_dta_index_SteamApplication_SupportedPlatfo_15_1989582126__K2_3]
GO

SET ANSI_PADDING ON

CREATE NONCLUSTERED INDEX [_dta_index_SteamApplication_SupportedPlatfo_15_1989582126__K2_3] ON [dbo].[SteamApplication_SupportedPlatform]
(
	[steamApplicationID] ASC
)
INCLUDE([supportedPlatformID]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
GO

-- 13.
DROP INDEX IF EXISTS [SteamApplication_Tag].[_dta_index_SteamApplication_Tag_15_530100929__K2_K3]
GO

SET ANSI_PADDING ON

CREATE NONCLUSTERED INDEX [_dta_index_SteamApplication_Tag_15_530100929__K2_K3] ON [dbo].[SteamApplication_Tag]
(
	[steamApplicationID] ASC,
	[tagID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
GO

-- 14.
DROP INDEX IF EXISTS [SupportInfo].[_dta_index_SupportInfo_15_709577566__K1_4]
GO

CREATE NONCLUSTERED INDEX [_dta_index_SupportInfo_15_709577566__K1_4] ON [dbo].[SupportInfo]
(
	[supportInfoID] ASC
)
INCLUDE([supportEmail]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
GO

/*Nuevas estadísticas*/
-- 1. 
CREATE STATISTICS [_dta_stat_805577908_2_1] ON [dbo].[Developer]([developerName], [developerID])
GO

-- 2.

CREATE STATISTICS [_dta_stat_773577794_2_1] ON [dbo].[Publisher]([publisherName], [publisherID])
GO

-- 3.

CREATE STATISTICS [_dta_stat_1557580587_10_8] ON [dbo].[SteamApplication]([ageClassificationID], [apprNumberOwners])
GO

-- 4.

CREATE STATISTICS [_dta_stat_1557580587_1_2_10] ON [dbo].[SteamApplication]([steamApplicationID], [applicationName], [ageClassificationID])
GO

-- 5.

CREATE STATISTICS [_dta_stat_1557580587_1_11] ON [dbo].[SteamApplication]([steamApplicationID], [supportInfoID])
GO

-- 6.

CREATE STATISTICS [_dta_stat_1557580587_1_10] ON [dbo].[SteamApplication]([steamApplicationID], [ageClassificationID])
GO

-- 7.

CREATE STATISTICS [_dta_stat_1557580587_1_10] ON [dbo].[SteamApplication]([steamApplicationID], [ageClassificationID])
GO

-- 8.

CREATE STATISTICS [_dta_stat_594101157_2_3] ON [dbo].[SteamApplication_ApplicationMediaFileType]([steamApplicationID], [applicationMediaFileTypeID])
GO

-- 9.

CREATE STATISTICS [_dta_stat_1925581898_2_3] ON [dbo].[SteamApplication_Developer]([steamApplicationID], [developerID])
GO

-- 10.

CREATE STATISTICS [_dta_stat_1989582126_2_3] ON [dbo].[SteamApplication_SupportedPlatform]([steamApplicationID], [supportedPlatformID])
GO
