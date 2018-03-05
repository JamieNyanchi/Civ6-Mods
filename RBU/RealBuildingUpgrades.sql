--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- Mar 20th, 2017 - Version 1 created
-- Aug 2nd, 2017 - Version 1.3, fix for summer patch
-- Sep 10th, 2017 - Version 1.3.1, tech fix for column names
-- Sep 18th, 2017 - Version 1.4, fix for Aztecs DLC
-- Nov 13th, 2017 - Version 1.5, fix for Apadana crash
-- 2018-03-04: Added Dar-e Mehr and Stupa
-- 2018-03-05: Removed all EnabledByReligion=1 Upgrades (game only allows for 1), removed Apadana fix (no longer necessary)
--------------------------------------------------------------

-- Version 1.5 Fix for Apadana crash; 2018-03-05 no longer necessary (tested)
--UPDATE Buildings SET AdjacentCapital = 0 WHERE BuildingType = 'BUILDING_APADANA';

-- first, some balance fixes
-- Research Lab 5->6, so later Upgrade can get 3; cost increased proportionally by 15%
--UPDATE Building_YieldChanges SET YieldChange = 6 WHERE BuildingType = 'BUILDING_RESEARCH_LAB' AND YieldType = 'YIELD_SCIENCE';
--UPDATE Buildings SET Cost = Cost * (115/100) WHERE BuildingType = 'BUILDING_RESEARCH_LAB';

-- The AI doesn't want to build Stables, but builds loads of Barracks probably because they are available
-- earlier and are cheaper; so lets make them comparable
UPDATE Buildings
SET Cost = (SELECT Cost FROM Buildings WHERE BuildingType = 'BUILDING_STABLE'),
	PrereqTech = 'TECH_IRON_WORKING'
WHERE BuildingType = 'BUILDING_BARRACKS';

--------------------------------------------------------------
-- Table with new parameters for buildings - the rest will be default
--------------------------------------------------------------
CREATE TABLE RBUConfig (
	BType	TEXT	NOT NULL,  	-- BuildingType
	PTech	TEXT,  				-- PrereqTech
	PCivic	TEXT,  				-- PrereqCivic
	UCost	INTEGER	NOT NULL,
	PDist	TEXT	NOT NULL,  	-- PrereqDistrict
	UMain	INTEGER NOT NULL DEFAULT 0, -- Maintenance
	Advis	TEXT,  				-- AdvisorType
	PRIMARY KEY (BType)
);

INSERT INTO RBUConfig (BType, PTech, PCivic, UCost, PDist, UMain, Advis)
VALUES  -- generated from Excel
('AIRPORT','TELECOMMUNICATIONS',NULL,450,'AERODROME',3,'CONQUEST'),
('AMPHITHEATER',NULL,'RECORDED_HISTORY',75,'THEATER',1,'CULTURE'),
('ARENA',NULL,'MILITARY_TRAINING',75,'ENTERTAINMENT_COMPLEX',1,'GENERIC'),
('ARMORY','GUNPOWDER',NULL,145,'ENCAMPMENT',2,'CONQUEST'),
('BANK','SCIENTIFIC_THEORY',NULL,215,'COMMERCIAL_HUB',0,'GENERIC'),
('BARRACKS','ENGINEERING',NULL,60,'ENCAMPMENT',1,'CONQUEST'),
('BROADCAST_CENTER','COMPUTERS',NULL,720,'THEATER',3,'CULTURE'),
('CASTLE','PRINTING',NULL,165,'CITY_CENTER',1,'GENERIC'),
--('CATHEDRAL',NULL,'REFORMED_CHURCH',140,'HOLY_SITE',0,NULL),
--('DAR_E_MEHR',NULL,'REFORMED_CHURCH',140,'HOLY_SITE',0,NULL),
('ELECTRONICS_FACTORY','STEAM_POWER',NULL,290,'INDUSTRIAL_ZONE',3,'GENERIC'),
('FACTORY','STEAM_POWER',NULL,290,'INDUSTRIAL_ZONE',3,'GENERIC'),
('FILM_STUDIO','COMPUTERS',NULL,720,'THEATER',0,'CULTURE'),
('GRANARY','IRRIGATION',NULL,30,'CITY_CENTER',1,'GENERIC'),
--('GURDWARA',NULL,'REFORMED_CHURCH',140,'HOLY_SITE',0,NULL),
('HANGAR','RADIO',NULL,230,'AERODROME',1,'CONQUEST'),
('LIBRARY','CURRENCY',NULL,45,'CAMPUS',1,'TECHNOLOGY'),
('LIGHTHOUSE','SHIPBUILDING',NULL,60,'HARBOR',1,'GENERIC'),
('MADRASA',NULL,'DIVINE_RIGHT',185,'CAMPUS',3,'TECHNOLOGY'),
('MARKET','MATHEMATICS',NULL,60,'COMMERCIAL_HUB',0,'GENERIC'),
--('MEETING_HOUSE',NULL,'REFORMED_CHURCH',140,'HOLY_SITE',0,NULL),
('MILITARY_ACADEMY','RIFLING',NULL,490,'ENCAMPMENT',3,'CONQUEST'),
('MONUMENT','WRITING',NULL,30,'CITY_CENTER',1,'CULTURE'),
--('MOSQUE',NULL,'REFORMED_CHURCH',140,'HOLY_SITE',0,NULL),
('MUSEUM_ART',NULL,'THE_ENLIGHTENMENT',215,'THEATER',1,'CULTURE'),
('MUSEUM_ARTIFACT',NULL,'THE_ENLIGHTENMENT',215,'THEATER',1,'CULTURE'),
--('PAGODA',NULL,'REFORMED_CHURCH',140,'HOLY_SITE',0,NULL),
('PALACE',NULL,'CODE_OF_LAWS',150,'CITY_CENTER',0,'GENERIC'),
('POWER_PLANT','COMPUTERS',NULL,720,'INDUSTRIAL_ZONE',4,'GENERIC'),
('RESEARCH_LAB','NUCLEAR_FISSION',NULL,720,'CAMPUS',4,'TECHNOLOGY'),
('SEAPORT','COMPUTERS',NULL,720,'HARBOR',0,'GENERIC'),
('SEWER','CHEMISTRY',NULL,150,'CITY_CENTER',2,'GENERIC'),
('SHIPYARD','SQUARE_RIGGING',NULL,215,'HARBOR',2,'GENERIC'),
('SHRINE','CELESTIAL_NAVIGATION',NULL,35,'HOLY_SITE',1,'RELIGIOUS'),
('STABLE','CONSTRUCTION',NULL,60,'ENCAMPMENT',1,'CONQUEST'),
('STADIUM',NULL,'SOCIAL_MEDIA',820,'ENTERTAINMENT_COMPLEX',3,'GENERIC'),
('STAR_FORT','BALLISTICS',NULL,380,'CITY_CENTER',1,'GENERIC'),
('STAVE_CHURCH',NULL,'DIVINE_RIGHT',90,'HOLY_SITE',2,'RELIGIOUS'),
('STOCK_EXCHANGE','COMPUTERS',NULL,490,'COMMERCIAL_HUB',0,'GENERIC'),
--('STUPA',NULL,'REFORMED_CHURCH',140,'HOLY_SITE',0,NULL),
('SUKIENNICE','MATHEMATICS',NULL,60,'COMMERCIAL_HUB',0,NULL),
--('SYNAGOGUE',NULL,'REFORMED_CHURCH',140,'HOLY_SITE',0,NULL),
('TEMPLE',NULL,'DIVINE_RIGHT',90,'HOLY_SITE',2,'RELIGIOUS'),
('TLACHTLI',NULL,'MILITARY_TRAINING',65,'ENTERTAINMENT_COMPLEX',1,NULL),
('UNIVERSITY','PRINTING',NULL,185,'CAMPUS',2,'TECHNOLOGY'),
('WALLS','CONSTRUCTION',NULL,40,'CITY_CENTER',1,'GENERIC'),
--('WAT',NULL,'REFORMED_CHURCH',140,'HOLY_SITE',0,NULL),
('WATER_MILL','ENGINEERING',NULL,40,'CITY_CENTER',1,'GENERIC'),
('WORKSHOP','EDUCATION',NULL,100,'INDUSTRIAL_ZONE',1,'GENERIC'),
('ZOO',NULL,'CONSERVATION',330,'ENTERTAINMENT_COMPLEX',0,'GENERIC');

-- DLC: Poland - remove upgrade if base building is not there
DELETE FROM RBUConfig
WHERE BType = 'SUKIENNICE' AND NOT EXISTS (SELECT * FROM Buildings WHERE BuildingType = 'BUILDING_SUKIENNICE');

-- DLC: Aztecs - remove upgrade if base building is not there
DELETE FROM RBUConfig
WHERE BType = 'TLACHTLI' AND NOT EXISTS (SELECT * FROM Buildings WHERE BuildingType = 'BUILDING_TLACHTLI');

--------------------------------------------------------------
-- BUILDINGS
--------------------------------------------------------------

-- New building Types	
INSERT INTO Types(Type, Kind)
SELECT 'BUILDING_'||BType||'_UPGRADE', 'KIND_BUILDING'
FROM RBUConfig;

-- New buildings
INSERT INTO Buildings
	(BuildingType, Name, PrereqTech, PrereqCivic, Cost, MaxPlayerInstances, MaxWorldInstances, Capital, PrereqDistrict, AdjacentDistrict, Description, 
	RequiresPlacement, RequiresRiver, OuterDefenseHitPoints, Housing, Entertainment, AdjacentResource, Coast, 
	EnabledByReligion, AllowsHolyCity, PurchaseYield, MustPurchase, Maintenance, IsWonder, TraitType, OuterDefenseStrength, CitizenSlots, 
	MustBeLake, MustNotBeLake, RegionalRange, AdjacentToMountain, ObsoleteEra, RequiresReligion,
	GrantFortification, DefenseModifier, InternalOnly, RequiresAdjacentRiver, Quote, QuoteAudio, MustBeAdjacentLand,
	AdvisorType, AdjacentCapital, AdjacentImprovement, CityAdjacentTerrain)
SELECT
	'BUILDING_'||BType||'_UPGRADE',
	'LOC_BUILDING_'||BType||'_UPGRADE_NAME',
	CASE WHEN PTech IS NULL THEN NULL ELSE 'TECH_'||PTech END,
	CASE WHEN PCivic IS NULL THEN NULL ELSE 'CIVIC_'||PCivic END,
	UCost, -1, -1, 0,  -- Cost, MaxPlayerInstances, MaxWorldInstances, Capital (PALACE!)
	'DISTRICT_'||PDist, NULL,
	'LOC_BUILDING_'||BType||'_UPGRADE_DESCRIPTION',
	0, 0, NULL, 0, 0, NULL, NULL, -- RequiresPlacement, RequiresRiver, OuterDefenseHitPoints, Housing, Entertainment, AdjacentResource, Coast
	0, 0, -- EnabledByReligion, AllowsHolyCity, 
	'YIELD_GOLD', 0,  -- PurchaseYield, MustPurchase
	UMain, 0, NULL, 0, NULL,  -- Maintenance, IsWonder, TraitType, OuterDefenseStrength, CitizenSlots
	0, 0, 0, 0, 'NO_ERA', 0,  -- MustBeLake, MustNotBeLake, RegionalRange, AdjacentToMountain, ObsoleteEra, RequiresReligion
	0, 0, 0, 0, NULL, NULL, 0,  -- GrantFortification, DefenseModifier, InternalOnly, RequiresAdjacentRiver, Quote, QuoteAudio, MustBeAdjacentLand
	CASE WHEN Advis IS NULL THEN NULL ELSE 'ADVISOR_'||Advis END, 0, NULL,  -- AdvisorType, AdjacentCapital, AdjacentImprovement
	NULL  -- CityAdjacentTerrain [Version 1.1, fix for summer patch]
FROM RBUConfig;

-- Palace Upgrade
UPDATE Buildings
SET MaxPlayerInstances = 1, PurchaseYield = NULL  --, Capital = 1
WHERE BuildingType = 'BUILDING_PALACE_UPGRADE';

-- Defensive buildings (walls)
UPDATE Buildings
SET PurchaseYield = NULL, OuterDefenseHitPoints = 25, OuterDefenseStrength = 1
WHERE BuildingType IN (
	'BUILDING_CASTLE_UPGRADE',
	'BUILDING_STAR_FORT_UPGRADE',
	'BUILDING_WALLS_UPGRADE');

-- Buildings with Regional Effects
UPDATE Buildings
SET RegionalRange = 6
WHERE BuildingType IN (
	-- standard building upgrades
	'BUILDING_ELECTRONICS_FACTORY_UPGRADE',
	'BUILDING_FACTORY_UPGRADE',
	--'BUILDING_LIGHTHOUSE_UPGRADE',
	'BUILDING_POWER_PLANT_UPGRADE',
	--'BUILDING_SHRINE_UPGRADE',
	'BUILDING_STADIUM_UPGRADE',
	'BUILDING_ZOO_UPGRADE',
	-- unique features of Level 3 Upgrades
	'BUILDING_FILM_STUDIO_UPGRADE',
	'BUILDING_RESEARCH_LAB_UPGRADE',
	'BUILDING_STOCK_EXCHANGE_UPGRADE');

-- Buildings that add Housing
UPDATE Buildings SET Housing = 1
WHERE BuildingType IN (
	'BUILDING_ELECTRONICS_FACTORY_UPGRADE',
	'BUILDING_FACTORY_UPGRADE',
	'BUILDING_MADRASA_UPGRADE',
	'BUILDING_MILITARY_ACADEMY_UPGRADE',
	'BUILDING_SEWER_UPGRADE',
	'BUILDING_STAR_FORT_UPGRADE',
	'BUILDING_WORKSHOP_UPGRADE');
UPDATE Buildings SET Housing = 2
WHERE BuildingType IN (
	'BUILDING_AIRPORT_UPGRADE');
UPDATE Buildings SET Housing = 3
WHERE BuildingType IN (
	'BUILDING_SEAPORT_UPGRADE');

-- Buildings that add Amenities
UPDATE Buildings
SET Entertainment = 1
WHERE BuildingType IN (
	'BUILDING_AIRPORT_UPGRADE',
	'BUILDING_AMPHITHEATER_UPGRADE',
	'BUILDING_BROADCAST_CENTER_UPGRADE',
	'BUILDING_FILM_STUDIO_UPGRADE',
	'BUILDING_LIBRARY_UPGRADE',
	'BUILDING_STADIUM_UPGRADE');
	
-- Buildings enabled by Religion
-- 2018-03-05 Game only allows for 1 such building, so Upgrades cannot be built :(
/*
UPDATE Buildings
SET EnabledByReligion = 1, PurchaseYield = 'YIELD_FAITH'
WHERE BuildingType IN (
	'BUILDING_CATHEDRAL_UPGRADE',
	'BUILDING_DAR_E_MEHR_UPGRADE',
	'BUILDING_GURDWARA_UPGRADE',
	'BUILDING_MEETING_HOUSE_UPGRADE',
	'BUILDING_MOSQUE_UPGRADE',
	'BUILDING_PAGODA_UPGRADE',
	'BUILDING_STUPA_UPGRADE',
	'BUILDING_SYNAGOGUE_UPGRADE',
	'BUILDING_WAT_UPGRADE');
*/

-- Additonal Food same as Adjacency Bonuses
INSERT INTO Building_YieldDistrictCopies (BuildingType, OldYieldType, NewYieldType)
VALUES
	('BUILDING_POWER_PLANT_UPGRADE', 'YIELD_PRODUCTION', 'YIELD_GOLD'),
	('BUILDING_SEAPORT_UPGRADE', 'YIELD_GOLD', 'YIELD_FOOD');

-- Unique Buildings' Upgrades
-- TraitType will be inserted separately, there are only 5 buildings
UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_ELECTRONICS_FACTORY' WHERE BuildingType = 'BUILDING_ELECTRONICS_FACTORY_UPGRADE';
UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_FILM_STUDIO' WHERE BuildingType = 'BUILDING_FILM_STUDIO_UPGRADE';
UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_MADRASA' WHERE BuildingType = 'BUILDING_MADRASA_UPGRADE';
UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_STAVE_CHURCH' WHERE BuildingType = 'BUILDING_STAVE_CHURCH_UPGRADE';
UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_TLACHTLI' WHERE BuildingType = 'BUILDING_TLACHTLI_UPGRADE';
UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_SUKIENNICE' WHERE BuildingType = 'BUILDING_SUKIENNICE_UPGRADE';

-- DLC: Poland
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn)
SELECT 'BUILDING_SUKIENNICE_UPGRADE', 'GREAT_PERSON_CLASS_MERCHANT', 1
FROM RBUConfig
WHERE BType = 'SUKIENNICE';

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType)
SELECT CivUniqueBuildingType||'_UPGRADE', ReplacesBuildingType||'_UPGRADE'
FROM BuildingReplaces
WHERE CivUniqueBuildingType IN (
	'BUILDING_FILM_STUDIO',
	'BUILDING_MADRASA',
	'BUILDING_STAVE_CHURCH',
	'BUILDING_ELECTRONICS_FACTORY',
	'BUILDING_TLACHTLI',
	'BUILDING_SUKIENNICE');

-- Connect Upgrades to Base Buildings
INSERT INTO BuildingPrereqs (Building, PrereqBuilding)
SELECT 'BUILDING_'||BType||'_UPGRADE', 'BUILDING_'||BType
FROM RBUConfig;

-- 2018-03-05 Mutually exclusive buildings (so they won't appear in production list)
INSERT INTO MutuallyExclusiveBuildings (Building, MutuallyExclusiveBuilding) VALUES
('BUILDING_STABLE_UPGRADE', 'BUILDING_BARRACKS'),
('BUILDING_STABLE_UPGRADE', 'BUILDING_BARRACKS_UPGRADE'),
('BUILDING_BARRACKS_UPGRADE', 'BUILDING_STABLE'),
('BUILDING_BARRACKS_UPGRADE', 'BUILDING_STABLE_UPGRADE'),
('BUILDING_MUSEUM_ART_UPGRADE', 'BUILDING_MUSEUM_ARTIFACT'),
('BUILDING_MUSEUM_ART_UPGRADE', 'BUILDING_MUSEUM_ARTIFACT_UPGRADE'),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'BUILDING_MUSEUM_ART'),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'BUILDING_MUSEUM_ART_UPGRADE');


--------------------------------------------------------------
-- Populate basic parameters (i.e. Yields)
--------------------------------------------------------------

INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
VALUES  -- generated from Excel
('BUILDING_AIRPORT_UPGRADE', 'YIELD_PRODUCTION', 2),
('BUILDING_AMPHITHEATER_UPGRADE', 'YIELD_CULTURE', 1),
('BUILDING_ARENA_UPGRADE', 'YIELD_CULTURE', 2),
('BUILDING_ARMORY_UPGRADE', 'YIELD_CULTURE', 1),
('BUILDING_ARMORY_UPGRADE', 'YIELD_PRODUCTION', 2),
('BUILDING_BANK_UPGRADE', 'YIELD_GOLD', 3),
('BUILDING_BANK_UPGRADE', 'YIELD_SCIENCE', 1),
--('BUILDING_BARRACKS_UPGRADE', 'YIELD_PRODUCTION', 1),
('BUILDING_BROADCAST_CENTER_UPGRADE', 'YIELD_CULTURE', 2),
--('BUILDING_CATHEDRAL_UPGRADE', 'YIELD_FAITH', 2),
--('BUILDING_CATHEDRAL_UPGRADE', 'YIELD_FOOD', 2),
--('BUILDING_DAR_E_MEHR_UPGRADE', 'YIELD_FAITH', 2),
--('BUILDING_DAR_E_MEHR_UPGRADE', 'YIELD_SCIENCE', 2),
('BUILDING_ELECTRONICS_FACTORY_UPGRADE', 'YIELD_PRODUCTION', 2),
('BUILDING_FACTORY_UPGRADE', 'YIELD_PRODUCTION', 1),
('BUILDING_FILM_STUDIO_UPGRADE', 'YIELD_CULTURE', 2),
('BUILDING_FILM_STUDIO_UPGRADE', 'YIELD_GOLD', 2),
('BUILDING_GRANARY_UPGRADE', 'YIELD_FOOD', 2),
--('BUILDING_GURDWARA_UPGRADE', 'YIELD_CULTURE', 1),
--('BUILDING_GURDWARA_UPGRADE', 'YIELD_FAITH', 2),
--('BUILDING_GURDWARA_UPGRADE', 'YIELD_FOOD', 1),
('BUILDING_HANGAR_UPGRADE', 'YIELD_PRODUCTION', 2),
('BUILDING_LIBRARY_UPGRADE', 'YIELD_SCIENCE', 1),
('BUILDING_LIGHTHOUSE_UPGRADE', 'YIELD_FOOD', 1),
('BUILDING_MADRASA_UPGRADE', 'YIELD_SCIENCE', 2),
('BUILDING_MARKET_UPGRADE', 'YIELD_GOLD', 2),
--('BUILDING_MEETING_HOUSE_UPGRADE', 'YIELD_FAITH', 2),
--('BUILDING_MEETING_HOUSE_UPGRADE', 'YIELD_PRODUCTION', 1),
--('BUILDING_MEETING_HOUSE_UPGRADE', 'YIELD_SCIENCE', 1),
('BUILDING_MILITARY_ACADEMY_UPGRADE', 'YIELD_CULTURE', 2),
('BUILDING_MILITARY_ACADEMY_UPGRADE', 'YIELD_PRODUCTION', 2),
('BUILDING_MONUMENT_UPGRADE', 'YIELD_CULTURE', 1),
--('BUILDING_MOSQUE_UPGRADE', 'YIELD_FAITH', 2),
--('BUILDING_MOSQUE_UPGRADE', 'YIELD_GOLD', 3),
('BUILDING_MUSEUM_ART_UPGRADE', 'YIELD_CULTURE', 2),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'YIELD_CULTURE', 2),
--('BUILDING_PAGODA_UPGRADE', 'YIELD_CULTURE', 2),
--('BUILDING_PAGODA_UPGRADE', 'YIELD_FAITH', 2),
('BUILDING_PALACE_UPGRADE', 'YIELD_GOLD', 2),
('BUILDING_PALACE_UPGRADE', 'YIELD_PRODUCTION', 1),
('BUILDING_PALACE_UPGRADE', 'YIELD_SCIENCE', 1),
('BUILDING_POWER_PLANT_UPGRADE', 'YIELD_FOOD', 2),
('BUILDING_POWER_PLANT_UPGRADE', 'YIELD_PRODUCTION', 2),
('BUILDING_RESEARCH_LAB_UPGRADE', 'YIELD_SCIENCE', 2),
('BUILDING_SEAPORT_UPGRADE', 'YIELD_FOOD', 1),
('BUILDING_SEAPORT_UPGRADE', 'YIELD_GOLD', 3),
('BUILDING_SEAPORT_UPGRADE', 'YIELD_PRODUCTION', 3),
('BUILDING_SHIPYARD_UPGRADE', 'YIELD_FOOD', 2),
('BUILDING_SHIPYARD_UPGRADE', 'YIELD_PRODUCTION', 2),
('BUILDING_SHRINE_UPGRADE', 'YIELD_FAITH', 1),
--('BUILDING_STABLE_UPGRADE', 'YIELD_PRODUCTION', 1),
('BUILDING_STAVE_CHURCH_UPGRADE', 'YIELD_FAITH', 1),
('BUILDING_STAVE_CHURCH_UPGRADE', 'YIELD_FOOD', 1),
('BUILDING_STOCK_EXCHANGE_UPGRADE', 'YIELD_GOLD', 3),
('BUILDING_STOCK_EXCHANGE_UPGRADE', 'YIELD_SCIENCE', 2),
--('BUILDING_STUPA_UPGRADE', 'YIELD_FAITH', 2),
--('BUILDING_STUPA_UPGRADE', 'YIELD_CULTURE', 1),
--('BUILDING_STUPA_UPGRADE', 'YIELD_FOOD', 1),
--('BUILDING_SYNAGOGUE_UPGRADE', 'YIELD_FAITH', 2),
--('BUILDING_SYNAGOGUE_UPGRADE', 'YIELD_PRODUCTION', 1),
--('BUILDING_SYNAGOGUE_UPGRADE', 'YIELD_GOLD', 2),
('BUILDING_TEMPLE_UPGRADE', 'YIELD_FAITH', 2),
('BUILDING_TEMPLE_UPGRADE', 'YIELD_FOOD', 1),
('BUILDING_UNIVERSITY_UPGRADE', 'YIELD_CULTURE', 1),
('BUILDING_UNIVERSITY_UPGRADE', 'YIELD_SCIENCE', 2),
--('BUILDING_WAT_UPGRADE', 'YIELD_FAITH', 2),
--('BUILDING_WAT_UPGRADE', 'YIELD_PRODUCTION', 1),
--('BUILDING_WAT_UPGRADE', 'YIELD_SCIENCE', 1),
('BUILDING_WATER_MILL_UPGRADE', 'YIELD_PRODUCTION', 1),
('BUILDING_WORKSHOP_UPGRADE', 'YIELD_PRODUCTION', 1),
('BUILDING_ZOO_UPGRADE', 'YIELD_GOLD', 1);

-- DLC: Poland must be updated separately
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
SELECT 'BUILDING_SUKIENNICE_UPGRADE', 'YIELD_GOLD', 2
FROM RBUConfig
WHERE BType = 'SUKIENNICE';

-- DLC: Aztecs must be updated separately
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
SELECT 'BUILDING_TLACHTLI_UPGRADE', 'YIELD_FAITH', 1
FROM RBUConfig
WHERE BType = 'TLACHTLI';
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
SELECT 'BUILDING_TLACHTLI_UPGRADE', 'YIELD_CULTURE', 1
FROM RBUConfig
WHERE BType = 'TLACHTLI';

--------------------------------------------------------------
-- MODIFIERS
--------------------------------------------------------------

INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_ELECTRONICS_FACTORY_UPGRADE', 'ELECTRONICSFACTORYUPGRADE_CULTURE'),
('BUILDING_BARRACKS_UPGRADE', 'BARRACKSUPGRADE_ADDCAMPPRODUCTION'),
('BUILDING_STABLE_UPGRADE', 'STABLEUPGRADE_ADDPASTUREPRODUCTION'),
--('BUILDING_WATER_MILL_UPGRADE', 'WATERMILLUPGRADE_ADDPLANTATIONFOOD'),
('BUILDING_WORKSHOP_UPGRADE', 'WORKSHOPUPGRADE_ADDQUARRYPRODUCTION'),
('BUILDING_STAVE_CHURCH_UPGRADE', 'STAVECHURCHUPGRADE_ADDLUMBERMILLFAITH'),
('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD'),
('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD'),
('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD'),
('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD'),
('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD'),
('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD'),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD'),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD'),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD'),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD'),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD'),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD'),
('BUILDING_STADIUM_UPGRADE', 'STADIUMUPGRADE_BOOST_ALL_TOURISM');

--INSERT INTO Types (Type, Kind)  -- hash value generated automatically
--VALUES ('MODIFIER_XXX_MODIFIER', 'KIND_MODIFIER');

--INSERT INTO DynamicModifiers (ModifierType, CollectionType, EffectType)
--VALUES ('MODIFIER_XXX_MODIFIER', 'COLLECTION_OWNER', 'EFFECT_ADJUST_BUILDING_YIELD_MODIFIER');

-- New requirements
INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('PLOT_HAS_PLANTATION_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL'),
('PLOT_HAS_LUMBER_MILL_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL');
	
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('PLOT_HAS_PLANTATION_REQUIREMENTS', 'REQUIRES_PLOT_HAS_PLANTATION'),
('PLOT_HAS_LUMBER_MILL_REQUIREMENTS', 'REQUIRES_PLOT_HAS_LUMBER_MILL');

INSERT INTO Requirements (RequirementId, RequirementType)
VALUES ('REQUIRES_PLOT_HAS_LUMBER_MILL', 'REQUIREMENT_PLOT_IMPROVEMENT_TYPE_MATCHES');
	
INSERT INTO RequirementArguments (RequirementId, Name, Value)
VALUES ('REQUIRES_PLOT_HAS_LUMBER_MILL', 'ImprovementType', 'IMPROVEMENT_LUMBER_MILL');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('ELECTRONICSFACTORYUPGRADE_CULTURE', 'MODIFIER_BUILDING_YIELD_CHANGE', 0, 1, 'PLAYER_HAS_ELECTRICITYTECHNOLOGY_REQUIREMENTS', NULL),
('BARRACKSUPGRADE_ADDCAMPPRODUCTION', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_CAMP_REQUIREMENTS'),
('STABLEUPGRADE_ADDPASTUREPRODUCTION', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_PASTURE_REQUIREMENTS'),
--('WATERMILLUPGRADE_ADDPLANTATIONFOOD', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_PLANTATION_REQUIREMENTS'),
('WORKSHOPUPGRADE_ADDQUARRYPRODUCTION', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_QUARRY_REQUIREMENTS'),
('STAVECHURCHUPGRADE_ADDLUMBERMILLFAITH', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_LUMBER_MILL_REQUIREMENTS'),
('HANGARUPGRADE_BONUS_AIR_SLOTS', 'MODIFIER_PLAYER_DISTRICT_GRANT_AIR_SLOTS', 0, 1, NULL, NULL),
('AIRPORTUPGRADE_BONUS_AIR_SLOTS', 'MODIFIER_PLAYER_DISTRICT_GRANT_AIR_SLOTS', 0, 1, NULL, NULL),
('MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD', 'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL),
('MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD', 'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL),
('MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD', 'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL),
('MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD', 'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL),
('MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD', 'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL),
('MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD', 'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL),
('STADIUMUPGRADE_BOOST_ALL_TOURISM', 'MODIFIER_PLAYER_ADJUST_TOURISM', 0, 0, NULL, NULL);
	
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
-- Electronics Factory Upgrade +2 Culture
('ELECTRONICSFACTORYUPGRADE_CULTURE', 'BuildingType', 'BUILDING_ELECTRONICS_FACTORY_UPGRADE'),
('ELECTRONICSFACTORYUPGRADE_CULTURE', 'Amount', '2'),
('ELECTRONICSFACTORYUPGRADE_CULTURE', 'YieldType', 'YIELD_CULTURE'),
-- Barracks Upgrade +1 Production from Camps
('BARRACKSUPGRADE_ADDCAMPPRODUCTION', 'Amount', '1'),
('BARRACKSUPGRADE_ADDCAMPPRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
-- Stable Upgrade +1 Production from Pastures
('STABLEUPGRADE_ADDPASTUREPRODUCTION', 'Amount', '1'),
('STABLEUPGRADE_ADDPASTUREPRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
-- Water Mill Upgrade +1 Food from Plantations
--('WATERMILLUPGRADE_ADDPLANTATIONFOOD', 'Amount', '1'),
--('WATERMILLUPGRADE_ADDPLANTATIONFOOD',	'YieldType', 'YIELD_FOOD'),
-- Workshop Upgrade +1 Production from Quarries
('WORKSHOPUPGRADE_ADDQUARRYPRODUCTION', 'Amount', '1'),
('WORKSHOPUPGRADE_ADDQUARRYPRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
-- Stave Church Upgrade +1 Faith from Lumber Mills
('STAVECHURCHUPGRADE_ADDLUMBERMILLFAITH', 'Amount', '1'),
('STAVECHURCHUPGRADE_ADDLUMBERMILLFAITH', 'YieldType', 'YIELD_FAITH'),
-- Hangar & Airport +1 Air Slot
('HANGARUPGRADE_BONUS_AIR_SLOTS', 'Amount', '1'),
('AIRPORTUPGRADE_BONUS_AIR_SLOTS', 'Amount', '1'),
-- Museums +1 Gold for each GW
('MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_ARTIFACT'),
('MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD', 'YieldType', 'YIELD_GOLD'),
('MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD', 'YieldChange', '1'),
('MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_LANDSCAPE'),
('MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD', 'YieldType', 'YIELD_GOLD'),
('MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD', 'YieldChange', '1'),
('MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_MUSIC'),
('MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD', 'YieldType', 'YIELD_GOLD'),
('MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD', 'YieldChange', '1'),
('MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_PORTRAIT'),
('MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD', 'YieldType', 'YIELD_GOLD'),
('MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD', 'YieldChange', '1'),
('MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_SCULPTURE'),
('MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD', 'YieldType', 'YIELD_GOLD'),
('MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD', 'YieldChange', '1'),
('MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_WRITING'),
('MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD', 'YieldType', 'YIELD_GOLD'),
('MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD', 'YieldChange', '1'),
-- Stadium Upgrade +10% to all Tourism
('STADIUMUPGRADE_BOOST_ALL_TOURISM', 'Amount', '10');
	
--------------------------------------------------------------
-- MODIFIERS FOR BELIEFS
-- 2018-03-05 Game only allows for 1 such building, so Upgrades cannot be built :(
--------------------------------------------------------------
/*
INSERT INTO BeliefModifiers (BeliefType, ModifierId)
SELECT BeliefType, ModifierId||'_UPGRADE'
FROM BeliefModifiers
WHERE ModifierId IN (SELECT ModifierId FROM Modifiers WHERE ModifierType = 'MODIFIER_PLAYER_RELIGION_ADD_RELIGIOUS_BUILDING');

INSERT INTO Modifiers (ModifierId, ModifierType)
SELECT 'ALLOW_'||BType||'_UPGRADE', 'MODIFIER_PLAYER_RELIGION_ADD_RELIGIOUS_BUILDING'
FROM RBUConfig
WHERE 'BUILDING_'||BType||'_UPGRADE' IN (SELECT BuildingType FROM Buildings WHERE EnabledByReligion = 1);

INSERT INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'ALLOW_'||BType||'_UPGRADE', 'BuildingType', 'BUILDING_'||BType||'_UPGRADE'
FROM RBUConfig
WHERE 'BUILDING_'||BType||'_UPGRADE' IN (SELECT BuildingType FROM Buildings WHERE EnabledByReligion = 1);
*/

--------------------------------------------------------------
-- AI
-- System Buildings contains only Wonders
-- Will use AiBuildSpecializations that contains only one list: DefaultCitySpecialization
--------------------------------------------------------------
