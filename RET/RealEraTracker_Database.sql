-- ===========================================================================
-- Real Era Tracker
-- Author: Infixo
-- 2019-03-28: Created
-- 2019-03-30: Added ReportsList Loader
-- ===========================================================================

-- just to make versioning easier
INSERT INTO GlobalParameters (Name, Value) VALUES ('RET_VERSION_MAJOR', '1');
INSERT INTO GlobalParameters (Name, Value) VALUES ('RET_VERSION_MINOR', '1');

-- options
INSERT INTO GlobalParameters (Name, Value) VALUES ('RET_OPTION_INCLUDE_OTHERS', '0'); -- set to 1 to detect historic moments that other players earned 
																					  -- please note that this is technically cheating as the game doesn't inform you about them (with few exceptions)

-- ReportsList Loader
INSERT OR REPLACE INTO RLLReports (ReportType, ButtonLabel, LuaEvent, StackID, SortOrder, RequiresXP1) VALUES
('REPORT_ERA_TRACKER', 'LOC_RET_BUTTON_LABEL', 'ReportsList_OpenEraTracker', 'GlobalReportsStack', 520, 1);

																					  
-- ===========================================================================
-- EXTRA DATA IN MOMENTS TABLE
-- Each moment earned will be registered to a tracked one.
-- In some cases the call will be infused with extra data.
-- ===========================================================================

ALTER TABLE Moments ADD COLUMN Category   INTEGER NOT NULL CHECK (Category IN (1,2,3)) DEFAULT 2; -- 1:world, 2: local, 3:repeatable
ALTER TABLE Moments ADD COLUMN Special    TEXT; -- marks moments that need special treatment (usually will be dynamically generated)
ALTER TABLE Moments ADD COLUMN ObjectType TEXT; -- info that will be displayed in the Object column
ALTER TABLE Moments ADD COLUMN MinEra     TEXT REFERENCES Eras (EraType) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE Moments ADD COLUMN MaxEra     TEXT REFERENCES Eras (EraType) ON DELETE CASCADE ON UPDATE CASCADE;


-- category WORLD
UPDATE Moments SET Category = 1 WHERE MomentType LIKE '%FIRST_IN_WORLD';
UPDATE Moments SET Category = 1 WHERE MomentType IN (
'MOMENT_UNIT_CREATED_FIRST_DOMAIN_AIR_IN_WORLD',
'MOMENT_UNIT_CREATED_FIRST_DOMAIN_SEA_IN_WORLD',
'MOMENT_UNIT_CREATED_FIRST_REQUIRING_STRATEGIC_IN_WORLD'
);

-- category Repeat - must be set manually
UPDATE Moments SET Category = 3 WHERE MomentType IN (
'MOMENT_ARTIFACT_EXTRACTED',
'MOMENT_BARBARIAN_CAMP_DESTROYED',
'MOMENT_BARBARIAN_CAMP_DESTROYED_NEAR_YOUR_CITY',
'MOMENT_BUILDING_CONSTRUCTED_GAME_ERA_WONDER',
'MOMENT_BUILDING_CONSTRUCTED_PAST_ERA_WONDER',
'MOMENT_CITY_BUILT_NEAR_NATURAL_WONDER',
'MOMENT_CITY_BUILT_NEAR_OTHER_CIV_CITY',
'MOMENT_CITY_BUILT_NEW_CONTINENT',
'MOMENT_CITY_BUILT_ON_DESERT',
'MOMENT_CITY_BUILT_ON_SNOW',
'MOMENT_CITY_BUILT_ON_TUNDRA',
'MOMENT_CITY_CHANGED_RELIGION_ENEMY_CITY_DURING_WAR',
'MOMENT_CITY_CHANGED_RELIGION_OTHER_HOLY_CITY',
'MOMENT_CITY_TRANSFERRED_DISLOYAL_FREE_CITY',
'MOMENT_CITY_TRANSFERRED_FOREIGN_CAPITAL',
'MOMENT_CITY_TRANSFERRED_TO_ORIGINAL_OWNER',
'MOMENT_EMERGENCY_WON_AS_MEMBER',
'MOMENT_EMERGENCY_WON_AS_TARGET',
'MOMENT_FIND_NATURAL_WONDER',
'MOMENT_GOODY_HUT_TRIGGERED',
'MOMENT_GREAT_PERSON_CREATED_GAME_ERA',
'MOMENT_GREAT_PERSON_CREATED_PAST_ERA',
'MOMENT_GREAT_PERSON_CREATED_PATRONAGE_FAITH_OVER_HALF',
'MOMENT_GREAT_PERSON_CREATED_PATRONAGE_GOLD_OVER_HALF',
'MOMENT_NATIONAL_PARK_CREATED',
'MOMENT_PLAYER_GAVE_ENVOY_CANCELED_LEVY',
'MOMENT_PLAYER_GAVE_ENVOY_CANCELED_SUZERAIN_DURING_WAR',
'MOMENT_PLAYER_LEVIED_MILITARY',
'MOMENT_PLAYER_LEVIED_MILITARY_NEAR_ENEMY_CITY',
'MOMENT_PLAYER_MET_MAJOR',
'MOMENT_SPY_MAX_LEVEL',
'MOMENT_TRADING_POST_CONSTRUCTED_IN_OTHER_CIV',
'MOMENT_UNIT_HIGH_LEVEL',
'MOMENT_UNIT_KILLED_UNDERDOG_MILITARY_FORMATION',
'MOMENT_UNIT_KILLED_UNDERDOG_PROMOTIONS',
'MOMENT_WAR_DECLARED_USING_CASUS_BELLI',
'MOMENT_CITY_BUILT_NEAR_FLOODABLE_RIVER',
'MOMENT_CITY_BUILT_NEAR_VOLCANO',
'MOMENT_MITIGATED_COASTAL_FLOOD',
'MOMENT_MITIGATED_RIVER_FLOOD',
'MOMENT_PLAYER_EARNED_DIPLOMATIC_VICTORY_POINT'
);

--- specials - eras
UPDATE Moments SET Special = 'ERA' WHERE MomentIllustrationType = 'MOMENT_ILLUSTRATION_CIVIC_ERA';
UPDATE Moments SET Special = 'ERA' WHERE MomentIllustrationType = 'MOMENT_ILLUSTRATION_TECHNOLOGY_ERA';
-- specials - strategic resource type
UPDATE Moments SET Special = 'STRATEGIC' WHERE MomentType = 'MOMENT_UNIT_CREATED_FIRST_REQUIRING_STRATEGIC';
UPDATE Moments SET Special = 'STRATEGIC' WHERE MomentType = 'MOMENT_UNIT_CREATED_FIRST_REQUIRING_STRATEGIC_IN_WORLD';
-- specials - uniques
UPDATE Moments SET Special = 'UNIQUE' WHERE MomentIllustrationType LIKE 'MOMENT_ILLUSTRATION_UNIQUE%';

-- eras
UPDATE Moments SET MinEra = MinimumGameEra WHERE MinimumGameEra IS NOT NULL;
UPDATE Moments SET MaxEra = ObsoleteEra    WHERE ObsoleteEra    IS NOT NULL;
UPDATE Moments SET MaxEra = MaximumGameEra WHERE MinimumGameEra IS NOT NULL;
-- special cases?


-- projects
UPDATE Moments SET ObjectType = 'PROJECT_MANHATTAN_PROJECT' WHERE MomentType = 'MOMENT_PROJECT_FOUNDED_MANHATTEN';
UPDATE Moments SET ObjectType = 'PROJECT_OPERATION_IVY'     WHERE MomentType = 'MOMENT_PROJECT_FOUNDED_OPERATION_IVY';
UPDATE Moments SET ObjectType = 'PROJECT_LAUNCH_EARTH_SATELLITE' WHERE MomentType = 'MOMENT_PROJECT_FOUNDED_SATELLITE_LAUNCH';
UPDATE Moments SET ObjectType = 'PROJECT_LAUNCH_EARTH_SATELLITE' WHERE MomentType = 'MOMENT_PROJECT_FOUNDED_SATELLITE_LAUNCH_FIRST_IN_WORLD';
UPDATE Moments SET ObjectType = 'PROJECT_LAUNCH_MOON_LANDING'    WHERE MomentType = 'MOMENT_PROJECT_FOUNDED_MOON_LANDING';
UPDATE Moments SET ObjectType = 'PROJECT_LAUNCH_MOON_LANDING'    WHERE MomentType = 'MOMENT_PROJECT_FOUNDED_MOON_LANDING_FIRST_IN_WORLD';
UPDATE Moments SET ObjectType = 'PROJECT_LAUNCH_MARS_BASE'       WHERE MomentType = 'MOMENT_PROJECT_FOUNDED_MARS'                AND EXISTS (SELECT * FROM Projects WHERE ProjectType = 'PROJECT_LAUNCH_MARS_BASE');
UPDATE Moments SET ObjectType = 'PROJECT_LAUNCH_MARS_BASE'       WHERE MomentType = 'MOMENT_PROJECT_FOUNDED_MARS_FIRST_IN_WORLD' AND EXISTS (SELECT * FROM Projects WHERE ProjectType = 'PROJECT_LAUNCH_MARS_BASE');
UPDATE Moments SET ObjectType = 'PROJECT_LAUNCH_EXOPLANET_EXPEDITION' WHERE MomentType = 'MOMENT_PROJECT_FOUNDED_EXOPLANET';
UPDATE Moments SET ObjectType = 'PROJECT_LAUNCH_EXOPLANET_EXPEDITION' WHERE MomentType = 'MOMENT_PROJECT_FOUNDED_EXOPLANET_FIRST_IN_WORLD';

-- districts
UPDATE Moments SET ObjectType = 'DISTRICT_AERODROME'  WHERE MomentType = 'MOMENT_BUILDING_CONSTRUCTED_FULL_AERODROME_FIRST';
UPDATE Moments SET ObjectType = 'DISTRICT_ENCAMPMENT' WHERE MomentType = 'MOMENT_BUILDING_CONSTRUCTED_FULL_ENCAMPMENT_FIRST';
UPDATE Moments SET ObjectType = 'DISTRICT_ENTERTAINMENT_COMPLEX'       WHERE MomentType = 'MOMENT_BUILDING_CONSTRUCTED_FULL_ENTERTAINMENT_COMPLEX_FIRST';
UPDATE Moments SET ObjectType = 'DISTRICT_WATER_ENTERTAINMENT_COMPLEX' WHERE MomentType = 'MOMENT_BUILDING_CONSTRUCTED_FULL_WATER_ENTERTAINMENT_COMPLEX_FIRST';

-- improvements
UPDATE Moments SET ObjectType = 'IMPROVEMENT_BEACH_RESORT'    WHERE MomentType = 'MOMENT_IMPROVEMENT_CONSTRUCTED_SEASIDE_RESORT_FIRST';
UPDATE Moments SET ObjectType = 'IMPROVEMENT_BEACH_RESORT'    WHERE MomentType = 'MOMENT_IMPROVEMENT_CONSTRUCTED_SEASIDE_RESORT_FIRST_IN_WORLD';
UPDATE Moments SET ObjectType = 'IMPROVEMENT_MOUNTAIN_TUNNEL' WHERE MomentType = 'MOMENT_IMPROVEMENT_CONSTRUCTED_MOUNTAIN_TUNNEL_FIRST';
UPDATE Moments SET ObjectType = 'IMPROVEMENT_MOUNTAIN_TUNNEL' WHERE MomentType = 'MOMENT_IMPROVEMENT_CONSTRUCTED_MOUNTAIN_TUNNEL_FIRST_IN_WORLD';
