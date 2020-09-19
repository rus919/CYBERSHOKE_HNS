#include "main\lib\Lib.sp"

#define SOUND_DOWNLOAD	"sound/WithoutName/mario_s.mp3"
#define SOUND_PLAY		"*WithoutName/mario_s.mp3"

int iOffsetGround;
int iOwnerCount[MAXPLAYERS + 1][MAXPLAYERS + 1];
int mytime;
bool g_bSwithRound;

public void OnPluginStart()
{
	if ((iOffsetGround = FindSendPropInfo("CBasePlayer", "m_hGroundEntity")) < 1) 
		SetFailState("Offset 'CBasePlayer'::'m_hGroundEntity' not found!");

	HookEvent("round_end", Event_RoundEnd,EventHookMode_Post); 
	HookEvent("round_start", Event_RoundStart,EventHookMode_Post); 

	CreateTimer(2.0, Timer_HeadOwner, _, TIMER_REPEAT);	
}

static void Event_RoundEnd(Handle event, const char[] sEvName, bool bDontBroadcast) 
{ 
	g_bSwithRound=false;
}

static void Event_RoundStart(Handle event, const char[] sEvName, bool bDontBroadcast) 
{ 
	CreateTimer(12.0, g_Enable, _);
}

static Action g_Enable(Handle tmr, any client) 
{ 
	g_bSwithRound=true;
	return Plugin_Stop;
}

public void OnMapStart()
{
	g_bSwithRound = false;
	PrecacheSound(SOUND_PLAY, true);
	AddFileToDownloadsTable(SOUND_DOWNLOAD);
}

public Action Timer_HeadOwner(Handle timer, any data)
{
	mytime=mytime+1;
}

public Action OnPlayerRunCmd(int client)
{
	if(!IsPlayerAlive(client))
		return Plugin_Continue;

	if(g_bSwithRound == false)
		return Plugin_Continue;

	static int target;
	if ((target = GetEntDataEnt2(client, iOffsetGround)) > 0 && target <= MaxClients && GetClientTeam(client) != GetClientTeam(target))
	{
		if(mytime-iOwnerCount[client][target]>=2)
		if(GetEntityMoveType(client) != MOVETYPE_LADDER && GetEntityMoveType(target) != MOVETYPE_LADDER)
		{
			iOwnerCount[client][target]=mytime;
			int clients[MAXPLAYERS];
			int total;
			for (int i = 1; i <= MaxClients; ++i)
			{
				if (IsClientInGame(i))
				{
					PrintToChat(i, "\x01\04 \x04CYBERSHOKE \x01| \x02%N \x06прыгнул на голову \x02%N!", client, target);
					clients[total++] = i;	
				}
			}
			
			EmitSound(clients, total, SOUND_PLAY);
		}
	}
	
	return Plugin_Continue;
}