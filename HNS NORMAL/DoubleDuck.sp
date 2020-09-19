#include "main\Lib\Lib.sp"

public Plugin myinfo = 
{
	name = "DoubleDuck",
	author = PLUGIN_AUTHOR,
	description = "DoubleDuck",
	version = PLUGIN_VERSION,
}

#define DOUBLEDUCK_HEIGHT 40.0 

bool g_bAllowDoubleDuck[MAXPLAYERS+1]; 

public Action 
OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{ 
	if((GetEntPropFloat(client, Prop_Data, "m_flDuckSpeed") <DOUBLEDUCK_HEIGHT)) 
		SetEntPropFloat(client, Prop_Send, "m_flDuckSpeed", DOUBLEDUCK_HEIGHT, 0);

	if(GetEntityFlags(client) & FL_ONGROUND )
	{ 
		float vecPos[3]; 
		GetClientAbsOrigin(client , vecPos); 
		vecPos[2] += DOUBLEDUCK_HEIGHT; 

		if(GetEntityFlags(client) & FL_DUCKING)
		{
			g_bAllowDoubleDuck[client] = false;
			return Plugin_Continue;
		}
			
		if((buttons & IN_DUCK) && !(GetEntityFlags(client) & FL_DUCKING))
		{
			g_bAllowDoubleDuck[client] = true;
			return Plugin_Continue;
		}

		if(GetEntProp(client , Prop_Data , "m_bDucking") && g_bAllowDoubleDuck[client]) 
		{ 
			if(IsValidPlayerPos_DoubleDuck(client , vecPos)) 
				TeleportEntity(client , vecPos , NULL_VECTOR , NULL_VECTOR); 	
		} 
	} 

	return Plugin_Continue; 
} 

static bool IsValidPlayerPos_DoubleDuck(int client , float vecPos[3]) 
{ 
	float vecMins [3] = { - 16.0 , - 16.0 ,0.0 }; 
	float vecMaxs [3] = { 16.0 , 16.0 , 72.0 }; 
	TR_TraceHullFilter(vecPos , vecPos , vecMins , vecMaxs , MASK_SOLID , TraceFilter_IgnorePlayer_DoubleDuck , client); 
	return (!TR_DidHit(null)); 
} 

static bool TraceFilter_IgnorePlayer_DoubleDuck(int entity , int mask , any ignore_me) 
{	
	if (entity > 0 && entity <= MaxClients) 
	{ 
		if(GetClientTeam(entity)==GetClientTeam(ignore_me)) 
			return false; 
		else 
			return true; 
	}
	else  
		return true; 
}