#include "main\Lib\Lib.sp"

public Plugin myinfo = 
{
	name = "AntiFrag",
	author = PLUGIN_AUTHOR,
	description = "AntiFrag",
	version = PLUGIN_VERSION,
}

Handle g_hMarked[MAXPLAYERS + 1]; 
Handle g_hMarked_dmg[MAXPLAYERS + 1]; 
int g_iOffsetGround;

public void 
OnPluginStart() 
{ 
    HookEvent("player_spawn", Event_PlayerSpawn); 

    if ((g_iOffsetGround = FindSendPropInfo("CBasePlayer", "m_hGroundEntity")) < 1)
		SetFailState("Offset 'CBasePlayer'::'m_hGroundEntity' not found!");
} 

public void 
OnClientPostAdminCheck(int client) 
{ 
    g_hMarked[client] = INVALID_HANDLE;
    g_hMarked_dmg[client] = INVALID_HANDLE;
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);   
} 

static Action 
OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{ 
    if (damagetype & DMG_SLASH > 0 && IsValidClient(victim) && IsValidClient(attacker))
        if(IsPlayerAlive(victim) && IsPlayerAlive(attacker) && GetClientTeam(victim)!=GetClientTeam(attacker)) 
    { 
        if(g_hMarked[victim]==INVALID_HANDLE) 
        { 
            if(g_hMarked_dmg[victim]==INVALID_HANDLE && g_hMarked_dmg[attacker]!=INVALID_HANDLE)
            {
                MarkPlayerDmg(attacker);
                PrintToChat(attacker,"\x01\04 \x04CYBERSHOKE \x01| \x09You cannot do damage because you have taken damage!");
                return Plugin_Handled;
            }
            else
            {
                ImmunePlayer(victim); 
                damage = 65.0;
                return Plugin_Changed;   
            } 
        }             
        else 
        { 
            ImmunePlayer(victim);
            PrintToChat(attacker,"\x01\04 \x04CYBERSHOKE \x01| \x09You can't hit that often!");
            return Plugin_Handled; 
        } 
    } 

    if(damagetype & DMG_FALL >= 1 && IsValidClient(victim))
        if(IsPlayerAlive(victim))
    {
        int target;
        if((target = GetEntDataEnt2(victim, g_iOffsetGround)) > 0 && target <= MaxClients)
        {
            return Plugin_Handled; 
        }
        MarkPlayerDmg(victim);
    }
     
    return Plugin_Continue; 
} 

static void
Event_PlayerSpawn(Event hEvent, const char[] sEvName, bool bDontBroadcast) 
{ 
    int client = GetClientOfUserId(hEvent.GetInt("userid"));
    
    if(IsValidClient(client))
    {
        SetEntityRenderMode(client, RENDER_TRANSCOLOR);
        SetEntityRenderColor(client, 255, 255, 255, 255);

        g_hMarked_dmg[client]=INVALID_HANDLE;
        g_hMarked[client]=INVALID_HANDLE;
    }
}

static void 
MarkPlayerDmg(int client)
{
    SetEntityRenderMode(client, RENDER_TRANSCOLOR);
    SetEntityRenderColor(client, 255, 255, 255, 200);

    if(g_hMarked_dmg[client]!=INVALID_HANDLE)
        KillTimer(g_hMarked_dmg[client]); 

    g_hMarked_dmg[client]=CreateTimer(3.0, AF_Unmark_dmg, client);
}

static void ImmunePlayer(int client) 
{ 
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 152, 56, 200);

	if(g_hMarked[client]!=INVALID_HANDLE)
        KillTimer(g_hMarked[client]);  

	g_hMarked[client]=CreateTimer(3.0, AF_Unmark, client);
} 

static Action 
AF_Unmark(Handle tmr, any client) 
{ 
    if(IsValidClient(client))
    {
        g_hMarked[client] = INVALID_HANDLE;
        SetEntityRenderMode(client, RENDER_TRANSCOLOR); 
        SetEntityRenderColor(client, 255, 255, 255, 255); 
    }

    return Plugin_Stop;
}

static Action 
AF_Unmark_dmg(Handle tmr, any client) 
{ 
    if(IsValidClient(client))
    {
        g_hMarked_dmg[client] = INVALID_HANDLE;
        SetEntityRenderMode(client, RENDER_TRANSCOLOR); 
        SetEntityRenderColor(client, 255, 255, 255, 255); 
    }
    
    return Plugin_Stop;
}