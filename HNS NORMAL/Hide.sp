#include <sourcemod> 
#include <sdktools> 
#include <sdkhooks> 

#define newdecls required

bool b_Hided[MAXPLAYERS+1] =  { false, ... };
ConVar b_OnlyForAdmins, b_Enabled, b_OnlyTeammates;

public void OnPluginStart()
{
	RegConsoleCmd("sm_hide", HideCallBack); 
	b_Enabled = CreateConVar("sm_hideplayers_enable", "1", "Включить/Выключить плагин | 1 = Включить | 0 = Выключить");
	b_OnlyForAdmins = CreateConVar("sm_hideplayers_only_admin", "0", "Только админы могут скрывать игроков? | 1 = Да | 0 = Все игроки");
	b_OnlyTeammates = CreateConVar("sm_hideplayers_only_teammates", "0", "Скрывать только союзников? | 1 = Да | 0 = Нет (Будут скрыты все игроки)");
	AutoExecConfig(true, "sm_hide");
	
	AddNormalSoundHook(Event_Footsteps);
}

public void OnClientPutInServer(int client)
{		
	SDKHook(client, SDKHook_SetTransmit, SetTransmit);
}


public Action SetTransmit(int entity, int client) 
{ 
    if (IsClientInGame(client))
    {
    	if (b_Hided[client] == true && IsPlayerAlive(client))
    	{
			if (client != entity && 0 < entity <= MaxClients)
			{
				if(!b_OnlyTeammates.BoolValue)
				{		
					return Plugin_Handled;
				}
				
				else
				{
					if (GetClientTeam(client) == GetClientTeam(entity))
					{
						return Plugin_Handled;
					}
				}
			}
		}			
	}		
        
    return Plugin_Continue; 
}  

public Action HideCallBack(int client, int args) 
{
	if (IsClientInGame(client))
	{
		if(b_Enabled.BoolValue)
		{
			if(b_OnlyForAdmins.BoolValue)
			{
				AdminId b_Admin = GetUserAdmin(client);
				
				if (b_Admin != INVALID_ADMIN_ID)
				{
					if (b_Hided[client] == false)
    				{	
    					b_Hided[client] = true;
   					}
   			
					else if (b_Hided[client] == true)
					{
						b_Hided[client] = false;
					}
	
					PrintToChat(client, "[Hide]  %s", b_Hided[client] ? "Вы скрыли игроков.":"Теперь Вы видите всех игроков.");		
				}
				
				else
				{
					PrintToChat(client, "[Hide] Данная команда доступна только администраторам.");
				}
			}				
				
			else
			{
				if (b_Hided[client] == false)
    			{
    				b_Hided[client] = true;
   				}
   		
				else if (b_Hided[client] == true)
				{
					b_Hided[client] = false;
				}

				PrintToChat(client, "[Hide] %s", b_Hided[client] ? "Вы скрыли игроков.":"Теперь Вы видите всех игроков.");			
			}			
			
		}	

		else
		{
			PrintToChat(client, "[Hide] Плагин выключен.");
		}
	}
	
	else
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
} 


public Action Event_Footsteps(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(entity >= 1 && entity <= MaxClients && IsClientInGame(entity))
	{
		bool change = false;
		for(int i = 0; i < numClients; i++)
		{
			if(b_Hided[clients[i]] && IsPlayerAlive(clients[i]) && clients[i] != entity && GetClientTeam(clients[i]) == GetClientTeam(entity))
			{
				for (int j = i; j < numClients - 1; j++)
				{
					clients[j] = clients[j + 1];
					
				}
				numClients--;
				i--;
				change = true;
			}
		}
		if(change)
		{
			return Plugin_Changed;
		}
		else
		{
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}