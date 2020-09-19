native int IsDatabaseLoaded(Function Func);

native int IsUserIdLoaded(Function Func, int client);

native int OnClientReconnect(int client);

enum struct SDbConnector
{
    //описатель бд
    Database    m_hDatabase;

    //сколько таблиц ожидается загрузить
    int         m_iMaxTable;

    //сколько таблиц уже загружено
    int         m_iTableLoaded;

    //массив загруженных пользователей
    int        	m_aUserIdLoaded[MAXPLAYERS];
    
    //загрузка кол-во таблиц
    void        Init(int iMaxTable)
    {
        this.m_iMaxTable = iMaxTable;
    }

    //таблица загрузилась
    void        TableLoaded()
    {
       this.m_iTableLoaded++;
    }

    //проверка на загрузку бд
    bool        IsDatabaseLoaded()
    {
        if(this.m_iTableLoaded == this.m_iMaxTable && this.m_hDatabase!=INVALID_HANDLE)
            return true;

        return false;
    }

    //загрузить игрока
    bool        LoadUserId(int iClient, int iUserId)
    {
        if(!IsValidClient(iClient))
            return false;

        this.m_aUserIdLoaded[iClient] = 0;

        if(!this.IsDatabaseLoaded())
            return false;

        this.m_aUserIdLoaded[iClient] = iUserId;

        return true;
    }

    //выгрузить игрока
    void        UnLoadUserId(int iClient)
    {
        this.m_aUserIdLoaded[iClient] = 0;
    }

    //проверка на зугрузку игрока
    bool        IsUserIdLoaded(int iClient)
    {
        if(!IsValidClient(iClient))
            return false;

        if(!this.IsDatabaseLoaded())
            return false;

        if(!this.m_aUserIdLoaded[iClient])
            return false;

        return true;
    }

    //получить информацию о UserId игрока
    int        GetUserId(int iClient)
    {
        if(!this.IsUserIdLoaded(iClient))
            SetFailState("Database failure: Failed UserId");

        return this.m_aUserIdLoaded[iClient];
    }

    //получить индификатор клиента по UserId
    int       GetClientByUserId(int iUserId)
    {
        for(int i = 1 ; i < MaxClients; i++)
		{
			if(this.IsUserIdLoaded(i))
			{
				if(this.GetUserId(i) == iUserId)
				{	
					return  i;
				}
			}
		}

        return 0;
    }
}