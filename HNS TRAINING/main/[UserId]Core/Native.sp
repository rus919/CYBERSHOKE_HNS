public int Native_OnClientReconnect(Handle hPlugin, int iNumParams)
{
    int client = GetNativeCell(1);
    
    OnClientPostAdminCheck(client);
     
    return 0;
}


public int Native_IsDatabaseLoaded(Handle hPlugin, int iNumParams)
{
    Function Func = GetNativeFunction(1);
    
    DataPack hPack = new DataPack();
    hPack.WriteCell(hPlugin);
    hPack.WriteFunction(Func);
    CreateTimer(0.1, Timer_IsDatabaseLoaded, hPack, TIMER_REPEAT);
     
    return 0;
}

static Action Timer_IsDatabaseLoaded(Handle timer, any data)
{
    //PrintToServer("1");
    if(g_sDbConnector.IsDatabaseLoaded())
    {
        //PrintToServer("2");
        DataPack hPack = data;
        hPack.Reset();

        Handle hPlugin = hPack.ReadCell();
        Function Func = hPack.ReadFunction();

        delete hPack;
   
        if(IsPluginLoaded(hPlugin))
        {  
            //PrintToServer("dddd123ddd %d", g_sDbConnector.m_hDatabase);
            Call_StartFunction(hPlugin, Func);
            Call_PushCell(g_sDbConnector.m_hDatabase);

            Call_Finish();
        }

        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}

public int Native_IsUserIdLoaded(Handle hPlugin, int iNumParams)
{
    Function Func = GetNativeFunction(1);
    int client = GetNativeCell(2);
    
    DataPack hPack = new DataPack();
    hPack.WriteCell(hPlugin);
    hPack.WriteFunction(Func);
    hPack.WriteCell(client);
    CreateTimer(0.1, Timer_IsUserIdLoaded, hPack, TIMER_REPEAT);
     
    return 0;
}

static Action Timer_IsUserIdLoaded(Handle timer, any data)
{
    DataPack hPack = data;
    hPack.Reset();

    Handle hPlugin = hPack.ReadCell();
    Function Func = hPack.ReadFunction();
    int client = hPack.ReadCell();

    if(!IsValidClient(client))
    {
        delete hPack;
        
        return Plugin_Stop;
    }

    if(g_sDbConnector.IsUserIdLoaded(client))
    {  
        delete hPack;

        if(IsPluginLoaded(hPlugin))
        {  
            Call_StartFunction(hPlugin, Func);
            Call_PushCell(g_sDbConnector.m_hDatabase);
            Call_PushCell(client);
            Call_PushCell(g_sDbConnector.GetUserId(client));

            Call_Finish();
        } 

        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}