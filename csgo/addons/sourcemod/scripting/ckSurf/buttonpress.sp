 //Start stage record timer
public void CL_OnStageTimerPress(int client) {
	if (!IsFakeClient(client))
	{
		if (IsValidClient(client))
		{
			if (!g_bServerDataLoaded)
			{
				if (GetGameTime() - g_fErrorMessage[client] > 1.0)
				{
					PrintToChat(client, "[%cCK%c] The server hasn't finished loading it's settings, please wait.", MOSSGREEN, WHITE);
					ClientCommand(client, "play buttons\\button10.wav");
					g_fErrorMessage[client] = GetGameTime();
				}
				return;
			}
			else if (g_bLoadingSettings[client])
			{
				if (GetGameTime() - g_fErrorMessage[client] > 1.0)
				{
					PrintToChat(client, "[%cCK%c] Your settings are currently being loaded, please wait.", MOSSGREEN, WHITE);
					ClientCommand(client, "play buttons\\button10.wav");
					g_fErrorMessage[client] = GetGameTime();
				}
				return;
			}
			else if (!g_bSettingsLoaded[client])
			{
				if (GetGameTime() - g_fErrorMessage[client] > 1.0)
				{
					PrintToChat(client, "[%cCK%c] The server hasn't finished loading your settings, please wait.", MOSSGREEN, WHITE);
					ClientCommand(client, "play buttons\\button10.wav");
					g_fErrorMessage[client] = GetGameTime();
				}
				return;
			}
		}
		if (g_bNewReplay[client] || g_bNewBonus[client]) // Don't allow starting the timer, if players record is being saved
			return;
	}
	
	//Reset stage variables for client
	g_stageStartTime[client] = GetGameTime();
	g_stageFinalTime[client] = 0.0;
	g_stageTimerActivated[client] = true;
	
}


// Start timer
public void CL_OnStartTimerPress(int client)
{
	if (!IsFakeClient(client))
	{
		if (IsValidClient(client))
		{
			if (!g_bServerDataLoaded)
			{
				if (GetGameTime() - g_fErrorMessage[client] > 1.0)
				{
					PrintToChat(client, "[%cCK%c] The server hasn't finished loading it's settings, please wait.", MOSSGREEN, WHITE);
					ClientCommand(client, "play buttons\\button10.wav");
					g_fErrorMessage[client] = GetGameTime();
				}
				return;
			}
			else if (g_bLoadingSettings[client])
			{
				if (GetGameTime() - g_fErrorMessage[client] > 1.0)
				{
					PrintToChat(client, "[%cCK%c] Your settings are currently being loaded, please wait.", MOSSGREEN, WHITE);
					ClientCommand(client, "play buttons\\button10.wav");
					g_fErrorMessage[client] = GetGameTime();
				}
				return;
			}
			else if (!g_bSettingsLoaded[client])
			{
				if (GetGameTime() - g_fErrorMessage[client] > 1.0)
				{
					PrintToChat(client, "[%cCK%c] The server hasn't finished loading your settings, please wait.", MOSSGREEN, WHITE);
					ClientCommand(client, "play buttons\\button10.wav");
					g_fErrorMessage[client] = GetGameTime();
				}
				return;
			}
		}
		if (g_bNewReplay[client] || g_bNewBonus[client]) {  // Don't allow starting the timer, if players record is being saved
			return;
		}
	}
	
	if (!g_bSpectate[client] && !g_bNoClip[client] && ((GetGameTime() - g_fLastTimeNoClipUsed[client]) > 2.0))
	{
		if (g_bActivateCheckpointsOnStart[client])
			g_bCheckpointsEnabled[client] = true;
		
		// Reset run variables
		tmpDiff[client] = 9999.0;
		g_fPauseTime[client] = 0.0;
		g_fStartPauseTime[client] = 0.0;
		g_bPause[client] = false;
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityRenderMode(client, RENDER_NORMAL);
		g_fStartTime[client] = GetGameTime();
		g_fCurrentRunTime[client] = 0.0;
		g_bPositionRestored[client] = false;
		g_bMissedMapBest[client] = true;
		g_bMissedBonusBest[client] = true;
		g_bTimeractivated[client] = true;
		
		if (!IsFakeClient(client))
		{
			// Reset checkpoint times
			for (int i = 0; i < CPLIMIT; i++)
			g_fCheckpointTimesNew[g_iClientInZone[client][2]][client][i] = 0.0;
			
			// Set missed record time variables
			if (g_iClientInZone[client][2] == 0)
			{
				if (g_fPersonalRecord[client] > 0.0)
					g_bMissedMapBest[client] = false;
			}
			else
			{
				if (g_fPersonalRecordBonus[g_iClientInZone[client][2]][client] > 0.0)
					g_bMissedBonusBest[client] = false;
				
			}
			
			// If starting the timer for the first time, print average times
			if (g_bFirstTimerStart[client])
			{
				g_bFirstTimerStart[client] = false;
				Client_Avg(client, 0);
			}
		}
	}
	
	// Play start sound
	PlayButtonSound(client);
	
	// Start recording for record bot
	if ((!IsFakeClient(client) && GetConVarBool(g_hReplayBot)) || (!IsFakeClient(client) && GetConVarBool(g_hBonusBot)))
	{
		if (g_hRecording[client] != null)
		{
			StopRecording(client);
		}
		if (IsPlayerAlive(client) || GetClientTeam(client) > 1) // player must be alive and in a valid team (2 or 3)
		{
			StartRecording(client);
		}
	}
}

// End timer
public void CL_OnEndTimerPress(int client)
{
	if (!IsValidClient(client))
		return;
	
	float endTime = GetGameTime();
	char clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));
	// Print bot finishing message to spectators
	if (IsFakeClient(client) && g_bTimeractivated[client])
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && !IsPlayerAlive(i))
			{
				int SpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
				if (SpecMode == 4 || SpecMode == 5)
				{
					int Target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
					if (Target == client)
					{
						if (Target == g_RecordBot)
							PrintToChat(i, "%t", "ReplayFinishingMsg", MOSSGREEN, WHITE, LIMEGREEN, g_szReplayName, GRAY, LIMEGREEN, g_szReplayTime, GRAY);
						if (Target == g_BonusBot)
							PrintToChat(i, "%t", "ReplayFinishingMsgBonus", MOSSGREEN, WHITE, LIMEGREEN, g_szBonusName, GRAY, YELLOW, g_szZoneGroupName[g_iClientInZone[g_BonusBot][2]], GRAY, LIMEGREEN, g_szBonusTime, GRAY);
					}
				}
			}
		}
		g_bTimeractivated[client] = false;
		PlayButtonSound(client);
		return;
	}
	
	// If timer is not on, play error sound and return
	if (!g_bTimeractivated[client])
	{
		ClientCommand(client, "play buttons\\button10.wav");
		return;
	}
	
	PlayButtonSound(client);
	
	// Get client name
	//char szName[MAX_NAME_LENGTH];
	//GetClientName(client, szName, MAX_NAME_LENGTH);
	
	// Get runtime and format it to a string
	g_fFinalTime[client] = endTime - g_fStartTime[client] - g_fPauseTime[client];
	
	FormatTimeFloat(client, g_fFinalTime[client], 3, g_szFinalTime[client], 32);
	
	/*============================================
	=            Handle practice mode            =
	============================================*/
	if (g_bPracticeMode[client])
	{
		if (g_iClientInZone[client][2] > 0)
			PrintToChat(client, "[%cCK%c] %c%N %cfinished the bonus with a time of [%c%s%c] in practice mode!", MOSSGREEN, WHITE, MOSSGREEN, client, WHITE, LIGHTBLUE, g_szFinalTime[client], WHITE);
		else
			PrintToChat(client, "[%cCK%c] %c%N %cfinished the map with a time of [%c%s%c] in practice mode!", MOSSGREEN, WHITE, MOSSGREEN, client, WHITE, LIGHTBLUE, g_szFinalTime[client], WHITE);
		
		/* Start function call */
		Call_StartForward(g_PracticeFinishForward);
		
		/* Push parameters one at a time */
		Call_PushCell(client);
		Call_PushFloat(g_fFinalTime[client]);
		Call_PushString(g_szFinalTime[client]);
		
		/* Finish the call, get the result */
		Call_Finish();
		
		return;
	}
	
	// Set "Map Finished" overlay panel
	g_bOverlay[client] = true;
	g_fLastOverlay[client] = endTime;
	PrintHintText(client, "%t", "TimerStopped", g_szFinalTime[client]);
	
	// Get Zonegroup
	int zGroup = g_iClientInZone[client][2];
	
	/*==========================================
	=            Handling map times            =
	==========================================*/
	if (zGroup == 0)
	{
		// Make a new record bot?
		if (GetConVarBool(g_hReplaceReplayTime) && (g_fFinalTime[client] < g_fReplayTimes[0] || g_fReplayTimes[0] <= 0.1)) //never compare floats
		{
			if (GetConVarBool(g_hReplayBot) && !g_bPositionRestored[client]) //if the replay bot is enabled and the client's position wasn't restored upon joining
			{
				g_fReplayTimes[0] = g_fFinalTime[client];
				g_bNewReplay[client] = true;
				CreateTimer(3.0, ReplayTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		
		char szDiff[54];
		float diff;
		
		// Record bools init
		g_bMapFirstRecord[client] = false;
		g_bMapPBRecord[client] = false;
		g_bMapSRVRecord[client] = false;
		
		g_OldMapRank[client] = g_MapRank[client];
		
		diff = g_fPersonalRecord[client] - g_fFinalTime[client];
		FormatTimeFloat(client, diff, 3, szDiff, sizeof(szDiff));
		if (diff > 0.0)
			Format(g_szTimeDifference[client], sizeof(szDiff), "-%s", szDiff);
		else
			Format(g_szTimeDifference[client], sizeof(szDiff), "+%s", szDiff);
		
		// Check for SR, even if there isn't one already
		if (!g_MapTimesCount || g_fFinalTime[client] < g_fRecordMapTime)
		{  // New fastest time in map
			g_bMapSRVRecord[client] = true;
			g_fRecordMapTime = g_fFinalTime[client];
			Format(g_szRecordPlayer, MAX_NAME_LENGTH, "%N", client);
			FormatTimeFloat(1, g_fRecordMapTime, 3, g_szRecordMapTime, 64);
			// Insert latest record
			db_InsertLatestRecords(g_szSteamID[client], clientName, g_fFinalTime[client]);
			// Update Checkpoints
			if (g_bCheckpointsEnabled[client] && !g_bPositionRestored[client])
			{
				for (int i = 0; i < CPLIMIT; i++)
				{
					g_fCheckpointServerRecord[zGroup][i] = g_fCheckpointTimesNew[zGroup][client][i];
				}
				g_bCheckpointRecordFound[zGroup] = true;
			}
			
			if (GetConVarBool(g_hReplayBot) && !g_bPositionRestored[client] && !g_bNewReplay[client])
			{
				g_bNewReplay[client] = true;
				g_fReplayTimes[0] = g_fFinalTime[client];
				CreateTimer(3.0, ReplayTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		
		// Check for personal record
		if (g_fPersonalRecord[client] <= 0.1)
		{  // Clients first record
			g_fPersonalRecord[client] = g_fFinalTime[client];
			g_pr_finishedmaps[client]++;
			g_MapTimesCount++;
			FormatTimeFloat(1, g_fPersonalRecord[client], 3, g_szPersonalRecord[client], 64);
			
			g_bMapFirstRecord[client] = true;
			g_pr_showmsg[client] = true;
			db_UpdateCheckpoints(client, g_szSteamID[client], zGroup);
			db_selectRecord(client);
		}
		else if (diff > 0.0)
		{  // Client's new record
			g_fPersonalRecord[client] = g_fFinalTime[client];
			g_MapTimesCount++;
			if (GetConVarInt(g_hExtraPoints) > 0)
				g_pr_multiplier[client] += 1; // Improved time, increase multip (how many times the player finished this map)
			FormatTimeFloat(1, g_fPersonalRecord[client], 3, g_szPersonalRecord[client], 64);
			
			g_bMapPBRecord[client] = true;
			g_pr_showmsg[client] = true;
			db_UpdateCheckpoints(client, g_szSteamID[client], zGroup);
			
			db_selectRecord(client);
			
		}
		
		if (!g_bMapSRVRecord[client] && !g_bMapFirstRecord[client] && !g_bMapPBRecord[client])
		{
			// for ck_min_rank_announce
			db_currentRunRank(client);
		}
		
		
		//Challenge
		if (g_bChallenge[client])
		{
			char opponentName[MAX_NAME_LENGTH];
			
			SetEntityRenderColor(client, 255, 255, 255, 255);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && i != client && i != g_RecordBot && i != g_BonusBot)
				{
					if (StrEqual(g_szSteamID[i], g_szChallenge_OpponentID[client]))
					{
						g_bChallenge[client] = false;
						g_bChallenge[i] = false;
						SetEntityRenderColor(i, 255, 255, 255, 255);
						db_insertPlayerChallenge(client);
						GetClientName(i, opponentName, MAX_NAME_LENGTH);
						//for (int k = 1; k <= MaxClients; k++)
						//	if (IsValidClient(k))
						PrintToChatAll("%t", "ChallengeW", RED, WHITE, MOSSGREEN, clientName, WHITE, MOSSGREEN, opponentName, WHITE);
						
						if (g_Challenge_Bet[client] > 0)
						{
							int lostpoints = g_Challenge_Bet[client] * g_pr_PointUnit;
							//for (int j = 1; j <= MaxClients; j++)
							//	if (IsValidClient(j))
							PrintToChatAll("%t", "ChallengeL", MOSSGREEN, WHITE, PURPLE, opponentName, GRAY, RED, lostpoints, GRAY);
							CreateTimer(0.5, UpdatePlayerProfile, i, TIMER_FLAG_NO_MAPCHANGE);
							g_pr_showmsg[client] = true;
						}
						
						break;
					}
				}
			}
		}
		CS_SetClientAssists(client, 100);
	}
	else
		/*====================================
	=            Handle bonus            =
	====================================*/
	{
		if (GetConVarBool(g_hReplaceReplayTime) && (g_fFinalTime[client] < g_fReplayTimes[zGroup] || g_fReplayTimes[zGroup] <= 0.1)) //never compare floats
		{
			if (GetConVarBool(g_hBonusBot) && !g_bPositionRestored[client])
			{
				g_fReplayTimes[zGroup] = g_fFinalTime[client];
				g_bNewBonus[client] = true;
				Handle pack;
				CreateDataTimer(3.0, BonusReplayTimer, pack);
				WritePackCell(pack, GetClientUserId(client));
				WritePackCell(pack, zGroup);
			}
		}
		char szDiff[54];
		float diff;
		
		// Record bools init
		g_bBonusFirstRecord[client] = false;
		g_bBonusPBRecord[client] = false;
		g_bBonusSRVRecord[client] = false;
		
		g_OldMapRankBonus[zGroup][client] = g_MapRankBonus[zGroup][client];
		
		diff = g_fPersonalRecordBonus[zGroup][client] - g_fFinalTime[client];
		FormatTimeFloat(client, diff, 3, szDiff, sizeof(szDiff));
		if (diff > 0.0)
			Format(g_szBonusTimeDifference[client], sizeof(szDiff), "-%s", szDiff);
		else
			Format(g_szBonusTimeDifference[client], sizeof(szDiff), "+%s", szDiff);
		
		
		g_tmpBonusCount[zGroup] = g_iBonusCount[zGroup];
		
		if (g_iBonusCount[zGroup] > 0)
		{  // If the server already has a record
			if (g_fFinalTime[client] < g_fBonusFastest[zGroup])
			{  // New fastest time in current bonus
				g_fOldBonusRecordTime[zGroup] = g_fBonusFastest[zGroup];
				g_fBonusFastest[zGroup] = g_fFinalTime[client];
				Format(g_szBonusFastest[zGroup], MAX_NAME_LENGTH, "%N", client);
				FormatTimeFloat(1, g_fBonusFastest[zGroup], 3, g_szBonusFastestTime[zGroup], 64);
				
				// Update Checkpoints
				if (g_bCheckpointsEnabled[client] && !g_bPositionRestored[client])
				{
					for (int i = 0; i < CPLIMIT; i++)
					{
						g_fCheckpointServerRecord[zGroup][i] = g_fCheckpointTimesNew[zGroup][client][i];
					}
					g_bCheckpointRecordFound[zGroup] = true;
				}
				
				g_bBonusSRVRecord[client] = true;
				if (GetConVarBool(g_hBonusBot) && !g_bPositionRestored[client] && !g_bNewBonus[client])
				{
					g_bNewBonus[client] = true;
					g_fReplayTimes[zGroup] = g_fFinalTime[client];
					Handle pack;
					CreateDataTimer(3.0, BonusReplayTimer, pack);
					WritePackCell(pack, GetClientUserId(client));
					WritePackCell(pack, zGroup);
				}
			}
		}
		else
		{  // Has to be the new record, since it is the first completion
			if (GetConVarBool(g_hBonusBot) && !g_bPositionRestored[client] && !g_bNewBonus[client])
			{
				g_bNewBonus[client] = true;
				g_fReplayTimes[zGroup] = g_fFinalTime[client];
				Handle pack;
				CreateDataTimer(3.0, BonusReplayTimer, pack);
				WritePackCell(pack, GetClientUserId(client));
				WritePackCell(pack, zGroup);
			}
			
			g_fOldBonusRecordTime[zGroup] = g_fBonusFastest[zGroup];
			g_fBonusFastest[zGroup] = g_fFinalTime[client];
			Format(g_szBonusFastest[zGroup], MAX_NAME_LENGTH, "%N", client);
			FormatTimeFloat(1, g_fBonusFastest[zGroup], 3, g_szBonusFastestTime[zGroup], 64);
			
			// Update Checkpoints
			if (g_bCheckpointsEnabled[client] && !g_bPositionRestored[client])
			{
				for (int i = 0; i < CPLIMIT; i++)
				{
					g_fCheckpointServerRecord[zGroup][i] = g_fCheckpointTimesNew[zGroup][client][i];
				}
				g_bCheckpointRecordFound[zGroup] = true;
			}
			
			g_bBonusSRVRecord[client] = true;
			
			g_fOldBonusRecordTime[zGroup] = g_fBonusFastest[zGroup];
		}
		
		
		if (g_fPersonalRecordBonus[zGroup][client] == 0.0)
		{  // Clients first record
			g_fPersonalRecordBonus[zGroup][client] = g_fFinalTime[client];
			FormatTimeFloat(1, g_fPersonalRecordBonus[zGroup][client], 3, g_szPersonalRecordBonus[zGroup][client], 64);
			
			g_bBonusFirstRecord[client] = true;
			g_pr_showmsg[client] = true;
			db_UpdateCheckpoints(client, g_szSteamID[client], zGroup);
			db_insertBonus(client, g_szSteamID[client], clientName, g_fFinalTime[client], zGroup);
		}
		else if (diff > 0.0)
		{  // client's new record
			g_fPersonalRecordBonus[zGroup][client] = g_fFinalTime[client];
			FormatTimeFloat(1, g_fPersonalRecordBonus[zGroup][client], 3, g_szPersonalRecordBonus[zGroup][client], 64);
			
			g_bBonusPBRecord[client] = true;
			g_pr_showmsg[client] = true;
			db_UpdateCheckpoints(client, g_szSteamID[client], zGroup);
			db_updateBonus(client, g_szSteamID[client], clientName, g_fFinalTime[client], zGroup);
		}
		
		
		if (!g_bBonusSRVRecord[client] && !g_bBonusFirstRecord[client] && !g_bBonusPBRecord[client])
		{
			db_currentBonusRunRank(client, zGroup);
			/*/ / Not any kind of a record
			if (GetConVarInt(g_hAnnounceRecord) == 0 && (g_MapRankBonus[zGroup][client] <= GetConVarInt(g_hAnnounceRank) || GetConVarInt(g_hAnnounceRank) == 0))
				PrintToChatAll("%t", "BonusFinished1", MOSSGREEN, WHITE, LIMEGREEN, szName, GRAY, YELLOW, g_szZoneGroupName[zGroup], GRAY, RED, szTime, GRAY, RED, szDiff, GRAY, LIMEGREEN, g_MapRankBonus[zGroup][client], GRAY, g_iBonusCount[zGroup], LIMEGREEN, g_szBonusFastestTime[zGroup], GRAY);
			else
			{
				if (IsValidClient(client))
					PrintToChat(client, "%t", "BonusFinished1", MOSSGREEN, WHITE, LIMEGREEN, szName, GRAY, YELLOW, g_szZoneGroupName[zGroup], GRAY, RED, szTime, GRAY, RED, szDiff, GRAY, LIMEGREEN, g_MapRankBonus[zGroup][client], GRAY, g_iBonusCount[zGroup], LIMEGREEN, g_szBonusFastestTime[zGroup], GRAY);
			}  */ 
		}
	}
	
	/*====================================
	=            Handle Stage            =
	====================================*/
	//Record bools init
	if (g_stageTimerActivated[client]) {
		char szDiff[54];
		float diff;
		g_stageFirstRecord[client] = false;
		g_stagePBRecord[client] = false;
		g_stageSRVRecord[client] = false;
		g_OldMapRankStage[zGroup][client] = g_MapRankStage[zGroup][client];
		
		diff = g_fPersonalRecordBonus[zGroup][client] - g_stageFinalTime[client];
		FormatTimeFloat(client, diff, 3, szDiff, sizeof(szDiff));
		if (diff > 0.0) {
			Format(g_szStageTimeDifference[client], sizeof(szDiff), "-%s", szDiff);
		}
		else {
			Format(g_szStageTimeDifference[client], sizeof(szDiff), "+%s", szDiff);
		}
		
		if (g_iStageCount[zGroup] > 0)
		{  // If the server already has a stage record
			if (g_stageFinalTime[client] < g_stageFastest[zGroup])
			{  // New fastest time in current bonus
				g_fOldStageRecordTime[zGroup] = g_stageFastest[zGroup];
				g_stageFastest[zGroup] = g_stageFinalTime[client];
				Format(g_szStageFastest[zGroup], MAX_NAME_LENGTH, "%N", client);
				FormatTimeFloat(1, g_stageFastest[zGroup], 3, g_szStageFastestTime[zGroup], 64);
				
				g_stageSRVRecord[client] = true;
			}
		} else {  // Has to be the new record, since it is the first completion
			g_fOldStageRecordTime[zGroup] = g_stageFastest[zGroup];
			g_stageFastest[zGroup] = g_stageFinalTime[client];
			Format(g_szBonusFastest[zGroup], MAX_NAME_LENGTH, "%N", client);
			FormatTimeFloat(1, g_stageFastest[zGroup], 3, g_szStageFastestTime[zGroup], 64);
			PrintToChat(client, "[%cCK%c] Terminaste la stage en %s", MOSSGREEN, WHITE, g_stageFinalTimeStr[client]);
			g_stageSRVRecord[client] = true;
			g_fOldStageRecordTime[zGroup] = g_stageFastest[zGroup];
		}
		
		
	}
	
	
	
	//set mvp star
	g_MVPStars[client] += 1;
	CS_SetMVPCount(client, g_MVPStars[client]);
}




// End timer
public void CL_OnEndStageTimerPress(int client)
{
	if (!IsValidClient(client))
		return;
	
	if (!g_stageTimerActivated[client])
	{
		ClientCommand(client, "play buttons\\button10.wav");
		return;
	}
	else
	{
		PlayButtonSound(client);
	}
	
	// Get client name
	char szName[MAX_NAME_LENGTH];
	GetClientName(client, szName, MAX_NAME_LENGTH);
	
	// Get runtime and format it to a string
	g_stageFinalTime[client] = GetGameTime() - g_stageStartTime[client];
	FormatTimeFloat(client, g_stageFinalTime[client], 3, g_stageFinalTimeStr[client], 32);
	
	
	// Get Zonegroup (Ejemplo bonus 1, 2, 3, etc)
	int zGroup = g_iClientInZone[client][2];
	
	//LO QUE NECESITO ES ZONETYPEID +1 Y CONSIGO EN QUE STAGE ESTA :D
	
	/*====================================
	=            Handle Stage            =
	====================================*/
	//Record bools init
	if (g_stageTimerActivated[client]) {
		char szDiff[54];
		float diff;
		g_stageFirstRecord[client] = false;
		g_stagePBRecord[client] = false;
		g_stageSRVRecord[client] = false;
		g_OldMapRankStage[zGroup][client] = g_MapRankStage[zGroup][client];
		
		diff = g_fPersonalRecordBonus[zGroup][client] - g_stageFinalTime[client];
		FormatTimeFloat(client, diff, 3, szDiff, sizeof(szDiff));
		if (diff > 0.0) {
			Format(g_szStageTimeDifference[client], sizeof(szDiff), "-%s", szDiff);
		}
		else {
			Format(g_szStageTimeDifference[client], sizeof(szDiff), "+%s", szDiff);
		}
		
		if (g_iStageCount[zGroup] > 0)
		{  // If the server already has a stage record
			if (g_stageFinalTime[client] < g_stageFastest[zGroup])
			{  // New fastest time in current bonus
				g_fOldStageRecordTime[zGroup] = g_stageFastest[zGroup];
				g_stageFastest[zGroup] = g_stageFinalTime[client];
				Format(g_szStageFastest[zGroup], MAX_NAME_LENGTH, "%s", szName);
				FormatTimeFloat(1, g_stageFastest[zGroup], 3, g_szStageFastestTime[zGroup], 64);
				
				g_stageSRVRecord[client] = true;
			}
		} else {  // Has to be the new record, since it is the first completion
			g_fOldStageRecordTime[zGroup] = g_stageFastest[zGroup];
			g_stageFastest[zGroup] = g_stageFinalTime[client];
			Format(g_szStageFastest[zGroup], MAX_NAME_LENGTH, "%s", szName);
			FormatTimeFloat(1, g_stageFastest[zGroup], 3, g_szStageFastestTime[zGroup], 64);
			PrintToChat(client, "[%cCK%c] Terminaste la stage en %s, zonegroup %i", MOSSGREEN, WHITE, g_stageFinalTimeStr[client], g_doingStage[client]);
			g_stageSRVRecord[client] = true;
			g_fOldStageRecordTime[zGroup] = g_stageFastest[zGroup];
		}
		
		
	}
	
	
	
	//set mvp star
	g_MVPStars[client] += 1;
	CS_SetMVPCount(client, g_MVPStars[client]);
} 