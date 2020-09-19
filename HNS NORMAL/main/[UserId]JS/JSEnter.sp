#define FONTCOLOR_WHITE "Last Jump: <font color='#727878'>%.1f</font>"
#define FONTCOLOR_BLUE "Last Jump: <font color='#333cb8'>%.1f</font>"
#define FONTCOLOR_GREEN "Last Jump: <font color='#00ff26'>%.1f</font>"
#define FONTCOLOR_RED "Last Jump: <font color='#ff0000'>%.1f</font>"
#define FONTCOLOR_YELLOW "Last Jump: <font color='#f6ff00'>%.1f</font>"
#define FONTCOLOR_KEYS "<font color='#bcd5eb'>"
#define JSCTDISABLE "<font color='#c7b585'>"

#define FONTCOLOR_DEFAULT "<font color='#bfc0c9'>"


public void OnMapStart()
{
	PrecacheSound(Green_PLAY , true);
	AddFileToDownloadsTable(Green_DOWNLOAD );
	PrecacheSound(Red_PLAY, true);
	AddFileToDownloadsTable(Red_DOWNLOAD);
	PrecacheSound(Yellow_PLAY, true);
	AddFileToDownloadsTable(Yellow_DOWNLOAD);
	PrecacheSound(RAMPAGE_PLAY, true);
	AddFileToDownloadsTable(RAMPAGE_DOWNLOAD);
}

public Action Timer_JS(Handle timer, any data)
{
	for (int client = 1; client <= MaxClients; client++) 
	{
		if(IsValidClient(client))
			if(IsUserIdLoadedDef)
				CenterHud(client);
	}
}

public void CenterHud(int client)
{	
	if(IsPlayerAlive(client))
	{
		char sResult[2048];
					
		if (g_iHud[client][0] & IN_MOVELEFT)
			Format(sResult, sizeof(sResult), "A");
		else
			Format(sResult, sizeof(sResult), "_");

		if (g_iHud[client][0] & IN_FORWARD)
			Format(sResult, sizeof(sResult), "%s W", sResult);
		else
			Format(sResult, sizeof(sResult), "%s _", sResult);	

		if (g_iHud[client][0] & IN_BACK)
			Format(sResult, sizeof(sResult), "%s S", sResult);
		else
			Format(sResult, sizeof(sResult), "%s _", sResult);	

		if (g_iHud[client][0] & IN_MOVERIGHT)
			Format(sResult, sizeof(sResult), "%s D", sResult);
		else
			Format(sResult, sizeof(sResult), "%s _", sResult);

		if (g_iHud[client][0] & IN_DUCK)
			Format(sResult, sizeof(sResult), "%s - C", sResult);
		else
			Format(sResult, sizeof(sResult), "%s - _", sResult);

		if (g_iHud[client][0] & IN_JUMP)
			Format(sResult, sizeof(sResult), "%s J", sResult);
		else
			Format(sResult, sizeof(sResult), "%s _", sResult);	
					
		char szLastJumpBuf [512];
		switch(g_iHud[client][1])
		{
			case 0:
			{
				Format(szLastJumpBuf, sizeof(szLastJumpBuf), FONTCOLOR_WHITE, g_fJSSave[client][LAST_JUMP]);
			}
			case 1:
			{
				Format(szLastJumpBuf, sizeof(szLastJumpBuf), FONTCOLOR_BLUE, g_fJSSave[client][LAST_JUMP]);
			}
			case 2:
			{
				Format(szLastJumpBuf, sizeof(szLastJumpBuf), FONTCOLOR_GREEN, g_fJSSave[client][LAST_JUMP]);
			}
			case 3:
			{
				Format(szLastJumpBuf, sizeof(szLastJumpBuf), FONTCOLOR_RED, g_fJSSave[client][LAST_JUMP]);
			}
			case 4:
			{
				Format(szLastJumpBuf, sizeof(szLastJumpBuf), FONTCOLOR_YELLOW, g_fJSSave[client][LAST_JUMP]);
			}
		}
		
		if(GetClientTeam(client) == 3)
		{
			Format(sResult, sizeof(sResult),"<font class='fontSize-0'>%sJS disabled for CT %s\nSpeed: %.1f u/s (%.0f)\nKeys:%s%s</font>",
				JSCTDISABLE, FONTCOLOR_DEFAULT, GetSpeed(client),g_fJS[client][PRE_JUMP],FONTCOLOR_KEYS, sResult);
		}
		else
		Format(sResult, sizeof(sResult),"<font class='fontSize-0'>%s%s (%s)\nSpeed: %.1f u/s (%.0f)\nKeys:%s%s</font>",
			FONTCOLOR_DEFAULT, szLastJumpBuf, szDirEnum[GetDirection(client)], GetSpeed(client),g_fJS[client][PRE_JUMP],FONTCOLOR_KEYS, sResult);

		if(g_iOptionStats[client] & SHOWSPEED_OPTION)
			PrintHintText(client,sResult);

		for(int obs = 1; obs <= MaxClients; obs++)
		{
			if(IsValidClient(obs) && obs!=client)
			{
				int iSpecMode;
				iSpecMode = GetEntProp(obs, Prop_Send, "m_iObserverMode");
				if(iSpecMode == 4 || iSpecMode == 5)
				if(GetEntPropEnt(obs, Prop_Send, "m_hObserverTarget") == client)
					if((g_iOptionStats[obs] & SHOWSPEED_OPTION))
						PrintHintText(obs,sResult);
			}
		}
	}
}

public void SendJumpStatToChat(int client, const char[] szType, int TRequestCode)
{
	for (int i = 1; i <= MaxClients;i++) 
		if(IsValidClient(i))
	{
		char szColor[256];

		g_iHud[client][1] = TRequestCode;

		char szDir[8];
		Format(szDir,sizeof(szDir),szDirEnum[GetDirection(client)]);
		
		switch(TRequestCode)
		{
			case REQUEST_WHITE: 
			{
				if(g_iOptionStats[i] & FULLSTATS_OPTION)
					Format(szColor,sizeof(szColor),szRequest_White_Long,STATS_LONG);
				else
					Format(szColor,sizeof(szColor),szRequest_White_Short,STATS_SHORT);
			}
			case REQUEST_BLUE:
			{
				if(g_iOptionStats[i] & FULLSTATS_OPTION)
					Format(szColor,sizeof(szColor),szRequest_Blue_Long,STATS_LONG);
				else
					Format(szColor,sizeof(szColor),szRequest_Blue_Short,STATS_SHORT);
			}
			case REQUEST_GREEN:
			{
				if(g_iOptionStats[i] & FULLSTATS_OPTION)
					Format(szColor,sizeof(szColor),szRequest_Green_Long,STATS_LONG);
				else
					Format(szColor,sizeof(szColor),szRequest_Green_Short,STATS_SHORT);

				if((g_iOptionStats[i] & SOUND_GREEN_OPTION) && client==i)
					EmitSoundToClient(i, Green_PLAY);
			}
			case REQUEST_RED:
			{
				if(g_iOptionStats[i] & FULLSTATS_OPTION)
					Format(szColor,sizeof(szColor),szRequest_Red_Long,STATS_LONG);
				else
					Format(szColor,sizeof(szColor),szRequest_Red_Short,STATS_SHORT);

				if((g_iOptionStats[i] & SOUND_RED_OPTION) && client==i)
					EmitSoundToClient(i, Red_PLAY);
			}
			case REQUEST_YELLOW:
			{
				if(g_iOptionStats[i] & FULLSTATS_OPTION)
					Format(szColor,sizeof(szColor),szRequest_Yellow_Long,STATS_LONG);
				else
					Format(szColor,sizeof(szColor),szRequest_Yellow_Short,STATS_SHORT);

				if(g_iOptionStats[i] & SOUND_YELLOW_OPTION)
					EmitSoundToClient(i, Yellow_PLAY);
			}
		}
	
		if((g_iOptionStats[i] & SENDTOCHAT_OPTION) && (i==client || TRequestCode>=REQUEST_GREEN))
			if(!(g_iOptionStats[i] & ONLYMYSTATS_OPTION) || i==client)
				PrintToChat(i,szColor);																					
	}	
	SendJumpStatToConsole(client,szType);		
	SaveStats(client,szType);	
}

public void SendJumpStatToConsole(int client, const char[] szType)
{
	char szSendStats[1024];
	char szSendStats_byStr[1024];
	char szSendStats_byStrPercent[1024];

	Format(szSendStats, sizeof(szSendStats), szRequest_Console, STATS_CONSOLE);

	for(int i = 0 ;i < g_iNumberStarfe[client] ; i++)
	{        
		Format(szSendStats_byStr, sizeof(szSendStats_byStr) , szRequest_Console_byStarfe, szSendStats_byStr, STATS_CONSOLE_byStr);
		Format(szSendStats_byStrPercent, sizeof(szSendStats_byStrPercent), szRequest_Console_byStarfePercent, szSendStats_byStrPercent, STATS_CONSOLE_byStrPercent);	
	}
	PrintToConsole(client,szSendStats);
	PrintToConsole(client,"  #.      Sync      Gained     MaxSpeed       Lost      AirTime ");
	PrintToConsole(client,szSendStats_byStr);

	if(g_iOptionStats[client] & SYNCINCHAT_OPTION)
		PrintToChat(client,szSendStats_byStrPercent);

	for(int obs = 1; obs <= MaxClients; obs++)
	{
		if(IsValidClient(obs) && obs!=client)
		{
			int iSpecMode;
			iSpecMode = GetEntProp(obs, Prop_Send, "m_iObserverMode");
			if(iSpecMode == 4 || iSpecMode == 5)
			if(GetEntPropEnt(obs, Prop_Send, "m_hObserverTarget") == client)
			{		
				PrintToConsole(obs,szSendStats);
				PrintToConsole(obs,"  #.      Sync      Gained     MaxSpeed       Lost      AirTime ");
				PrintToConsole(obs,szSendStats_byStr);

				if(g_iOptionStats[obs] & SYNCINCHAT_OPTION)
					PrintToChat(obs,szSendStats_byStrPercent);
			}
		}
	}
}
