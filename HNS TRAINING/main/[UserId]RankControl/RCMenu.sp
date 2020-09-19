public Action Client_Top(int client,int args)
{
	ShowRankTopMenu(client);
	return Plugin_Handled;
}


public void ShowRankTopMenu(int client)
{
	Menu hMenu = new Menu(MenuHandlerShowRankTop);
	char szOption[128];
	char szValue[128];

	if(g_aPlayerStats[client][POINTS]>20)
	{	
		Format(szValue, sizeof(szValue), "[Rank %d]", g_aPlayerStats[client][RANK]);
	}		
	else 
		Format(szValue, sizeof(szValue), " Ваш ранг: [NEW]\n");

	Format(szOption,sizeof(szOption),"%s Поинтов: %d\n KD: %d:%d \n Время игры: %d мин",szValue
																	,g_aPlayerStats[client][POINTS]
																	,g_aPlayerStats[client][KILL]
																	,g_aPlayerStats[client][DEATH]
																	,g_aPlayerStats[client][TIME]);


	hMenu.SetTitle(szOption);

	

	hMenu.AddItem("","Топ 10 по рангу");

	Format(szOption,sizeof(szOption),"Топ 20 по прыжкам");
	hMenu.AddItem("",szOption);

	/*Format(szOption,sizeof(szOption),"[%s] Hud+Beam [for VIP]",g_iSwithFollow[client] ? "ENABLED" : "DISABLED");

	
	if(!IsClientAdmin(client))
		hMenu.AddItem("","Купить Премиум [7 days/1000 money]");*/

	

	hMenu.Display(client, MENU_TIME_FOREVER);
}

static int MenuHandlerShowRankTop(Menu hMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		switch(option)
		{
			case 0: 
			{
				char szQuery[1024];       
				Format(szQuery, sizeof(szQuery), sql_SRC_REC,1,"DESC LIMIT 10");
				g_hDatabase.Query(SQLQueryCallback_sql_SRC_REC ,szQuery,client);
			}
			case 1: 
			{
				ShowRankTopMenu(client);
				ClientCommand(client, "sm_jt");
			}
		}
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
	return 0;
}


public void SQLQueryCallback_sql_SRC_REC(Database hDatabase, DBResultSet hResults, const char[] sError, any data) 
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQLQueryCallback_RCMenu: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}

	int client = data;
	Menu hMenu = new Menu(MenuHandler_sql_SRC_REC);
	
	hMenu.SetTitle("Топ 10\n    Ранк     Поинтов      Убийств     Смертей     Время           Имя");
	hMenu.Pagination = 4;

	int i = 1;
	while (hResults.FetchRow())
	{
		char szValue[512];
		char szName[64];

		hResults.FetchString(0, szName, sizeof(szName));
		int P = hResults.FetchInt(1);
		int K = hResults.FetchInt(2); 
		int D = hResults.FetchInt(3); 
		//int A = hResults.FetchInt(4); 
		//int M = hResults.FetchInt(5); 
		int T = hResults.FetchInt(6); 

		if(i<10)
			Format(szValue, 512, "[0%i.]",i);
		else 
			Format(szValue, 512, "[%i.]",i);

		if(P<10)
			Format(szValue, 512, "%s           %d",szValue,P);
		else if(P<100)
			Format(szValue, 512, "%s         %d",szValue,P);
		else if(P<1000)
			Format(szValue, 512, "%s        %d",szValue,P);
		else if(P<10000)
			Format(szValue, 512, "%s      %d",szValue,P);
		else if(P<100000)
			Format(szValue, 512, "%s    %d",szValue,P);

		if(K<10)
			Format(szValue, 512, "%s                %d",szValue,K);
		else if(K<100)
			Format(szValue, 512, "%s            %d",szValue,K);
		else if(K<1000)
			Format(szValue, 512, "%s            %d",szValue,K);
		else if(K<10000)
			Format(szValue, 512, "%s          %d",szValue,K);

		if(D<10)
			Format(szValue, 512, "%s                 %d",szValue,D);
		else if(D<100)
			Format(szValue, 512, "%s              %d",szValue,D);
		else if(D<1000)
			Format(szValue, 512, "%s           %d",szValue,D);
		else if(D<10000)
			Format(szValue, 512, "%s         %d",szValue,D);

		/*if(A<10)
			Format(szValue, 512, "%s       %d",szValue,A);
		else if(A<100)
			Format(szValue, 512, "%s     %d",szValue,A);
		else if(A<1000)
			Format(szValue, 512, "%s   %d",szValue,A);
		else if(A<10000)
			Format(szValue, 512, "%s %d",szValue,A);*/

		if(T<10)
			Format(szValue, 512, "%s                  %d",szValue,T);
		else if(T<100)
			Format(szValue, 512, "%s                %d",szValue,T);
		else if(T<1000)
			Format(szValue, 512, "%s              %d",szValue,T);
		else if(T<10000)
			Format(szValue, 512, "%s         %d",szValue,T);
		else if(T<100000)
			Format(szValue, 512, "%s       %d",szValue,T);

		/*if(M<10)
			Format(szValue, 512, "%s               %d",szValue,M);
		else if(M<100)
			Format(szValue, 512, "%s             %d",szValue,M);
		else if(M<1000)
			Format(szValue, 512, "%s           %d",szValue,M);
		else if(M<10000)
			Format(szValue, 512, "%s         %d",szValue,M);
		else if(M<100000)
			Format(szValue, 512, "%s       %d",szValue,M);
		else if(M<1000000)
			Format(szValue, 512, "%s     %d",szValue,M);
		else if(M<10000000)
			Format(szValue, 512, "%s   %d",szValue,M);*/
			
		Format(szValue, 512, "%s       %s",szValue,szName);
		hMenu.AddItem("",szValue);
		i++;
	}
	
	hMenu.Display(client, MENU_TIME_FOREVER);
}

static int MenuHandler_sql_SRC_REC(Menu hMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		ShowRankTopMenu(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
	return 0;
}