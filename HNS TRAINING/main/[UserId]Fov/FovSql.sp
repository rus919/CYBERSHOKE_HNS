public void SaveFov(int client, int UserId, int fov)
{
	if(!IsValidClient(client))
		return;

	if(!IsDatabaseLoadedDef)
		return;

	char szQuery[512];

	DataPack hPack = new DataPack();
	hPack.WriteCell(fov);
	hPack.WriteCell(UserId);


	Format(szQuery, sizeof(szQuery),sql_SFov,UserId);
	g_hDatabase.Query(SQLQueryCallback_SaveFov,szQuery,hPack);	
}

public void SQLQueryCallback_SaveFov(Database hDatabase, DBResultSet hResults, const char[] sError, DataPack hPack) // Обратный вызов
{
	hPack.Reset(); // Возвращаем позицию на 0

	int fov = hPack.ReadCell();
	int UserId = hPack.ReadCell();

	delete hPack;

	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}

	char szQuery[512];

	if(fov == 90)
		Format(szQuery, sizeof(szQuery),sql_DFov,UserId);
	else
	{
		if(hResults.FetchRow())	
			Format(szQuery, sizeof(szQuery),sql_UFov,fov,UserId);
		else
			Format(szQuery, sizeof(szQuery),sql_IFov,fov,UserId);
	}

	g_hDatabase.Query(SQLQueryCallback_FovSql,szQuery);
}

public void GetFov(int client, int UserId)
{
	char szQuery[512];

	Format(szQuery, sizeof(szQuery),sql_SFov,UserId);
	g_hDatabase.Query(SQLQueryCallback_GetFov,szQuery,client);
}

public void SQLQueryCallback_GetFov(Database hDatabase, DBResultSet hResults, const char[] sError, any client) // Обратный вызов
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_GetFov: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}

	if(!IsValidClient(client))
		return;

	if(!IsDatabaseLoadedDef)
		return;

	int fov;

	if(hResults.FetchRow())	// Игрок есть в базе
		fov = hResults.FetchInt(0);

	if(fov>0)
	{
		SetEntProp(client, Prop_Send, "m_iFOV", fov);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", fov);
	}
}

public void SQLQueryCallback_FovSql(Database hDatabase, DBResultSet results, const char[] sError, any data) // Обратный вызов
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_FovSql: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
}

public void SQLQueryCallback_ConnectToDataBase(Database hDatabase, DBResultSet results, const char[] sError, any data) // Обратный вызов
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_ConnectToDataBase: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}

	g_iTableLoaded++;
}
