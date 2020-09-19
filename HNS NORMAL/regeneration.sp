#include <sourcemod>
#include <cstrike>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "HP regeneration",
	author = "",
	description = "",
	version = "",
	url = ""
};

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}
public void OnMapStart()
{
    CreateTimer(2.0, Timer_Message, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Message(Handle timer)
{
	for(int client = 1; client < MAXPLAYERS; client ++)
	{
	 	if (IsClientInGame(client) && GetClientTeam(client) == 3 && GetClientHealth(client) < 105)
		{
			SetEntityHealth(client, GetClientHealth(client) + 1);
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && GetClientTeam(client) == 3)
	{
		SetEntityHealth(client, 105);
	}
}