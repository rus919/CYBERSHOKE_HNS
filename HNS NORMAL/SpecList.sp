#include "main\Lib\Lib.sp"

public Plugin myinfo = 
{
	name = "SpecList",
	author = PLUGIN_AUTHOR,
	description = "SpecList",
	version = PLUGIN_VERSION,
}

public void 
OnPluginStart()
{
	CreateTimer(1.0, Timer_SL, _, TIMER_REPEAT);
}

static Action 
Timer_SL(Handle timer, any data)
{
	for(int client=1;client<=MaxClients;client++)
    {
        if(IsValidClient(client))
        {
            int iSpecMode, players = 0;
            char szBuffer[1024];

            if(IsPlayerAlive(client))
            {
                for(int i = 1; i <= MaxClients; i++)
                {
                    if(!IsValidClient(i) || !IsClientObserver(i))
                        continue;
                    
                    if(IsClientAdmin(i) && !(IsClientAdmin(client)))
                        continue;

                    iSpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
                    if(iSpecMode != 4 && iSpecMode != 5)
                        continue;

                    if(GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") == client)
                    {
                        players++;
                        if(players > 10)
                            continue;
                        else
                        {
                            char szName[32];

                            if(!GetClientName(i, szName, sizeof(szName)))
                                return;

                            FormatEx(szBuffer, sizeof(szBuffer), "%s%s\n", szBuffer, szName);
                        }
                    }
                }
            }
            else
            {
                iSpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");

                if(iSpecMode == 4 || iSpecMode == 5)
                {
                    int iSpecTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
                    
                    for(int i = 1; i <= MaxClients; i++)
                    {
                        if(!IsValidClient(i) || !IsClientObserver(i) )
                            continue;

                        if(IsClientAdmin(i)  && !(IsClientAdmin(client)))
                            continue;

                        iSpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
                        if(iSpecMode != 4 && iSpecMode != 5)
                            continue;

                        if(GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") == iSpecTarget)
                        {
                            players++;
                            if(players > 10)
                                continue;
                            else
                            {
                                char szName[32];

                                if(!GetClientName(i, szName, sizeof(szName)))
                                    return;

                                FormatEx(szBuffer, sizeof(szBuffer), "%s%s\n", szBuffer, szName);
                            }
                        }
                    }
                }
            }

            if(players > 0)
            {
                Format(szBuffer, sizeof(szBuffer), "Specs:\n%s", szBuffer);

                if(players > 10)
                    FormatEx(szBuffer, sizeof(szBuffer), "%s\ne.t.c %d...", szBuffer, players - 10);

                SetHudTextParams(0.01, 0.30, 1.0, 0, 230, 150, 250, 0, 0.0, 0.1, 0.1);
                ShowHudText(client, 1, szBuffer);
            }        
        }
    }
}
		