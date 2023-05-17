print("Loading WorldRankings_BWR.lua from Better World Rankings version "..GlobalParameters.BWR_VERSION_MAJOR.."."..GlobalParameters.BWR_VERSION_MINOR);
-- ===========================================================================
-- Better World Rankings
-- Author: Infixo
-- 2020-06-22: Created
-- This file contains the actual mod changes. It is executed AFTER base / exp2 files have been executed
-- ===========================================================================

-- Cache base functions
BASE_PopulateOverallInstance = PopulateOverallInstance;
BASE_PopulateOverallTeamIconInstance = PopulateOverallTeamIconInstance;
BASE_PopulateOverallPlayerIconInstance = PopulateOverallPlayerIconInstance;
BASE_PopulateScienceProgressMeters = PopulateScienceProgressMeters;
BASE_GatherCultureData = GatherCultureData;
BASE_PopulateCultureInstance = PopulateCultureInstance;
BASE_ViewCulture = ViewCulture;
BASE_PopulateTeamInstanceShared = PopulateTeamInstanceShared;

-- Expansions check
local bIsRiseAndFall:boolean = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall
local bIsGatheringStorm:boolean = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68"); -- Gathering Storm

-- calculate tourism needed to attract one visiting tourist
local m_iTourismForOne:number = GlobalParameters.TOURISM_TOURISM_TO_MOVE_CITIZEN * PlayerManager.GetWasEverAliveMajorsCount();


-- ===========================================================================
-- Helpers

-- debug routine - prints a table (no recursion)
function dshowtable(tTable:table)
	for k,v in pairs(tTable) do
		print(k, type(v), tostring(v));
	end
end

-- debug routine - prints a table, and tables inside recursively (up to 5 levels)
function dshowrectable(tTable:table, iLevel:number)
	local level:number = 0;
	if iLevel ~= nil then level = iLevel; end
	for k,v in pairs(tTable) do
		print(string.rep("---:",level), k, type(v), tostring(v));
		if type(v) == "table" and level < 5 then dshowrectable(v, level+1); end
	end
end



-- ===========================================================================
-- OVERALL
--[[ teamData record
 	TeamProgress	number	0.125
 	TeamID	number	6
 	PlayerData	table	table: 00000000B02F8660
 ---:	6	table	table: 00000000B02F8840
 ---:---:	SecondTiebreakScore	number	329.18359375
 ---:---:	GenericScore	number	1039
 ---:---:	Player	table	table: 00000000B02821A0
 ---:---:---:	__instance	userdata	userdata: 0000000014A54B10
 ---:---:	SecondTiebreakSummary	string	[ICON_Science] Science per turn: 329.2
 ---:---:	FirstTiebreakSummary	string	Technologies Researched: 61
 ---:---:	FirstTiebreakScore	number	61
 	SecondTeamTiebreakScore	number	329.18359375
 	TeamGenericScore	number	1039
 	FirstTeamTiebreakScore	number	61
 	PlayerCount	number	1
 	TeamScore	number	0.125
--]]

-- returns hasCapital:boolean, numCaptured:number
function CheckOriginalCapitals(playerID:number)
	--print("FUN CheckOriginalCapitals", playerID);
	
	local pCities = Players[playerID]:GetCities();
	if pCities:GetCapitalCity() == nil then return false, 0; end -- we haven't started yet
	
	local hasCapital:boolean, numCaptured:number = false, 0;

	for _,city in pCities:Members() do
		local originalOwnerID:number = city:GetOriginalOwner();
		local pOriginalOwner:table = Players[originalOwnerID];
		if playerID ~= originalOwnerID and pOriginalOwner:IsMajor() and city:IsOriginalCapital() then
			numCaptured = numCaptured + 1;
		elseif playerID == originalOwnerID and pOriginalOwner:IsMajor() and city:IsOriginalCapital() then
			hasCapital = true;
		end
	end

	return hasCapital, numCaptured;
end

function PopulateOverallTeamIconInstance(instance:table, teamData:table, iconSize:number, ribbonSize:number)
	--print("FUN PopulateOverallTeamIconInstance() for team", teamData.TeamID, "player count is", teamData.PlayerCount);
	BASE_PopulateOverallTeamIconInstance(instance, teamData, iconSize, ribbonSize);
	--dshowrectable(teamData);
    
    local function DetectVictoryType() -- why isn't this sent as a parameter???
        for _,playerData in pairs(teamData.PlayerData) do
            if string.match(playerData.SecondTiebreakSummary, "ICON_Science") ~= nil then
                return "VICTORY_TECHNOLOGY";
            elseif string.match(playerData.SecondTiebreakSummary, "ICON_Culture") ~= nil then
                return "VICTORY_CULTURE";
            elseif string.match(playerData.SecondTiebreakSummary, "ICON_Faith") ~= nil then
                return "VICTORY_RELIGIOUS";
            elseif string.match(playerData.FirstTiebreakSummary, "/") ~= nil then
                return "VICTORY_DIPLOMATIC";
            else
                local digits:string = string.match(playerData.FirstTiebreakSummary, '%d+');
                if digits ~= nil and tonumber(digits) > 20 then
                    return "VICTORY_CONQUEST";
                end
            end
        end -- players
        return "";
    end
    local victoryType:string = DetectVictoryType();
    --print("victory type is", victoryType);
    
	-- new fields
	local score1:number, score2:number = Round(teamData.FirstTeamTiebreakScore, 0), Round(teamData.SecondTeamTiebreakScore, 0);
    local victoryData = g_victoryData[victoryType];
    local player = {};
    for _, playerData in pairs(teamData.PlayerData) do
        player = playerData.Player;
        break;
    end
    local firstTeamTiebreakSummary = Locale.Lookup((victoryData.Primary or victoryData).GetText(player), score1);
    local secondTeamTiebreakSummary = Locale.Lookup((victoryData.Secondary or victoryData).GetText(player), score2);
    -- tooltips are the same for all
    instance.Line1:SetToolTipString(firstTeamTiebreakSummary);
	instance.Line2:SetToolTipString(secondTeamTiebreakSummary);
    -- formatting depends on the victory type
    if     victoryType == "VICTORY_TECHNOLOGY" then
        instance.Line1:SetText(tostring(score1));
        instance.Line2:SetText("[COLOR_Science]"..tostring(score2).."[ENDCOLOR]");
    elseif victoryType == "VICTORY_CULTURE" then
        instance.Line1:SetText("[COLOR_Tourism]"..tostring(score1).."[ENDCOLOR]");
        instance.Line2:SetText("[COLOR_Culture]"..tostring(score2).."[ENDCOLOR]");
    elseif victoryType == "VICTORY_CONQUEST" then
        -- check if we still have at least 1 original capital and calculate how many we have captured
        local teamHasCapital:boolean, teamNumCaptured:number = false, 0;
        for _,playerData in pairs(teamData.PlayerData) do
            local hasCapital:boolean, numCaptured:number = CheckOriginalCapitals(playerData.Player:GetID());
            teamHasCapital = teamHasCapital or hasCapital; -- true if at least one
            teamNumCaptured = teamNumCaptured + numCaptured;
        end
        instance.HasCapital:SetHide(not teamHasCapital);
        instance.Line1:SetText(tostring(teamNumCaptured));
        instance.Line1:SetToolTipString(Locale.Lookup("LOC_WORLD_RANKINGS_DOMINATION_SUMMARY", teamNumCaptured));
        instance.Line2:SetText("[COLOR_Military]"..tostring(score2).."[ENDCOLOR]");
    elseif victoryType == "VICTORY_RELIGIOUS" then 
        instance.Line1:SetText(tostring(score1));
        instance.Line2:SetText("[COLOR_FaithDark]"..tostring(score2).."[ENDCOLOR]");
    elseif victoryType == "VICTORY_DIPLOMATIC" then
        instance.Line1:SetText(tostring(score1));
        instance.Line2:SetHide(true);
    else
        instance.Line1:SetText(tostring(score1));
        instance.Line2:SetText(tostring(score2));
    end
    return instance;
end

function PopulateOverallPlayerIconInstance(instance:table, victoryType:string, teamData:table, iconSize:number)
	--print("FUN PopulateOverallPlayerIconInstance()", victoryType, iconSize);
	--dshowrectable(teamData);
	BASE_PopulateOverallPlayerIconInstance(instance, victoryType, teamData, iconSize);
	
	-- new fields
	-- Take the player ID from the first team member who should be the only team member
	local playerID:number = Teams[teamData.TeamID][1];
	local playerData:table = teamData.PlayerData[playerID];
	if playerData ~= nil then
        local score1:number, score2:number = Round(playerData.FirstTiebreakScore, 0), Round(playerData.SecondTiebreakScore, 0);
		-- tooltips are the same for all
		instance.Line1:SetToolTipString(playerData.FirstTiebreakSummary);
		instance.Line2:SetToolTipString(playerData.SecondTiebreakSummary);
		-- formatting depends on the victory type
		if     victoryType == "VICTORY_TECHNOLOGY" then
			instance.Line1:SetText(tostring(score1));
			instance.Line2:SetText("[COLOR_Science]"..tostring(score2).."[ENDCOLOR]");
		elseif victoryType == "VICTORY_CULTURE" then
			instance.Line1:SetText("[COLOR_Tourism]"..tostring(score1).."[ENDCOLOR]");
			instance.Line2:SetText("[COLOR_Culture]"..tostring(score2).."[ENDCOLOR]");
		elseif victoryType == "VICTORY_CONQUEST" then
			local hasCapital:boolean, numCaptured:number = CheckOriginalCapitals(playerID);
			instance.HasCapital:SetHide(not hasCapital);
			instance.Line1:SetText(tostring(numCaptured));
			instance.Line1:SetToolTipString(Locale.Lookup("LOC_WORLD_RANKINGS_DOMINATION_SUMMARY", numCaptured));
			instance.Line2:SetText("[COLOR_Military]"..tostring(score2).."[ENDCOLOR]");
		elseif victoryType == "VICTORY_RELIGIOUS" then 
			instance.Line1:SetText(tostring(score1));
			instance.Line2:SetText("[COLOR_FaithDark]"..tostring(score2).."[ENDCOLOR]");
		elseif victoryType == "VICTORY_DIPLOMATIC" then
            local numNeeded:number = GlobalParameters.DIPLOMATIC_VICTORY_POINTS_REQUIRED;
			instance.Line1:SetText(tostring(score1));
            instance.Line1:SetToolTipString(Locale.Lookup("LOC_WORLD_RANKINGS_DIPLOMATIC_POINTS_TT", score1, numNeeded));
			instance.Line2:SetHide(true);
		else
			instance.Line1:SetText(tostring(score1));
			instance.Line2:SetText(tostring(score2));
		end
	end
end

-- Constants copied from base file for use here
local PADDING_VICTORY_LABEL_UNDERLINE:number = 90;
local SIZE_VICTORY_ICON_SMALL:number = 64;
local TEAM_ICON_SIZE_TOP_TEAM:number = 38;
local TEAM_RIBBON_SIZE_TOP_TEAM:number = 53;
local SIZE_OVERALL_TOP_PLAYER_ICON:number = 48;
local TEAM_ICON_SIZE:number = 28;
local TEAM_RIBBON_SIZE:number = 44;
local SIZE_OVERALL_PLAYER_ICON:number = 36;
local DATA_FIELD_OVERALL_PLAYERS_IM:string = "OverallPlayersIM";

local SIZE_OVERALL_BG_HEIGHT:number = 95;
local SIZE_OVERALL_INSTANCE:number = 75;

function PopulateOverallInstance(instance:table, victoryType:string, typeText:string)

	local victoryInfo:table= GameInfo.Victories[victoryType];
	local numIcons = 0;

	instance.VictoryLabel:SetText(Locale.ToUpper(Locale.Lookup(victoryInfo.Name)));
	instance.VictoryLabelUnderline:SetSizeX(instance.VictoryLabel:GetSizeX() + PADDING_VICTORY_LABEL_UNDERLINE);
	
	local icon:string;
	local color:number;
	if typeText ~= nil then
		icon = "ICON_VICTORY_" .. typeText;
		color = UI.GetColorValue("COLOR_VICTORY_" .. typeText);
	else
		icon = victoryInfo.Icon or ICON_GENERIC;
		color = UI.GetColorValue("White");
	end
	instance.VictoryBanner:SetColor(color);
	instance.VictoryLabelGradient:SetColor(color);

	if icon ~= nil then
		local textureOffsetX:number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas(icon, SIZE_VICTORY_ICON_SMALL);
		if(textureSheet == nil or textureSheet == "") then
			UI.DataError("Could not find icon in PopulateOverallInstance: icon=\""..icon.."\", iconSize="..tostring(SIZE_VICTORY_ICON_SMALL));
		else
			instance.VictoryIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
			instance.VictoryIcon:SetHide(false);
		end
	else
		instance.VictoryIcon:SetHide(true);
	end

	-- Cache victory data to avoid table access within loops
	local victoryData = g_victoryData[victoryType];

	-- Team tiebreaker score functions
	local averageScores = function(playerData, playerCount, scoreKey)
		-- Add player scores
		local score:number = 0;
		for _, player in pairs(playerData) do
			score = score + player[scoreKey];
		end
		-- Divide by player count
		return score / playerCount;
	end;

	-- Gather team data
	local teamIDs = GetAliveMajorTeamIDs();

	local teamData:table = {};
	for _, teamID in ipairs(teamIDs) do
		local team = Teams[teamID];
		if(team ~= nil) then
			-- If progress is nil, then the team is not capable of earning a victory (ex: city-state teams and barbarian teams).
			-- Skip any team that is incapable of earning a victory.
			local progress = Game.GetVictoryProgressForTeam(victoryType, teamID);
			if(progress ~= nil) then

				-- PlayerData
				local playerData:table = {};
				local playerCount:number = 0;
                local everAliveCount:number = 0;
				local teamGenericScore = 0;

				for i, playerID in ipairs(team) do
					if IsAliveAndMajor(playerID) then
						local pPlayer:table = Players[playerID];

						local firstTiebreaker:table = victoryData.Primary or victoryData;
						local secondTiebreaker:table = victoryData.Secondary or victoryData;
						local primaryScore:number = firstTiebreaker.GetScore(pPlayer);
						local secondaryScore:number = secondTiebreaker.GetScore(pPlayer);					
						local additionalSummary:string = (victoryData.AdditionalSummary and victoryData.AdditionalSummary(pPlayer)) or "";

						local genericScore = pPlayer:GetScore();

						-- Team score is calculated as the highest individual score.
						teamGenericScore = math.max(teamGenericScore, genericScore);

						playerData[playerID] = {
							Player = pPlayer,
							GenericScore = genericScore,
							FirstTiebreakScore = primaryScore,
							SecondTiebreakScore = secondaryScore,
							FirstTiebreakSummary = Locale.Lookup(firstTiebreaker.GetText(pPlayer), Round(primaryScore, 1)),
							SecondTiebreakSummary = Locale.Lookup(secondTiebreaker.GetText(pPlayer), Round(secondaryScore, 1)),							
							AdditionalSummary = Locale.Lookup(additionalSummary);
						};

						playerCount = playerCount + 1;
					end
                    
                    if (Players[playerID]:IsMajor()) then
                        everAliveCount = everAliveCount + 1;
                    end
				end

				-- Team Data
				table.insert(teamData, {
					TeamID = teamID,
					TeamScore = progress,
					TeamProgress = progress,
					TeamGenericScore = teamGenericScore,
					PlayerData = playerData,
					PlayerCount = playerCount,
                    EverAliveCount = everAliveCount,
					FirstTeamTiebreakScore = averageScores(playerData, playerCount, "FirstTiebreakScore");
					SecondTeamTiebreakScore = averageScores(playerData, playerCount, "SecondTiebreakScore");
				});
			end
		end
	end

	-- Sort teams by score
	table.sort(teamData, function(a, b)
		if (a.TeamProgress ~= b.TeamProgress) then
			return a.TeamProgress > b.TeamProgress;
		elseif(a.FirstTeamTiebreakScore ~= b.FirstTeamTiebreakScore) then
			return a.FirstTeamTiebreakScore > b.FirstTeamTiebreakScore;
		elseif(a.SecondTeamTiebreakScore ~= b.SecondTeamTiebreakScore) then
			return a.SecondTeamTiebreakScore > b.SecondTeamTiebreakScore;
		elseif(a.TeamGenericScore ~= b.TeamGenericScore) then
			return a.TeamGenericScore > b.TeamGenericScore;
		else
			return a.TeamID < b.TeamID;
		end
	end);

	-- Handle case where this victory type is not completable by any team.
	-- This can happen with Global Thermonuclear War's Proxy War victory if there are no city states to conquer.
	if(#teamData < 1) then
			instance.VictoryPlayer:SetText("");
			instance.VictoryLeading:SetText(Locale.Lookup("LOC_WORLD_RANKINGS_VICTORY_DISABLED"));
			-- Make the whole box look plain, since the victory is out of reach
			instance.TeamRibbon:SetHide(true);
			instance.TopPlayer:SetHide(true);
			instance.CivIcon:SetHide(true);
			instance.CivIconFaded:SetHide(true);
			instance.CivIconBacking:SetHide(true);
			instance.CivIconBackingRing:SetHide(true);
			instance.CivIconBackingFaded:SetHide(true);
			instance.VictoryLabelGradient:SetHide(true); 
			instance.VictoryBanner:SetHide(true); 
			instance.VictoryIcon:SetHide(true); 
		return;
	end

	-- Ensure we have Instance Managers for the player meters
	local playersIM:table = instance[DATA_FIELD_OVERALL_PLAYERS_IM];
	if(playersIM == nil) then
		playersIM = InstanceManager:new("OverallPlayerInstance", "CivIconBackingFaded", instance.PlayerStack);
		instance[DATA_FIELD_OVERALL_PLAYERS_IM] = playersIM;
	end
	playersIM:ResetInstances();

	-- Populate top team/player icon
	if teamData[1].EverAliveCount > 1 then
		PopulateOverallTeamIconInstance(instance, teamData[1], TEAM_ICON_SIZE_TOP_TEAM, TEAM_RIBBON_SIZE_TOP_TEAM);
	else
		PopulateOverallPlayerIconInstance(instance, victoryType, teamData[1], SIZE_OVERALL_TOP_PLAYER_ICON);
	end
	numIcons = numIcons + 1;

	-- Populate other team/player icons
	if #teamData > 1 then
		for i = 2, #teamData, 1 do
			local playerInstance:table = playersIM:GetInstance();
			if teamData[i].EverAliveCount > 1 then
				PopulateOverallTeamIconInstance(playerInstance, teamData[i], TEAM_ICON_SIZE, TEAM_RIBBON_SIZE);
			else
				PopulateOverallPlayerIconInstance(playerInstance, victoryType, teamData[i], SIZE_OVERALL_PLAYER_ICON);
			end
			numIcons = numIcons + 1;
		end
	end

	-- Determine if local player is leading
	local isLocalPlayerLeading:boolean = false;
	local leadingTeam:table = teamData[1];
	for playerID, data in pairs(teamData[1].PlayerData) do
		if playerID == g_LocalPlayerID then
			isLocalPlayerLeading = true;
		end
	end

	-- Populate leading and local player labels
	if isLocalPlayerLeading then
		-- You or your team is leading
		instance.VictoryPlayer:SetText("");
		if teamData[1].EverAliveCount > 1 then
			instance.VictoryLeading:SetText(Locale.Lookup("LOC_WORLD_RANKINGS_FIRST_PLACE_TEAM_SIMPLE"));
		else
			instance.VictoryLeading:SetText(Locale.Lookup("LOC_WORLD_RANKINGS_FIRST_PLACE_YOU_SIMPLE"));
		end
	else
		-- Set top team/player text
		local topName:string = "";
		if teamData[1].EverAliveCount > 1 then
			topName = Locale.Lookup("LOC_WORLD_RANKINGS_TEAM", GameConfiguration.GetTeamName(teamData[1].TeamID) + 1);
		else
			local topPlayerID:number = Teams[teamData[1].TeamID][1];
			if(g_LocalPlayer == nil or g_LocalPlayer:GetDiplomacy():HasMet(topPlayerID))then
				topName = Locale.Lookup(GameInfo.Civilizations[PlayerConfigurations[Teams[teamData[1].TeamID][1]]:GetCivilizationTypeID()].Name);
			else
				topName = LOC_UNKNOWN_CIV;
			end
		end
		instance.VictoryLeading:SetText(Locale.Lookup("LOC_WORLD_RANKINGS_FIRST_PLACE_OTHER_SIMPLE", topName));

		-- Set local team/player text
		local isVictoryPlayerSet:boolean = false;
		for teamPosition, team in ipairs(teamData) do
			for playerID, data in pairs(team.PlayerData) do
				if playerID == g_LocalPlayerID then
					local localPlayerPositionText:string = Locale.Lookup("LOC_WORLD_RANKINGS_" .. teamPosition .. "_PLACE");
					local localPlayerDescription:string = "";

					if team.EverAliveCount > 1 then
						localPlayerDescription = Locale.Lookup("LOC_WORLD_RANKINGS_OTHER_PLACE_TEAM_SIMPLE", localPlayerPositionText);
					else
						localPlayerDescription = Locale.Lookup("LOC_WORLD_RANKINGS_OTHER_PLACE_SIMPLE", localPlayerPositionText);
					end

					instance.VictoryPlayer:SetText(localPlayerDescription);
					isVictoryPlayerSet = true;
				end
			end
		end
		if (not isVictoryPlayerSet) then
			instance.VictoryPlayer:SetText("");		
		end
	end

	--instance.ButtonBG:SetSizeY(SIZE_OVERALL_BG_HEIGHT + math.max(instance.PlayerStack:GetSizeY(), SIZE_OVERALL_INSTANCE * ((numIcons / 9) + 1)));

	--print("FUN PopulateOverallInstance()", victoryType, typeText);
	--BASE_PopulateOverallInstance(instance, victoryType, typeText);
	
	-- this is just to resize the instance properly
	local numIcons:number = PlayerManager.GetAliveMajorsCount() - 1; -- max 9 in one line
	local numRows:number = math.floor(numIcons/9); -- full rows
	if numIcons > numRows * 9 then numRows = numRows + 1; end -- partial row
	instance.ButtonBG:SetSizeY(SIZE_OVERALL_BG_HEIGHT + SIZE_OVERALL_INSTANCE * numRows);
end



-- ===========================================================================
-- SCIENCE

function PopulateScienceProgressMeters(instance:table, progressData:table)
    BASE_PopulateScienceProgressMeters(instance, progressData);
    
    -- Display progress on Exoplanet Expedition
    if (bIsGatheringStorm) then
        if ((progressData.projectProgresses[4] >= progressData.projectTotals[4]) and (progressData.projectTotals[4] ~= 0)) then
            local pPlayer = Players[progressData.playerID];
            local lightYears = pPlayer:GetStats():GetScienceVictoryPoints();
            local lightYearsPerTurn = pPlayer:GetStats():GetScienceVictoryPointsPerTurn();
            local totalLightYears = g_LocalPlayer:GetStats():GetScienceVictoryPointsTotalNeeded();
            if lightYears > totalLightYears then
                lightYears = totalLightYears;
            end

            instance.ObjBG_5:SetToolTipString(Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_IS_MOVING", lightYearsPerTurn).."[NEWLINE]"..Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_HAS_MOVED", lightYears, totalLightYears));
        end
    end
end



-- ===========================================================================
-- CULTURE

function GatherCultureData()
	--print("FUN GatherCultureData()");
	-- gather the data
	local data:table = BASE_GatherCultureData();
	--dshowrectable(data); -- debug
	-- data is ipairs table of team records
	--   team record: TeamID, BestNumRequiredTourists, BestNumVisitingUs, PlayerData:table
	--   PlayerData is ipairs table of single plater data: PlayerID, TurnsTillCulturalVictory, NumVisitingUs, NumStaycationers, NumRequiredTourists

	-- add more data - iterate through all players and add more data
	local localPlayer:number = Game.GetLocalPlayer();
	local playerCulture:table = Players[localPlayer]:GetCulture();
    -- 2021-06-08 Cultural Dominance
    --local iLocalVisitingTourists:number = playerCulture:GetTouristsTo();
    --local iLocalDomesticTourists:number = playerCulture:GetStaycationers();
	
	for _,teamData in ipairs(data) do
		--print("..team", teamData.TeamID);
		for _,playerData in ipairs(teamData.PlayerData) do
			local playerID:number = playerData.PlayerID;
			--print("....player", playerData.PlayerID);
			
			-- needed: is there TR, is open borders, tourism boost, etc.
			playerData.CulturePerTurn = Round(Players[playerID]:GetCulture():GetCultureYield(), 0);
			playerData.ToolTip = playerCulture:GetTouristsFromTooltip(playerID);
			playerData.TourismBoost = 0; -- percentage
			playerData.TradeRoute = false; -- is there a TR between us
			playerData.OpenBorders = Players[localPlayer]:GetDiplomacy():HasOpenBordersFrom(playerID); -- "you received open borders"
			playerData.TurnsTillNext = 999; -- turns till we attract the next visting tourist from this player
            playerData.ErrCurrent = false; -- issue with the TT analysis
            playerData.ErrLifetime = false; -- issue with the TT analysis
            -- 2021-06-08 Cultural Dominance
            --playerData.CulturalDominance    = ( iLocalVisitingTourists > Players[playerID]:GetCulture():GetStaycationers() );
            --playerData.CulturalSubservience = ( Players[playerID]:GetCulture():GetTouristsTo() > iLocalDomesticTourists );
            playerData.CulturalDominance    = playerCulture:IsDominantOver(playerID);
            playerData.CulturalSubservience = Players[playerID]:GetCulture():IsDominantOver(localPlayer);

			--if playerData.CulturePerTurn >= 100 then playerData.CulturePerTurn = Round(playerData.CulturePerTurn, 0);
			--else                                     playerData.CulturePerTurn = Round(playerData.CulturePerTurn, 1); end
			
			-- Determine if toPlayer has a trade route with fromPlayer (modified code from TradeOverview.lua)
			local function CheckTradeRoute(fromPlayer:number, toPlayer:number)
				if Players[toPlayer] == nil then return false; end -- assert
				for _,city in Players[toPlayer]:GetCities():Members() do
					if city:GetTrade():HasTradeRouteFrom(fromPlayer) then return true; end
				end
				return false;
			end
			-- Note: this is a two-way bonus, it doesn't matter who sends the TR
			--print("......checking TR", localPlayer, playerID);
			playerData.TradeRoute = ( CheckTradeRoute(localPlayer, playerID) or CheckTradeRoute(playerID, localPlayer) );
			
			-- calculate tourism boost modifier
			-- unfortunately it is not available via a simple call, needs to be retrieved from the tooltip
            --print("....TT:", playerData.ToolTip);
            --print(string.byte(playerData.ToolTip, 72, 82));
			--playerData.ToolTip = string.gsub(playerData.ToolTip, "[\128-\255]", "");
            -- there are some non-ASCII whitespaces inside that break pattern matching, need to trim them first
            local sTrimmedTT:string = "";
            for i = 1, #playerData.ToolTip do
                local ch:string = string.sub(playerData.ToolTip, i, i);
                if string.byte(ch) < 128 then sTrimmedTT = sTrimmedTT..ch; end
            end
            --print("....TT:", sTrimmedTT);
			local sCurrentT:string, sLifetimeT:string = string.match(sTrimmedTT, "([%d%.,]+)%D+([%d%.,]+)"); -- detects first 2 numbers, number may contain . or ,
			--print("....tourism string to player", playerID, sCurrentT, sLifetimeT);
            if sCurrentT  == nil then sCurrentT  = "0"; playerData.ErrCurrent  = true; end
            if sLifetimeT == nil then sLifetimeT = "0"; playerData.ErrLifetime = true; end
			sCurrentT  = string.gsub(sCurrentT, "%D",""); -- remove all non-digits, it returns 2 values, so cannot use directly with tonumber()
			sLifetimeT = string.gsub(sLifetimeT,"%D","");
			--print("....tourism string to player", playerID, sCurrentT, sLifetimeT);
			local iCurrentT:number, iLifetimeT:number = tonumber(sCurrentT), tonumber(sLifetimeT);
            if iCurrentT  == nil then iCurrentT  = 0; playerData.ErrCurrent  = true; end
            if iLifetimeT == nil then iLifetimeT = 0; playerData.ErrLifetime = true; end
			--print("....tourism number to player", playerID, iCurrentT, iLifetimeT);
            if iLifetimeT < iCurrentT then playerData.ErrLifetime = true; end
			local iTotalT:number = Players[localPlayer]:GetStats():GetTourism();
			if iTotalT > 0 then
				playerData.TourismBoost = Round((iCurrentT - iTotalT) * 100 / iTotalT, 0);
			end
			
			-- turns till the next one
			if iCurrentT > 0 then
				local iTouristsFrom:number = playerCulture:GetTouristsFrom(playerID);
				playerData.TurnsTillNext = ( (iTouristsFrom+1) * m_iTourismForOne - iLifetimeT ) / iCurrentT;
				--print("....turns till next", iTouristsFrom, iLifetimeT, playerData.TurnsTillNext);
				playerData.TurnsTillNext = math.floor(playerData.TurnsTillNext) + 1;
			end
		end
        
        -- Sort players within teams
        table.sort(teamData.PlayerData, function(a, b) return a.NumVisitingUs / a.NumRequiredTourists > b.NumVisitingUs / b.NumRequiredTourists; end);
	end
	
	return data;
end


-- playerData: PlayerID, TurnsTillCulturalVictory, NumVisitingUs, NumStaycationers, NumRequiredTourists
function PopulateCultureInstance(instance:table, playerData:table)
	--print("FUN PopulateCultureInstance()");
	--dshowrectable(playerData); -- debug
	BASE_PopulateCultureInstance(instance, playerData);
	
	-- better tooltip
	instance.VisitingUsTourists:SetToolTipString("");
	instance.VisitingUsIcon:SetToolTipString("");
	instance.VisitingUsContainer:SetToolTipString(playerData.ToolTip);
	
	-- new fields
	instance.CulturePerTurn:SetText( "[COLOR_Culture]"..tostring(playerData.CulturePerTurn).."[ENDCOLOR]" );
	instance.TradeRoute:SetText( playerData.TradeRoute and "[ICON_PROPOSE_TRADE]" or "[ICON_CheckFail]" );
	instance.OpenBorders:SetText( playerData.OpenBorders and "[ICON_OPEN_BORDERS]" or "[ICON_CheckFail]" );
	-- tourism boost
    if     playerData.ErrCurrent        then instance.TourismBoost:SetText("[COLOR_Red]![ENDCOLOR]");
    elseif playerData.TourismBoost == 0 then instance.TourismBoost:SetText("0%");
    elseif playerData.TourismBoost > 0  then instance.TourismBoost:SetText(string.format("[COLOR_GREEN]+%d%%[ENDCOLOR]", playerData.TourismBoost));
    else                                     instance.TourismBoost:SetText(string.format("[COLOR_RED]%d%%[ENDCOLOR]", playerData.TourismBoost));
    end
	-- turns till the next visiting tourist
    if playerData.ErrLifetime then
        instance.TurnsTillNext:SetText("[COLOR_Red]![ENDCOLOR]");
	elseif playerData.TurnsTillNext ~= 999 then
		--instance.TurnsTillNext:SetHide(false);
		instance.TurnsTillNext:SetText("[ICON_Turn]"..tostring(playerData.TurnsTillNext));
	else
		instance.TurnsTillNext:SetHide(true);
	end
    -- 2021-06-08 Cultural Dominance
    instance.CulturalDominance:SetHide(    not playerData.CulturalDominance    or playerData.PlayerID == Game.GetLocalPlayer() );
    instance.CulturalSubservience:SetHide( not playerData.CulturalSubservience or playerData.PlayerID == Game.GetLocalPlayer() );
end


function ViewCulture()
	--print("FUN ViewCulture");
	BASE_ViewCulture();
	
	-- new fields
	Controls.TourismForOne:SetText(Locale.Lookup("LOC_BWR_TOURISM_FOR_ONE", m_iTourismForOne));
end



-- ===========================================================================
-- SCORE

-- these categories will be shown by default, all that are not here will be shown as a tooltip
local tScoresMap:table = {
	CATEGORY_EMPIRE       = {"Score1", "[ICON_Citizen]"},
	CATEGORY_TECH         = {"Score2", "[ICON_Science]"},
	CATEGORY_CIVICS       = {"Score3", "[ICON_Culture]"},
	CATEGORY_GREAT_PEOPLE = {"Score4", "[ICON_GreatPerson]"},
	CATEGORY_RELIGION     = {"Score5", "[ICON_Religion]"},
	CATEGORY_WONDER       = {"Score6", "[ICON_Housing]"},
	CATEGORY_ERA_SCORE    = {"Score7", "[ICON_Turn]"},
};

-- overwrite fully so it functions as "always details"
function PopulateScoreInstance(instance:table, playerData:table)
	PopulatePlayerInstanceShared(instance, playerData.PlayerID);

	instance.Score:SetText(playerData.PlayerScore);

	ResizeLocalPlayerBorder(instance, 75 + 9); -- +SIZE_LOCAL_PLAYER_BORDER_PADDING but it is local

	local detailsText:string = "";
	for i, category in ipairs(playerData.Categories) do
		local categoryInfo:table = GameInfo.ScoringCategories[category.CategoryID];
		local sTT:string = Locale.Lookup(categoryInfo.Name) .. ": " .. category.CategoryScore;
		local tScoreRec:table = tScoresMap[ categoryInfo.CategoryType ];
		if tScoreRec ~= nil then
			-- display specific category
			instance[ tScoreRec[1] ]:SetText( tScoreRec[2]..tostring(category.CategoryScore) );
			instance[ tScoreRec[1] ]:SetToolTipString(sTT);
			instance[ tScoreRec[1] ]:SetHide(false);
		else
			-- all others go here
			if #detailsText > 0 then detailsText = detailsText.."[NEWLINE]"; end
			detailsText = detailsText..sTT;
		end
	end

	if #detailsText > 0 then
		instance.ScoreX:SetToolTipString(detailsText);
		instance.ScoreX:SetHide(false);
	else
		instance.ScoreX:SetHide(true);
	end
end


-- ===========================================================================
-- SHARED

function PopulateTeamInstanceShared(instance:table, teamID:number)
    BASE_PopulateTeamInstanceShared(instance, teamID);

    -- Update team name
	instance.TeamName:SetText(Locale.Lookup("LOC_WORLD_RANKINGS_TEAM", GameConfiguration.GetTeamName(teamID) + 1));
end


print("OK loaded WorldRankings_BWR.lua from Better World Rankings");