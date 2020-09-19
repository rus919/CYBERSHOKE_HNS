public Action Jump_Cmd(int client,int args)
{
	ShowJumpCmdMenu(client);
	return Plugin_Handled;
}

static void ShowJumpCmdMenu(int client)
{
	Menu hMenu = new Menu(MenuHandlerJumpCmd);

	hMenu.SetTitle("Jump Cmd:");

	char szOption[32];

	Format(szOption,sizeof(szOption),"[%s] Change Speed Style", (g_iOptionStats[client] & SHOWSPEED_OPTION) ? "Old Style" : "New Style");
	hMenu.AddItem("",szOption);

	Format(szOption,sizeof(szOption),"[%s] Show Stats",(g_iOptionStats[client] & SENDTOCHAT_OPTION) ? "Enabled" : "Disabled");
	hMenu.AddItem("",szOption);

	Format(szOption,sizeof(szOption),"[%s] Full Stats",(g_iOptionStats[client] & FULLSTATS_OPTION) ? "Enabled" : "Disabled");
	hMenu.AddItem("",szOption);

	Format(szOption,sizeof(szOption),"[%s] Sound Green",(g_iOptionStats[client] & SOUND_GREEN_OPTION) ? "Enabled" : "Disabled");
	hMenu.AddItem("",szOption);

	Format(szOption,sizeof(szOption),"[%s] Sound Red",(g_iOptionStats[client] & SOUND_RED_OPTION) ? "Enabled" : "Disabled");
	hMenu.AddItem("",szOption);

	Format(szOption,sizeof(szOption),"[%s] Sound Yellow",(g_iOptionStats[client] & SOUND_YELLOW_OPTION) ? "Enabled" : "Disabled");
	hMenu.AddItem("",szOption);

	Format(szOption,sizeof(szOption),"[%s] Sync in chat",(g_iOptionStats[client] & SYNCINCHAT_OPTION) ? "Enabled" : "Disabled");
	hMenu.AddItem("",szOption);

	Format(szOption,sizeof(szOption),"[%s] only my stats",(g_iOptionStats[client] & ONLYMYSTATS_OPTION) ? "Enabled" : "Disabled");
	hMenu.AddItem("",szOption);

	hMenu.Display(client, MENU_TIME_FOREVER);
}

static int MenuHandlerJumpCmd(Menu hMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		switch(option)
		{
			case 0: 
			{
				if(g_iOptionStats[client] & SHOWSPEED_OPTION)
				{
					ClientCommand(client, "sm_mhcustom");
					g_iOptionStats[client] -= SHOWSPEED_OPTION;
				}
				else if(!(g_iOptionStats[client] & SHOWSPEED_OPTION))
				{
					ClientCommand(client, "sm_mhdefault");
					g_iOptionStats[client] += SHOWSPEED_OPTION;
				}
					
			}
			case 1:
			{
				if(g_iOptionStats[client] & SENDTOCHAT_OPTION)
					g_iOptionStats[client] -= SENDTOCHAT_OPTION;
				else if(!(g_iOptionStats[client] & SENDTOCHAT_OPTION))
					g_iOptionStats[client] += SENDTOCHAT_OPTION;
			}	
			case 2: 
			{
				if(g_iOptionStats[client] & FULLSTATS_OPTION)
					g_iOptionStats[client] -= FULLSTATS_OPTION;
				else if(!(g_iOptionStats[client] & FULLSTATS_OPTION))
					g_iOptionStats[client] += FULLSTATS_OPTION;
			}	
			case 3:
			{
				if(g_iOptionStats[client] & SOUND_GREEN_OPTION)
					g_iOptionStats[client] -= SOUND_GREEN_OPTION;
				else if(!(g_iOptionStats[client] & SOUND_GREEN_OPTION))
					g_iOptionStats[client] += SOUND_GREEN_OPTION;
			}	
			case 4:
			{
				if(g_iOptionStats[client] & SOUND_RED_OPTION)
					g_iOptionStats[client] -= SOUND_RED_OPTION;
				else if(!(g_iOptionStats[client] & SOUND_RED_OPTION))
					g_iOptionStats[client] += SOUND_RED_OPTION;
			}
			case 5:
			{
				if(g_iOptionStats[client] & SOUND_YELLOW_OPTION)
					g_iOptionStats[client] -= SOUND_YELLOW_OPTION;
				else if(!(g_iOptionStats[client] & SOUND_YELLOW_OPTION))
					g_iOptionStats[client] += SOUND_YELLOW_OPTION;
			}
			case 6: 
			{
				if(g_iOptionStats[client] & SYNCINCHAT_OPTION)
					g_iOptionStats[client] -= SYNCINCHAT_OPTION;
				else if(!(g_iOptionStats[client] & SYNCINCHAT_OPTION))
					g_iOptionStats[client] += SYNCINCHAT_OPTION;
			}	
			case 7: 
			{
				if(g_iOptionStats[client] & ONLYMYSTATS_OPTION)
					g_iOptionStats[client] -= ONLYMYSTATS_OPTION;
				else if(!(g_iOptionStats[client] & ONLYMYSTATS_OPTION))
					g_iOptionStats[client] += ONLYMYSTATS_OPTION;
			}			
		}
		SaveJumpCmd(client);
		ShowJumpCmdMenu(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
	return 0;
}
///топ
public Action Jump_Top(int client,int args)
{
	ShowJumpTopAllMenu(client);
	return Plugin_Handled;
}

public void ShowJumpTopAllMenu(int client)
{
	Menu hMenu = new Menu(MenuHandlerJumpTopAll);

	hMenu.SetTitle("Jump Top:");

	char szOption[32];

	for(int i = 0 ;i < JUMP_PATTERN ; i++)
	{
		Format(szOption,sizeof(szOption),"Top 20 %s",szJumps[i]);
		hMenu.AddItem("",szOption);
	}

	hMenu.Display(client, MENU_TIME_FOREVER);
}

static int MenuHandlerJumpTopAll(Menu hMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		ShowJumpTopMenu(client,option);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
	return 0;
}

public void ShowJumpTopMenu(int client, int TJumpCode)
{
	char szQuery[256];

	DataPack hPack = new DataPack();
	hPack.WriteCell(TJumpCode);
	hPack.WriteCell(client);
	
	Format(szQuery,sizeof(szQuery),sql_SJS_JUMPREC[TJumpCode],100.0,"DESC LIMIT 20;");
	g_hDatabase.Query(SQLQueryCallback_ShowJumpTopMenu ,szQuery, hPack);
}

public void SQLQueryCallback_ShowJumpTopMenu(Database hDatabase, DBResultSet hResults, const char[] sError, Handle hDataPack) // Обратный вызов
{
	DataPack hPack = view_as<DataPack>(hDataPack);    // Методы работают только с типом DataPack, а не Handle
	hPack.Reset(); // Возвращаем позицию на 0
	int TJumpCode = hPack.ReadCell();
	int client = hPack.ReadCell();

	delete hPack;
	
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_JsMenu: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}

	Menu hMenu = new Menu(MenuHandlerJumpTop);

	char szInfo[8];
	char szOption[256];
	

	char szName[64];
	float rec;
	int str;
	int i;
	int UserId;

	Format(szOption,sizeof(szOption),"Top 20 %s ",szJumps[TJumpCode]);
	hMenu.SetTitle(szOption);
	
	while (hResults.FetchRow())
	{	
		i++;
		hResults.FetchString( 0, szName, sizeof(szName));
		rec = hResults.FetchFloat(1); 
		str = hResults.FetchInt(2); 
		UserId = hResults.FetchInt(3); 

		if(i>9)
			Format(szOption,sizeof(szOption),"[%d.]    %.3f units      ",i,rec);
		else
			Format(szOption,sizeof(szOption),"[0%d.]    %.3f units      ",i,rec);

		if(str>9)
			Format(szOption,sizeof(szOption),"%s%d      >>%s",szOption,str,szName);
		else
			Format(szOption,sizeof(szOption),"%s  %d      >>%s",szOption,str,szName);

		Format(szInfo,sizeof(szInfo),"%d",UserId);
		hMenu.AddItem(szInfo,szOption);		
	}
	
	hMenu.Display(client, MENU_TIME_FOREVER);
}

static int MenuHandlerJumpTop(Menu hMenu, MenuAction action, int client, int option)
{
	bool bFlag;

	if(action == MenuAction_Select)
	{
		bFlag = true;
		char szInfo[128]; 
		hMenu.GetItem(option, szInfo, sizeof(szInfo));
		int UserId=StringToInt(szInfo);
		ShowJumpTopUserIdMenu(client,UserId);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(hMenu);		
	}

	if(!bFlag)
		ShowJumpTopAllMenu(client);
		
	return 0;
}

public Action Jump_Rank(int client,int args)
{
	if (args < 1)
	{
		 ReplyToCommand(client, "[SM] Usage: !stats <name|@me>");
		 return Plugin_Handled;
	}
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
						 arg,
						 client,
						 target_list,
						 MAXPLAYERS,
						 COMMAND_FILTER_NO_IMMUNITY,
						 target_name,
						 sizeof(target_name),
						 tn_is_ml)) <= 0)
	{
		PrintToChat(client, "Not found or invalid parameter.");
		return Plugin_Handled;
	}

	if(!IsDatabaseLoadedDef)
		return Plugin_Handled;

	for (int i = 0; i < target_count; i++)
	{	
		if(IsValidClient(target_list[i]))
		{
			if(g_iClientUserId[target_list[i]])
			{
				int UserId = g_iClientUserId[target_list[i]];
				ShowJumpTopUserIdMenu(client,UserId);
			}			
		}		
	}	
	
	return Plugin_Handled;
}

public void ShowJumpTopUserIdMenu(int client, int UserId)
{
	char szQueryOnly[256];
	char szQuery[4096];

	DataPack hPack = new DataPack();
	hPack.WriteCell(UserId);
	hPack.WriteCell(client);

	Format(szQuery,sizeof(szQuery),sql_SJS_JUMP[0],UserId);

	for(int i = 1 ; i < JUMP_PATTERN ; i++)
	{
		Format(szQueryOnly,sizeof(szQueryOnly),sql_SJS_JUMP[i],UserId);
		Format(szQuery,sizeof(szQuery),"%s UNION %s",szQuery,szQueryOnly);	
	}
	g_hDatabase.Query(SQLQueryCallback_ShowJumpTopUserIdMenu ,szQuery, hPack);
}

public void SQLQueryCallback_ShowJumpTopUserIdMenu(Database hDatabase, DBResultSet hResults, const char[] sError, Handle hDataPack) // Обратный вызов
{
	DataPack hPack = view_as<DataPack>(hDataPack);    // Методы работают только с типом DataPack, а не Handle
	hPack.Reset(); // Возвращаем позицию на 0
	int UserId = hPack.ReadCell();
	int client = hPack.ReadCell();

	delete hPack;
	
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_JsMenu: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}

	Menu hMenu = new Menu(MenuHandlerJumpTopUserId);

	char szOption[256];
	char szName[64];
	float rec;
	int str;
	float pre;
	float max;
	float height;
	float gain;
	float sync;

	bool bFlagEmpty = false;
	
	hMenu.Pagination = 5;

	while(hResults.FetchRow())
	{
		hResults.FetchString( 0, szName, sizeof(szName));
		rec = hResults.FetchFloat(1); 
		str = hResults.FetchInt(2); 
		pre = hResults.FetchFloat(3); 
		max = hResults.FetchFloat(4); 
		height = hResults.FetchFloat(5); 
		gain = hResults.FetchFloat(6); 
		sync = hResults.FetchFloat(7); 
		if(rec>100)
		{
			bFlagEmpty = true;
			
			if(str>9)
				Format(szOption,sizeof(szOption),"%3.3f  %8d %8.2f %8.2f %8.1f %8.1f %8.1f%% >> %s", rec,str,pre,max,height,gain,sync,szJumpsShort[hResults.FetchInt(8)]);		
			else	
				Format(szOption,sizeof(szOption),"%3.3f   %8d %8.2f %8.2f %8.1f %8.1f %8.1f%% >> %s", rec,str,pre,max,height,gain,sync,szJumpsShort[hResults.FetchInt(8)]);	
				
			hMenu.AddItem("",szOption);
		}
	}
	
	if(!bFlagEmpty)
		hMenu.AddItem("","Empty",ITEMDRAW_DISABLED );
	 
	Format(szOption,sizeof(szOption),"%s || %d\nDistance         STR   PRE       MAX      HEIGHT   GAIN   SYNC       TYPE",szName,UserId);
	hMenu.SetTitle(szOption);
	
	hMenu.Display(client, MENU_TIME_FOREVER);
}


static int MenuHandlerJumpTopUserId(Menu hMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		ShowJumpTopMenu(client,option);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(hMenu);		
	}
	return 0;
}