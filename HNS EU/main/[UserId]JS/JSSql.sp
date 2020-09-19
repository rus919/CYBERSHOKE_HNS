//к меню
public void SetJumpCmd(int client)
{
	char szQuery[512];

	if(!IsUserIdLoadedDef)
		return;
	
	int UserId = g_iClientUserId[client];

	Format(szQuery, sizeof(szQuery),sql_SJS_CMD,UserId);
	g_hDatabase.Query(SQLQueryCallback_SetJumpCmd,szQuery,client);
}

public void SQLQueryCallback_SetJumpCmd(Database hDatabase, DBResultSet hResults, const char[] sError, any client) // Обратный вызов
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_JsSql: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}

	if(!IsUserIdLoadedDef)
		return;

	char szQuery[512];
	int res = 59;
	int UserId = g_iClientUserId[client];

	if(hResults.FetchRow())	// Игрок есть в базе
		g_iOptionStats[client] = hResults.FetchInt(0);
	else
	{
		g_iOptionStats[client]=res;
		Format(szQuery, sizeof(szQuery),sql_IJS_CMD,res,UserId);
		g_hDatabase.Query(SQLQueryCallback_JsSql,szQuery);
	}	
}

public void SaveJumpCmd(int client)
{
	if(!IsUserIdLoadedDef)
		return;

	char szQuery[512];
	//float time = GetEngineTime();
	int UserId = g_iClientUserId[client];
	//PrintToServer("%f",GetEngineTime()-time);
	Format(szQuery, sizeof(szQuery),sql_UJS_CMD,g_iOptionStats[client],UserId);
	g_hDatabase.Query(SQLQueryCallback_JsSql,szQuery);	
}
//к прыжкам 
public void SetJumpStats(int client)
{
	if(!IsUserIdLoadedDef)
		return;

	int UserId = g_iClientUserId[client];
	char szQuery[512];

	for(int i = 0 ; i < JUMP_PATTERN ; i++)
	{
		DataPack hPack = new DataPack();
		hPack.WriteCell(i);
		hPack.WriteCell(client);

		Format(szQuery, sizeof(szQuery),sql_SJS_JUMP[i],UserId);
		g_hDatabase.Query(SQLQueryCallback_SetJumpStats,szQuery,hPack);
	}	
}

public void SQLQueryCallback_SetJumpStats(Database hDatabase, DBResultSet hResults, const char[] sError, Handle hDataPack) // Обратный вызов
{
	DataPack hPack = view_as<DataPack>(hDataPack);    // Методы работают только с типом DataPack, а не Handle
	hPack.Reset(); // Возвращаем позицию на 0
	int TJumpCode = hPack.ReadCell();
	int client = hPack.ReadCell();

	delete hPack;

	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_JsSql: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}

	if(!IsUserIdLoadedDef)
		return;

	int UserId = g_iClientUserId[client];

	char szQuery[512];
	
	if(hResults.FetchRow())	// Игрок есть в базе
		g_fJumpPattern[client][TJumpCode] = hResults.FetchFloat(1);	
	else
	{
		Format(szQuery, sizeof(szQuery),sql_IJS_JUMP[TJumpCode],UserId);
		g_hDatabase.Query(SQLQueryCallback_JsSql,szQuery);
	}
}

public void SaveStats(int client,const char[] szType)
{
	char szQuery[256];
	int TJumpCode;
 	g_iNumberStarfeSave[client] = g_iNumberStarfe[client];

	for(int i = 0 ; i < JUMP_STATS ; i++)
	 	g_fJSSave[client][i] = g_fJS[client][i];

	for(int i = 0 ; i < JUMP_PATTERN ; i++)
	{
		if(StrEqual(szType,szJumps[i], true) && (g_fJSSave[client][LAST_JUMP]>=g_fJumpPattern[client][i]))
		{
			g_fJumpPattern[client][i] = g_fJSSave[client][LAST_JUMP];
			Format(szQuery,sizeof(szQuery),sql_UJS_JUMP[i],STATS_PUT);
			TJumpCode = i;
		}
	}

	if(szQuery[0])
	{
		if(!IsUserIdLoadedDef)
		return;

		int UserId = g_iClientUserId[client];

		Format(szQuery,sizeof(szQuery),"%s %d;",szQuery,UserId);
		//PrintToServer("%s",szQuery);
		
		g_hDatabase.Query(SQLQueryCallback_JsSql ,szQuery);			
		
		
		DataPack hPack = new DataPack();
		hPack.WriteCell(TJumpCode);
		hPack.WriteCell(client);

		Format(szQuery,sizeof(szQuery),sql_SJS_JUMPREC[TJumpCode],g_fJSSave[client][LAST_JUMP],";");
		g_hDatabase.Query(SQLQueryCallback_NowInTop ,szQuery, hPack);			
	}
}

public void SQLQueryCallback_NowInTop(Database hDatabase, DBResultSet hResults, const char[] sError, Handle hDataPack) // Обратный вызов
{
	DataPack hPack = view_as<DataPack>(hDataPack);    // Методы работают только с типом DataPack, а не Handle
	hPack.Reset(); // Возвращаем позицию на 0
	int TJumpCode = hPack.ReadCell();
	int client = hPack.ReadCell();

	delete hPack;

	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_JsSql: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}

	if(hResults.FetchRow())	// Игрок есть в базе
		PrintToChatAll("\x01\04 \x03[\x07JS\x03] \x04%N \x08is \x08now \x0B#%d \x08in \x08the \x04%s",client, SQL_GetRowCount(hResults),szJumps[TJumpCode]);

}

public void SQLQueryCallback_Delete_statsUserId(Database hDatabase, DBResultSet hResults, const char[] sError, any data) // Обратный вызов
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_JsSql: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}

	if(hResults.FetchRow())
		Delete_statsUserId(hResults.FetchInt(0));

}


public void Delete_stats(int client)
{
	char szQuery[256];

	if(!IsUserIdLoadedDef)
		return;

	int UserId = g_iClientUserId[client];

	for(int i = 0 ; i < JUMP_STATS ; i++)
	{
		g_fJSSave[client][i] = 0.0;
		g_fJumpPattern[client][i]=0.0;

	}
	
	for(int i = 0 ; i < JUMP_PATTERN ; i++)
	{
		Format(szQuery,sizeof(szQuery),sql_UJS_JUMP[i],0.0, 0, 0.0, 0.0, 0.0, 0.0, 0.0);
		Format(szQuery,sizeof(szQuery),"%s %d;",szQuery,UserId);
				//PrintToServer("%s",szQuery);
				
		g_hDatabase.Query(SQLQueryCallback_JsSql ,szQuery);	
	}

	PrintToChatAll("Stats %d is reset",UserId);
}

public void Delete_statsUserId(int UserId)
{
	char szQuery[256];

	for(int i = 0 ; i < JUMP_PATTERN ; i++)
	{
		Format(szQuery,sizeof(szQuery),sql_UJS_JUMP[i],0.0, 0, 0.0, 0.0, 0.0, 0.0, 0.0);
		Format(szQuery,sizeof(szQuery),"%s %d;",szQuery,UserId);
				//PrintToServer("%s",szQuery);
				
		g_hDatabase.Query(SQLQueryCallback_JsSql ,szQuery);	
	}

	PrintToChatAll("Stats %d is reset",UserId);
}

public void SQLQueryCallback_JsSql(Database hDatabase, DBResultSet results, const char[] sError, any data) // Обратный вызов
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_JsSql: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
}

public void SQLQueryCallback_JsSql_BaseLoaded(Database hDatabase, DBResultSet results, const char[] sError, any data) // Обратный вызов
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_FovSql: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}

	g_iTableLoaded++;
}