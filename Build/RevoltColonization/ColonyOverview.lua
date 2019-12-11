-- ColonyOverview
-- Author: Florian
-- DateCreated: 12/8/2019 12:10:09 PM
--------------------------------------------------------------
include( "IconSupport" );
include( "InstanceManager" );
include( "TechHelpInclude" );


local g_ColonyButton = InstanceManager:new( "ColonyButtonInstance", "ColonyButton", Controls.ColonyStack );

--=========================================================================================================
--How Many colonies do i have?
--=========================================================================================================
--[[
function NumColony(g_iPlayer)
local numColony = 0;
local g_iPlayer = Players[Game.GetActivePlayer()]
local player = Players[g_iPlayer];
local ColonyCity = player:CountNumBuildings(GameInfoTypes["BUILDING_JFD_GOVERNORS_MANSION"]);
if (ColonyCity == 0) then
numColony = 0;
print("NumColonyPersook1")
else
numColony = ColonyCity;
print("NumColonyPersook2")
end
return numColony
end
]]
--=========================================================================================================
--Open the UI Colony Overview
--=========================================================================================================
function OnOpeningColony()
	ContextPtr:SetHide(false)
end
--=========================================================================================================
--Close the UI Colony Overview
--=========================================================================================================
function OnClosingOK()
  ContextPtr:SetHide(true)
end
--=========================================================================================================
--Closethe UI Colony Overview
--=========================================================================================================

LuaEvents.AdditionalInformationDropdownGatherEntries.Add(function(entries)
table.insert(entries, {
	text = Locale.Lookup("TXT_KEY_COLONY_OVERVIEW"),
	--art = "DC45_Civics.dds", -- icon for EUI
	call = function() 
	    OnOpeningColony() -- function that opens the Popup.
	end,
});
end);

--=========================================================================================================
--Function that allows the use of keyboard as shortcut
--=========================================================================================================
function ColonyInputHandler( uiMsg, wParam, lParam )      
    if(uiMsg == KeyEvents.KeyDown) then
        if (wParam == Keys.VK_ESCAPE) then
			OnClosingOK()
			return true
        end
    end
end
ContextPtr:SetInputHandler( ColonyInputHandler )
--=========================================================================================================
--Function That Set the right icon in the top of the Colony overview's panel
--=========================================================================================================
function ShowHideHandler( bIsHide, bInitState )
	CivIconHookup( Game.GetActivePlayer(), 64, Controls.Icon, Controls.CivIconBG, Controls.CivIconShadow, false, true );
	if( not bInitState ) then
        if( not bIsHide ) then
		UI.incTurnTimerSemaphore();
		Update();
		else
		UI.decTurnTimerSemaphore();
		ResetColonyDescription();
		end
	end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

function TestColonyStarted()
local g_iPlayer = Players[Game.GetActivePlayer()]
local iTech = GameInfoTypes["TECH_COMPASS"]
local renaissance = GameInfo.Eras["ERA_RENAISSANCE"].ID
local tColonyStarted = false
	if g_iPlayer:GetCurrentEra() == renaissance then
	tColonyStarted = true;
	print("ColonyStart = vrai")
	else
	tColonyStarted = false
	print("ColonyStart = faux")
	end
	return tColonyStarted
end

--=========================================================================================================
--Managment of the content of the panel overview
--=========================================================================================================
function ResetColonyDescription()
	Controls.ColonyDescBox:SetHide(true);
end

function Update(g_iPlayer)
	-- Update active player
	local g_iPlayer = Players[Game.GetActivePlayer()]
	local player = Players[g_iPlayer];

	local bColonyStarted = TestColonyStarted();

	Controls.LabelColonyNotStartedYet:SetHide(TestColonyStarted() == true);
	Controls.OverviewPanel:SetHide(TestColonyStarted() == false);
	Controls.NumColonies:SetHide(TestColonyStarted() == false);
	Controls.NumColoniesWorld:SetHide(TestColonyStarted() == false);
	Controls.LabelNoColonies:SetHide( g_iPlayer:CountNumBuildings(GameInfoTypes["BUILDING_JFD_GOVERNORS_MANSION"]) ~= 0);

	if(bColonyStarted) then
		local iTotalColonies = 0;
		--How many colonies in the world
		for PlayerID = 0, GameDefines.MAX_MAJOR_CIVS - 1, 1 do
			if (Players[PlayerID] ~= nil) then
					local pPlayer = Players[PlayerID]
					local numColonies = pPlayer:CountNumBuildings(GameInfoTypes["BUILDING_JFD_GOVERNORS_MANSION"])
					iTotalColonies = iTotalColonies + numColonies
			end
		end
		Controls.NumColoniesWorld:LocalizeAndSetText( "TXT_KEY_NUM_WORLD_COLONIES", iTotalColonies );
		--How Many colonies do i have?
		Controls.NumColonies:LocalizeAndSetText( "TXT_KEY_NUM_OUR_COLONIES", g_iPlayer:CountNumBuildings(GameInfoTypes["BUILDING_JFD_GOVERNORS_MANSION"]) );


		-- Show Colony Information
			UpdateColonyList();
			g_SelectedColony = nil;
	end
end

--=========================================================================================================
--Update List if we have Colonies
--=========================================================================================================

function UpdateColonyList()
	local g_iPlayer = Players[Game.GetActivePlayer()]
	local player = Players[g_iPlayer];
	if (ContextPtr:IsHidden()) then
		return;
	end
	
	if (IsGameCoreBusy()) then
		return;
	end

	-- Clear buttons
	g_ColonyButton:ResetInstances();

	-- Add Colonies to stack
	for city in g_iPlayer:Cities() do
			if (city:IsColony() == true) then
			print("ColonyList colony targeted ok")
				-- Our colony?
					local controlTable = g_ColonyButton:GetInstance();

					controlTable.LeaderName:SetText( city:GetName() );

					--local cityPlayer = city:GetOwner();
					local civType = city:GetCivilizationType();
					local originalOwnerID = city:GetOriginalOwner();
					local originalCityOwner = Players[ originalOwnerID ]
					local originOwnerCiv = originalCityOwner:GetCivilizationType();
					local originOwnerCivInfo = GameInfo.Civilizations[civType];
					local civInfo = GameInfo.Civilizations[civType];
					local strCiv = Locale.ConvertTextKey(civInfo.ShortDescription);

					local otherLeaderType = originalCityOwner:GetLeaderType();
					local otherLeaderInfo = GameInfo.Leaders[otherLeaderType];

					controlTable.CivName:SetText(strCiv);
					IconHookup( otherLeaderInfo.PortraitIndex, 64, otherLeaderInfo.IconAtlas, controlTable.LeaderPortrait );
					--Function Selection of a Colony
					controlTable.ColonyButton:SetVoid1( city ); -- indicates type
					controlTable.ColonyButton:RegisterCallback( Mouse.eLClick, ColonySelected );
			end
	end
	Controls.ColonyStack:CalculateSize();

	Controls.ScrollPanel:CalculateInternalSize();
	Controls.ScrollPanel:ReprocessAnchoring();
end

--=========================================================================================================
--Update Colony Details when colony selected
--=========================================================================================================
function ColonySelected( city )

	if not Players[Game.GetActivePlayer()]:IsTurnActive() or Game.IsProcessingMessages() then
		return;
	end

	if( Controls.ColonyDescBox:IsHidden() ) then
		Controls.ColonyDescBox:SetHide(false);
	end
	--on recupère l'ID du joueur
	local g_iPlayer = Players[Game.GetActivePlayer()]
	local pColonyCity = g_iPlayer:GetCityByID(city);

	--ID du vassal selectionné
	g_SelectedColony = city;
	--quelle civilization à le vassal
	local civType = pColonyCity:GetCivilizationType();
	local originalOwnerID = pColonyCity:GetOriginalOwner();
	local originalCityOwner = Players[ originalOwnerID ]
	local originOwnerCiv = originalCityOwner:GetCivilizationType();
	local originOwnerCivInfo = GameInfo.Civilizations[civType];
	local civInfo = GameInfo.Civilizations[civType];
	local strCiv = Locale.ConvertTextKey(civInfo.ShortDescription);

	local otherLeaderType = originalCityOwner:GetLeaderType();
	local otherLeaderInfo = GameInfo.Leaders[otherLeaderType];
	
	--On met l'icon et le texte dans le details de la colonie
	Controls.ColonyInfoLeaderName:SetText( pColonyCity:GetName() );

	Controls.ColonyInfoCivName:SetText( strCiv );
	Controls.ColonyInfoStarted:LocalizeAndSetText("TXT_KEY_TURNS_ACQUIRED", Game.GetGameTurn() - pColonyCity:GetGameTurnAcquired()  , pColonyCity:GetGameTurnAcquired());

	-- Leader Portrait
	--local pLeader = GameInfo.Leaders[pColonyCity:GetLeaderType()];
	CivIconHookup( Game.GetActivePlayer(), 128, Controls.ColonySubIcon, Controls.ColonySubIconBG, Controls.ColonySubIconShadow, false, true );
	--IconHookup( originalCityOwner, 128, pLeader.IconAtlas, Controls.ColonyIcon );
	--CivIconHookup( otherLeaderInfo, 45, Controls.ColonySubIcon, Controls.ColonySubIconBG, Controls.ColonySubIconShadow, true, true, Controls.ColonySubIconHighlight );
	--[[
	-- Calculate percentage of current cities vs. what we had when vassalage started

	local iCityPercent = 0;
	local iPopPercent = 0;
	
	if( pVassalTeam:GetNumCitiesWhenVassalMade() ~= 0 ) then
		iCityPercent = math.floor(pVassalTeam:GetNumCities() * 100 / pVassalTeam:GetNumCitiesWhenVassalMade());
	else
		if( pVassalTeam:GetNumCities() == 0) then
			iCityPercent = 0;
		else
			iCityPercent = 100;
		end
	end
	if( pVassalTeam:GetTotalPopulationWhenVassalMade() ~= 0 ) then
		iPopPercent = math.floor(pVassalTeam:GetTotalPopulation() * 100 / pVassalTeam:GetTotalPopulationWhenVassalMade());
	else
		if( pVassalTeam:GetTotalPopulation() == 0) then
			iPopPercent = 0;
		else
			iPopPercent = 100;
		end
	end

	local iMasterCityPercent = 0;
	local iMasterPopPercent = 0;

	if( g_pTeam:GetNumCities() ~= 0) then
		iMasterCityPercent = math.floor(pVassalTeam:GetNumCities() * 100 / g_pTeam:GetNumCities());
	end
	if( g_pTeam:GetTotalPopulation() ~= 0) then
		iMasterPopPercent = math.floor(pVassalTeam:GetTotalPopulation() * 100 / g_pTeam:GetTotalPopulation());
	end

	local iMinimumTurns = 0;
	if( pVassalTeam:IsVoluntaryVassal(g_iTeam) ) then
		iMinimumTurns = Game.GetMinimumVoluntaryVassalTurns();
	else
		iMinimumTurns = Game.GetMinimumVassalTurns();
	end

	-- Build Independence tooltip
	local strIndependenceTooltip = g_pPlayer:GetVassalIndependenceTooltipAsMaster(ePlayer);

	local strIndependencePossible = "";
	if( pVassalTeam:CanEndVassal(g_iPlayer) ) then
		strIndependencePossible = "[COLOR_NEGATIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_DECLARE_WAR_YES") .. "[ENDCOLOR]";
	else 
		strIndependencePossible = "[COLOR_POSITIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_DECLARE_WAR_NO") .. "[ENDCOLOR]";
	end


	Controls.VassalInfoIndependence:LocalizeAndSetText( strIndependencePossible );
	Controls.VassalInfoIndependence:SetToolTipString(strIndependenceTooltip);

	Controls.VassalPercentMasterCities:LocalizeAndSetText( iMasterCityPercent .. "%" );
	Controls.VassalPercentMasterCities:LocalizeAndSetToolTip( "TXT_KEY_VO_MASTER_CITY_PERCENT_TT", pVassalTeam:GetNumCities(), g_pTeam:GetNumCities(), pVassalPlayer:GetNumCities() );
	Controls.VassalPercentMasterPop:LocalizeAndSetText( iMasterPopPercent .. "%" );
	Controls.VassalPercentMasterPop:LocalizeAndSetToolTip( "TXT_KEY_VO_MASTER_POP_PERCENT_TT", pVassalTeam:GetTotalPopulation(), g_pTeam:GetTotalPopulation(), pVassalPlayer:GetTotalPopulation() );

	Controls.VassalInfoCityPercent:LocalizeAndSetText( iCityPercent  .. "%");
	Controls.VassalInfoCityPercent:LocalizeAndSetToolTip("TXT_KEY_VO_CITY_PERCENT_TT", pVassalTeam:GetNumCities(), pVassalTeam:GetNumCitiesWhenVassalMade(), pVassalPlayer:GetNumCities());
	Controls.VassalInfoPopPercent:LocalizeAndSetText( iPopPercent  .. "%");
	Controls.VassalInfoPopPercent:LocalizeAndSetToolTip("TXT_KEY_VO_POP_PERCENT_TT", pVassalTeam:GetTotalPopulation(), pVassalTeam:GetTotalPopulationWhenVassalMade(), pVassalPlayer:GetTotalPopulation());

	local strType, strTypeTooltip;
	if( pVassalTeam:IsVoluntaryVassal( g_iTeam ) ) then
		strType = Locale.ConvertTextKey( "TXT_KEY_VO_VASSAL_TYPE_VOLUNTARY" );
		strTypeTooltip = Locale.ConvertTextKey( "TXT_KEY_VO_VASSAL_TYPE_VOLUNTARY_TT" );
	else
		strType = Locale.ConvertTextKey( "TXT_KEY_VO_VASSAL_TYPE_CAPITULATED" );
		strTypeTooltip = Locale.ConvertTextKey( "TXT_KEY_VO_VASSAL_TYPE_CAPITULATED_TT" );
	end

	Controls.VassalInfoType:LocalizeAndSetText(strType);
	Controls.VassalInfoType:LocalizeAndSetToolTip(strTypeTooltip);

	Controls.TaxSlider:SetValue( TaxValueToPercent( g_pTeam:GetVassalTax( ePlayer ) ) );
	
	local iNumTurnsForTax = Game.GetMinimumVassalTaxTurns();
	local iNumTurnsSinceSet = g_pTeam:GetNumTurnsSinceVassalTaxSet( ePlayer );
	local iNumTurnsLeft = iNumTurnsForTax - iNumTurnsSinceSet;

	if( not g_pTeam:CanSetVassalTax( ePlayer ) ) then
		Controls.TaxSlider:SetDisabled( true );
		Controls.TaxSliderValueToolTip:LocalizeAndSetToolTip( "TXT_KEY_VO_TAX_TOO_SOON", iNumTurnsForTax, iNumTurnsLeft );
	else
		Controls.TaxSlider:SetDisabled( false );
		Controls.TaxSliderValueToolTip:SetToolTipString( "" );
	end
	
	local iTurnTaxesSet = Game.GetGameTurn() - iNumTurnsSinceSet;
	local iTurnTaxesAvailable = Game.GetGameTurn() + iNumTurnsLeft;
	local availableStr = "";
	local taxesSetTurnStr = "";
	if ( iNumTurnsLeft <= 0 or iNumTurnsSinceSet == -1 ) then
		availableStr = Locale.ConvertTextKey("TXT_KEY_VO_TAX_CHANGE_READY");
	else
		availableStr = Locale.ConvertTextKey("TXT_KEY_VO_TAX_TURN_AVAILABLE", iTurnTaxesAvailable);
	end

	if ( g_pTeam:GetNumTurnsSinceVassalTaxSet( ePlayer ) == -1 ) then	
		taxesSetTurnStr = Locale.ConvertTextKey("TXT_KEY_VO_TAX_TURN_NOT_SET_EVER");
	else
		taxesSetTurnStr = Locale.ConvertTextKey("TXT_KEY_VO_TAX_TURN_SET", iTurnTaxesSet);
	end

	Controls.TaxesCurrentGPT:LocalizeAndSetText("TXT_KEY_VO_TAX_CONTRIBUTION", g_pPlayer:GetVassalTaxContribution(ePlayer));
	Controls.TaxesCurrentGPT:LocalizeAndSetToolTip("TXT_KEY_VO_TAX_GPT_RECEIVED_TT", g_pPlayer:GetVassalTaxContribution(ePlayer), g_pTeam:GetVassalTax( ePlayer), pVassalPlayer:CalculateGrossGold());

	Controls.TaxesTurnSet:SetText(taxesSetTurnStr);
	Controls.TaxesAvailableTurn:SetText(availableStr);
	Controls.TaxSliderValue:LocalizeAndSetText("TXT_KEY_VO_TAX_RATE", g_pTeam:GetVassalTax( ePlayer ) );

	DoVassalStatistics( ePlayer );
	UpdateVassalTreatment( ePlayer );

	Controls.ApplyChanges:SetDisabled( true );
	Controls.ApplyChanges:SetVoid1( ePlayer );
	Controls.ApplyChanges:RegisterCallback( Mouse.eLClick, OnApplyChangesClicked );
	Controls.ApplyChanges:LocalizeAndSetToolTip( "TXT_KEY_APPLY_CHANGES_TT" );

	-- Liberate Vassal button
	local tooltipStr = Locale.ConvertTextKey("TXT_KEY_VO_LIBERATE_VASSAL_TT", pVassalTeam:GetName());
	if( not g_pTeam:CanLiberateVassal( iVassalTeam ) ) then
		Controls.LiberateCiv:SetDisabled( true );
		tooltipStr = tooltipStr .. "[NEWLINE][NEWLINE]" .. Locale.ConvertTextKey("TXT_KEY_VO_LIBERATE_VASSAL_TOO_SOON", Game.GetMinimumVassalLiberateTurns(), Game.GetMinimumVassalLiberateTurns() - pVassalTeam:GetNumTurnsIsVassal( g_iTeam ));
	else
		Controls.LiberateCiv:SetDisabled( false );
	end

	Controls.LiberateCiv:SetToolTipString( tooltipStr );
	Controls.LiberateCiv:SetVoid1( iVassalTeam );
	Controls.LiberateCiv:RegisterCallback( Mouse.eLClick, OnLiberateCivClicked );

	Controls.StatsScrollPanel:CalculateInternalSize();
	Controls.StatsScrollPanel:ReprocessAnchoring();

	Controls.ManagementScrollPanel:CalculateInternalSize();
	Controls.ManagementScrollPanel:ReprocessAnchoring();
	]]
end



	LuaEvents.RequestRefreshAdditionalInformationDropdownEntries();
	ContextPtr:SetHide(true);