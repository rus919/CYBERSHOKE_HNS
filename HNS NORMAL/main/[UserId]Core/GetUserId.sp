public void GetUserIdFromSql(int client)
{
	char szSteamId[32];
	char szIp[32];
	char szName[32];
	char szQuery[256];

	if(!IsValidClient(client))
		return;

	//не могу получить стим
	if(!GetClientAuthId(client, AuthId_Engine, szSteamId, sizeof(szSteamId)))
	{
		KickClientEx(client,"Authorization Failed");
		return;
	}

	//не могу получить ип
	if(!GetClientIP(client, szIp, sizeof(szIp)))
	{
		KickClientEx(client,"Authorization Failed");
		return;
	}
		
	//не могу получить имя
	if(!GetClientName(client, szName, sizeof(szName)))
	{
		KickClientEx(client,"Authorization Failed");
		return;
	}

	Format(szQuery, sizeof(szQuery),sql_SUserId,szSteamId,szIp);
	g_sDbConnector.m_hDatabase.Query(SQLQueryCallback_GetUserIdFromSql,szQuery,client);	
}

public void SQLQueryCallback_GetUserIdFromSql(Database hDatabase, DBResultSet hResults, const char[] sError, any client) // Обратный вызов
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_GetUserIdFromSql: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}

	int UserId[2];
	char szSteamId[32];
	char szIp[32];
	char szName[32];
	char szQuery[256];

	if(!IsValidClient(client))
		return;

	if(!GetClientAuthId(client, AuthId_Engine, szSteamId, sizeof(szSteamId)))
		return;

	if(!GetClientIP(client, szIp, sizeof(szIp)))
		return;

	if(!GetClientName(client, szName, sizeof(szName)))
		return;

	char[] szEscapedName = new char[2*strlen(szName)+1];
	g_sDbConnector.m_hDatabase.Escape(szName, szEscapedName, MAX_NAME_LENGTH*2+1);

	while(hResults.FetchRow())	// Игрок есть в базе
		UserId[hResults.FetchInt(1)]  = hResults.FetchInt(0);

	if(UserId[0])
	{
		g_sDbConnector.LoadUserId(client, UserId[0]);
		
		DataPack hPack = new DataPack();
		hPack.WriteCell(client);
		hPack.WriteString(szEscapedName);
		hPack.WriteString(szIp);

		Format(szQuery, sizeof(szQuery),sql_SIp_byUserId,UserId[0]);
		g_sDbConnector.m_hDatabase.Query(SQLQueryCallback_SIp,szQuery,hPack);
	}
	else if(UserId[1])
	{
		g_sDbConnector.LoadUserId(client, UserId[1]);
		
		Format(szQuery, sizeof(szQuery),sql_ISteamId,szSteamId,UserId[1]);
		g_sDbConnector.m_hDatabase.Query(SQLQueryCallback_GetUserIdFromSql_All,szQuery);

		Format(szQuery, sizeof(szQuery),sql_UUserId,szEscapedName, GetTime(),UserId[1]);
		g_sDbConnector.m_hDatabase.Query(SQLQueryCallback_GetUserIdFromSql_All,szQuery);
	}
	else
	{
		DataPack hPack = new DataPack();
		hPack.WriteCell(client);
		hPack.WriteString(szSteamId);
		hPack.WriteString(szIp);
		
		Format(szQuery, sizeof(szQuery),sql_IUserId, szEscapedName, GetTime());
		g_sDbConnector.m_hDatabase.Query(SQLQueryCallback_CUserId,szQuery,hPack);
	}
}

public void SQLQueryCallback_CUserId(Database hDatabase, DBResultSet hResults, const char[] sError, Handle hDataPack) // Обратный вызов
{
	DataPack hPack = view_as<DataPack>(hDataPack);   

	hPack.Reset(); // Возвращаем позицию на 0

	int client = hPack.ReadCell();
	char szIp[32];
	char szSteamId[32];
	hPack.ReadString(szSteamId, sizeof(szSteamId));
	hPack.ReadString(szIp, sizeof(szIp));

	delete hPack;

	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_CUserId: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}

	char szQuery[256];

	int UserId = hResults.InsertId;

	g_sDbConnector.LoadUserId(client, UserId);

	Format(szQuery, sizeof(szQuery),sql_ISteamId, szSteamId, UserId);
	g_sDbConnector.m_hDatabase.Query(SQLQueryCallback_GetUserIdFromSql_All,szQuery);

	Format(szQuery, sizeof(szQuery),sql_IIP, szIp, UserId);
	g_sDbConnector.m_hDatabase.Query(SQLQueryCallback_GetUserIdFromSql_All,szQuery);
	
}

public void SQLQueryCallback_SIp(Database hDatabase, DBResultSet hResults, const char[] sError, DataPack hPack) // Обратный вызов
{
	hPack.Reset(); // Возвращаем позицию на 0

	int client = hPack.ReadCell();
	char szEscapedName[32];
	hPack.ReadString(szEscapedName, sizeof(szEscapedName));
	char szIp[32];
	hPack.ReadString(szIp, sizeof(szIp));

	delete hPack;

	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_SIp: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
	char szQuery[256];

	if(g_sDbConnector.IsUserIdLoaded(client))
	{
		if(hResults.FetchRow())
		{
			Format(szQuery, sizeof(szQuery),sql_UIP,szIp ,g_sDbConnector.GetUserId(client));
		}
		else
			Format(szQuery, sizeof(szQuery),sql_IIP,szIp, g_sDbConnector.GetUserId(client));

		g_sDbConnector.m_hDatabase.Query(SQLQueryCallback_GetUserIdFromSql_All, szQuery);

		Format(szQuery, sizeof(szQuery),sql_UUserId,szEscapedName, GetTime(), g_sDbConnector.GetUserId(client));
		g_sDbConnector.m_hDatabase.Query(SQLQueryCallback_GetUserIdFromSql_All, szQuery);
	}
}

public void SQLQueryCallback_GetUserIdFromSql_All(Database hDatabase, DBResultSet hResults, const char[] sError, any data) // Обратный вызов
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_GetUserIdFromSql_All: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
}