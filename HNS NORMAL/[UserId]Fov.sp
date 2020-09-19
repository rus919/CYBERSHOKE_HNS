#include "main\API\[UserId]Core.inc"

#include "main\Lib\Lib.sp"

char sql_CFov[] 	= "CREATE TABLE IF NOT EXISTS Fov (fov INT ,user_id INT PRIMARY KEY, FOREIGN KEY(user_id) REFERENCES UserId(user_id));";
char sql_SFov[] 	= "SELECT fov FROM Fov WHERE user_id = %d;";
char sql_IFov[]  	= "INSERT INTO Fov (fov, user_id) VALUES(%d, %d);";
char sql_UFov[] 	= "UPDATE Fov SET fov = %d WHERE user_id = %d;";
char sql_DFov[] 	= "DELETE FROM Fov WHERE user_id = %d";

//частный случай для кажого плагина
Database    g_hDatabase;
int         g_iTableLoaded;
int        	g_iClientUserId[MAXPLAYERS  + 1];

#define MAX_TABLE 1
#define IsDatabaseLoadedDef (g_iTableLoaded==MAX_TABLE)
#define IsUserIdLoadedDef (IsDatabaseLoadedDef && g_iClientUserId[client])
//**********************************************************************

#include "main\[UserId]Fov\FovSql.sp"

public Plugin myinfo = 
{
	name = "[UserId]Fov",
	author = PLUGIN_AUTHOR,
	description = "Fov",
	version = PLUGIN_VERSION,
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_fov", Command_Fov, "[SM] Usage: !fov <90>");

	IsDatabaseLoaded(OnConnected);

	for(int i = 0 ; i < MaxClients; i++)
	{
		if(IsValidClient(i))
			OnClientPostAdminCheck(i);
	}
}

public void OnConnected(Database hDatabase)
{
	g_hDatabase = hDatabase;

	hDatabase.Query(SQLQueryCallback_ConnectToDataBase, sql_CFov);

}

public void OnClientDisconnect(int client)
{
	g_iClientUserId[client] = 0;
}

public void OnClientPostAdminCheck(int client)
{
	g_iClientUserId[client] = 0;
	IsUserIdLoaded(ClientConnectedCore, client);
}

public void ClientConnectedCore(Database hDatabase, int client, int UserId)
{
	//UserId инцилизирован
	g_iClientUserId[client] = UserId;

	CreateTimer(0.1, Timer_OnClientPostAdminCheck, client, TIMER_REPEAT);
}

static Action Timer_OnClientPostAdminCheck(Handle timer, any data)
{
	if(IsDatabaseLoadedDef)
	{
		if(IsValidClient(data))
	   		ClientConnected(data);

		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public void ClientConnected(int client)
{
	//игрок полностью подключен

	GetFov(client, g_iClientUserId[client]);
}

static Action Command_Fov(int client,int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: !fov <90>");
		return Plugin_Handled;
	}

	if(!IsUserIdLoadedDef)
		return Plugin_Handled;
	
	char teamarg[65];
	int teamargBuffer;
	GetCmdArg(1, teamarg, sizeof(teamarg));
	teamargBuffer = StringToInt(teamarg);
	if(teamargBuffer<170 && teamargBuffer>10 && IsValidClient(client))
	{
		SetEntProp(client, Prop_Send, "m_iFOV", teamargBuffer);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", teamargBuffer);
	
		SaveFov(client,g_iClientUserId[client],teamargBuffer);
	}
	else 
		ReplyToCommand(client, "[SM] Usage: !fov <10-170>");

	return Plugin_Handled;
}

