#include "main\lib\Lib.sp"
#include "main\API\[UserId]Core.inc"

SDbConnector g_sDbConnector;

//создание таблиц
char sql_CUserId[] 	            = "CREATE TABLE IF NOT EXISTS UserId (user_id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(32), lastlogin INT);";
char sql_CSteamId [] 	        = "CREATE TABLE IF NOT EXISTS SteamId (steamid VARCHAR(32) PRIMARY KEY,user_id INT, FOREIGN KEY(user_id) REFERENCES UserId(user_id));";
char sql_CIp[] 	                = "CREATE TABLE IF NOT EXISTS Ip (ip VARCHAR(32) PRIMARY KEY, user_id INT, FOREIGN KEY(user_id) REFERENCES UserId(user_id));";

char sql_SUserId[]         		= "SELECT UserId.user_id, 0 FROM SteamId JOIN UserId USING(user_id) WHERE SteamId.steamid ='%s' UNION SELECT UserId.user_id, 1 FROM Ip JOIN UserId USING(user_id) WHERE Ip.ip ='%s';";
char sql_ISteamId[]      	    = "INSERT INTO SteamId 	(steamid, user_id) 	VALUES ('%s', %d) ;";
char sql_IIP[]       			= "INSERT INTO Ip 		(ip, user_id) 		VALUES ('%s', %d) ;";
char sql_UIP[]       			= "UPDATE Ip SET ip='%s' WHERE user_id = %d ;";

char sql_UUserId[]       		= "UPDATE UserId SET name ='%s', lastlogin = '%d' WHERE user_id = %d;";

char sql_SIp_byUserId[]         = "SELECT Ip.ip FROM Ip JOIN UserId USING(user_id) WHERE UserId.user_id = %d;";

char sql_IUserId[] 	            = "INSERT INTO UserId (user_id, name, lastlogin) VALUES (NULL, '%s', %d);";

public Plugin myinfo = 
{
	name = "[UserId]Core",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
}

#include "main\[UserId]Core\Native.sp"
#include "main\[UserId]Core\GetUserId.sp"

public void OnPluginStart()
{
	//передаем кол-во таблиц
	g_sDbConnector.Init(3);

	//загрузка переводов
	LoadTranslations("common.phrases");

	//подключение к бд
	Database.Connect(ConnectCallBack, "UserIdCore");

	//в случае загрузи плагина во время игры, делаем загрузку игроков
	for(int i = 1 ; i < MaxClients; i++)
	{
		if(IsValidClient(i))
			OnClientPostAdminCheck(i);
	}
}

public void ConnectCallBack(Database hDatabase, const char[] sError, any data) // Пришел результат соеденения
{
	if (hDatabase == null)    // Соединение  не удачное
	{
		SetFailState("Database failure: %s", sError); // Отключаем плагин
		return;
	}
	
	g_sDbConnector.m_hDatabase = hDatabase; // Присваиваеым глобальной переменной соеденения значение текущего соеденения

	//создаем таблицы
	hDatabase.Query(SQLQueryCallback_CreateTable, sql_CUserId);
	hDatabase.Query(SQLQueryCallback_CreateTable, sql_CSteamId);
	hDatabase.Query(SQLQueryCallback_CreateTable, sql_CIp);
}

static void SQLQueryCallback_CreateTable(Database hDatabase, DBResultSet results, const char[] sError, any client) // Обратный вызов
{
	if(sError[0]) // Если произошла ошибка
	{
		SetFailState("Can't create table: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
	
	hDatabase.SetCharset("cp1251");
	g_sDbConnector.TableLoaded();
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max) 
{   
	CreateNative("IsUserIdLoaded", Native_IsUserIdLoaded);
	CreateNative("IsDatabaseLoaded", Native_IsDatabaseLoaded);
	CreateNative("OnClientReconnect", Native_OnClientReconnect);
	
	return APLRes_Success; 
}

public void OnClientPostAdminCheck(int client)
{
	CreateTimer(0.1, Timer_OnClientPostAdminCheck, client, TIMER_REPEAT);
}

public void OnClientDisconnect(int client)
{
	g_sDbConnector.UnLoadUserId(client);
}

static Action Timer_OnClientPostAdminCheck(Handle timer, any data)
{
	if(g_sDbConnector.IsDatabaseLoaded())
	{
		if(IsValidClient(data))
	   		ClientConnected(data);

		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

static void ClientConnected(int client)
{
	GetUserIdFromSql(client);
}