#include "main\Lib\Lib.sp"

public Plugin myinfo = 
{
	name = "ThirdPerson",
	author = PLUGIN_AUTHOR,
	description = "ThirdPerson",
	version = PLUGIN_VERSION,
}

bool g_bThird[MAXPLAYERS+1];

public void 
OnPluginStart()
{
	Handle hCvar = FindConVar("sv_allow_thirdperson");

	if(hCvar == INVALID_HANDLE)
		SetFailState("sv_allow_thirdperson not found!");
		
	SetConVarInt(hCvar, 1);

	RegConsoleCmd("sm_third", Command_TP, "Toggle thirdperson");
	RegConsoleCmd("sm_thirdperson", Command_TP, "Toggle thirdperson");
	RegConsoleCmd("sm_tp", Command_TP, "Toggle thirdperson");
}

public void 
OnClientPostAdminCheck(int client)
{
    g_bThird[client] = false;
}

static Action 
Command_TP(int client, int args)
{
	if(!g_bThird[client])
	{
		ClientCommand(client, "thirdperson");
		g_bThird[client] = true;
	}
	else
	{
		ClientCommand(client, "firstperson");
		g_bThird[client] = false;
	}

	return Plugin_Handled;
}

