
public void SetRank(int client)
{
	char szQuery[512];
	
	int UserId = g_iClientUserId[client];
	
	Format(szQuery, sizeof(szQuery),sql_SRC_STATS,UserId);
	g_hDatabase.Query(SQLQueryCallback_SetRank,szQuery,GetClientUserId(client));
}

public void SQLQueryCallback_SetRank(Database hDatabase, DBResultSet hResults, const char[] sError, any client_id) // Обратный вызов
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_SetRank: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}

	int client = GetClientOfUserId(client_id);

	if(!IsValidClient(client))
		return;

	if(!IsDatabaseLoadedDef)
		return;

	char szQuery[512];
	char szBuffer[512];
	
	int UserId = g_iClientUserId[client];

	if(hResults.FetchRow())	// Игрок есть в базе
    {	
		int i;
		for(i = 1 ; i < RANK_STAT ; i++)
		{
			g_aPlayerStats[client][i] = hResults.FetchInt(i);
			Format(szBuffer, sizeof(szBuffer),"%s %8d",szBuffer,g_aPlayerStats[client][i]);
		}

		g_iSwithFollow[client] = hResults.FetchInt(i++);

		LogToFile(RankStatspath,"%s UserId = %8d %N",szBuffer,UserId,client);

		Format(szQuery, sizeof(szQuery),sql_SRC_CUR_RANK,g_aPlayerStats[client][POINTS]);
		g_hDatabase.Query(SQLQueryCallback_SetRec,szQuery,GetClientUserId(client));
    }
	else
	{
		Format(szQuery, sizeof(szQuery),sql_IRC_STATS,UserId);
		g_hDatabase.Query(SQLQueryCallback_RCSql,szQuery);
	}	
}

public void SQLQueryCallback_SetRec(Database hDatabase, DBResultSet hResults, const char[] sError, any client_id) // Обратный вызов
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_SetRec: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}

	int client = GetClientOfUserId(client_id);
	
	if(!IsValidClient(client))
		return;

	if(hResults.FetchRow())	// Игрок есть в базе
		g_aPlayerStats[client][RANK] = hResults.FetchInt(0);
		
	char szValue[128];

	if(g_aPlayerStats[client][POINTS]>20)
	{
		if(g_aPlayerStats[client][RANK]>=1000)
		{
			Format(szValue, sizeof(szValue), "[Rank %dk+]", g_aPlayerStats[client][RANK]/1000);
		}
		else
		{
			Format(szValue, sizeof(szValue), "[Rank %d]", g_aPlayerStats[client][RANK]);
		}
	}	
	else 
		Format(szValue, sizeof(szValue), "[NEW]");

	if(IsValidClient(client))
		CS_SetClientClanTag(client,	szValue); 
}

public void SaveRank(int client)
{
	if(!IsValidClient(client))
		return;

	if(!IsUserIdLoadedDef)
		return;

	int UserId = g_iClientUserId[client];

	char szQuery[512];
	
	Format(szQuery, sizeof(szQuery),sql_URC_STATS,Save_PlayerStats);
	g_hDatabase.Query(SQLQueryCallback_RCSql,szQuery);

	Format(szQuery, sizeof(szQuery),sql_SRC_CUR_RANK,g_aPlayerStats[client][POINTS]);
	g_hDatabase.Query(SQLQueryCallback_SetRec,szQuery,GetClientUserId(client));
}

public void SQLQueryCallback_RCSql(Database hDatabase, DBResultSet results, const char[] sError, any data) // Обратный вызов
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_RCSql: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
}

public void SQLQueryCallback_RCSql_BaseLoaded(Database hDatabase, DBResultSet results, const char[] sError, any data) // Обратный вызов
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_RCSql_BaseLoaded: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}

	g_iTableLoaded++;
}