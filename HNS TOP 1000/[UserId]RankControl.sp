#include "main\API\[UserId]Core.inc"

#include "main\Lib\Lib.sp"

//int g_Beam;
int g_iOffsetGround;
#define RANK_STAT 7

enum
{
	RANK = 0,
	POINTS,
	KILL,
	DEATH,
	ASSISTS,
	MONEY,
	TIME,
};
int g_aPlayerStats[MAXPLAYERS+1][RANK_STAT];



#define PLAYERFOLLOW 3

enum
{
	TIMEFOLLOW=0,
	TIMESTAND,
	TIMEPERCENT,
};
//////////////////////////////////////////////////////////////////////////////////////////
//struct for player abs
#define PLAYERABS 2

enum
{
	ABSNEW=0,
	ABSLAST,
};

//////////////////////////////////////////////////////////////////////////////////////////
//struct for 	follow dist
#define PLAYERFOLLOWDIST 2

enum
{
	DISTFOLLOW=0,
	TICKFOLLOW,
};

bool g_bSwithRound;
bool g_bSwithPlayer[MAXPLAYERS+1];
bool g_MatrixAssists[MAXPLAYERS+1][MAXPLAYERS+1];

float g_aPlayerFollow[MAXPLAYERS+1][PLAYERFOLLOW];
float g_PlayerAbs[MAXPLAYERS+1][PLAYERABS][3];
float g_PlayerAbsMas[MAXPLAYERS+1][25][3];
float g_Mytime;

int g_FollowDelay[MAXPLAYERS+1][MAXPLAYERS+1][2];
int g_iOwnerCount[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_Murder[MAXPLAYERS+1];

int g_iSwithFollow[MAXPLAYERS+1];


char RankStatspath[PLATFORM_MAX_PATH];

//частный случай для кажого плагина
Database    g_hDatabase;
int         g_iTableLoaded;
int        	g_iClientUserId[MAXPLAYERS  + 1];

#define MAX_TABLE 1
#define IsDatabaseLoadedDef (g_iTableLoaded==MAX_TABLE)
#define IsUserIdLoadedDef (IsDatabaseLoadedDef && g_iClientUserId[client])
//**********************************************************************


char sql_CRC_STATS[] 				= "CREATE TABLE IF NOT EXISTS RankStats (p INT, k INT, d INT, a INT , m INT, t INT, cmd INT, user_id INT PRIMARY KEY, FOREIGN KEY(user_id) REFERENCES UserId(user_id));";
char sql_SRC_STATS[] 				= "SELECT UserId.name, RankStats.p, RankStats.k, RankStats.d, RankStats.a, RankStats.m, RankStats.t, RankStats.cmd FROM RankStats JOIN UserId USING(user_id) WHERE user_id = %d;";
char sql_IRC_STATS[] 				= "INSERT INTO RankStats (user_id,p,k,d,a,m,t) VALUES(%d,0,0,0,0,0,0);";
char sql_URC_STATS[]            	= "UPDATE RankStats SET p = %d, k = %d, d = %d, a = %d, m = %d, t = %d, cmd = %d WHERE user_id = %d;";

char sql_SRC_CUR_RANK[]				= "SELECT COUNT(*) as count FROM RankStats WHERE p>=%d;";

char sql_SRC_REC[]            	    = "SELECT UserId.name, RankStats.p, RankStats.k, RankStats.d, RankStats.a, RankStats.m, RankStats.t FROM RankStats JOIN UserId USING(user_id) WHERE RankStats.p >= %d ORDER BY RankStats.p %s;";
#define Save_PlayerStats g_aPlayerStats[client][POINTS],g_aPlayerStats[client][KILL],g_aPlayerStats[client][DEATH],g_aPlayerStats[client][ASSISTS],g_aPlayerStats[client][MONEY],g_aPlayerStats[client][TIME],g_iSwithFollow[client],UserId

#include "main\[UserId]RankControl\RCSql.sp"
#include "main\[UserId]RankControl\RCCalc.sp"
#include "main\[UserId]RankControl\RCMenu.sp"

public Plugin myinfo = 
{
	name = "[UserId]RankControl",
	author = PLUGIN_AUTHOR,
	description = "RankControl",
	version = PLUGIN_VERSION,
}

public void OnPluginStart()
{
	IsDatabaseLoaded(OnConnected);
	
	if ((g_iOffsetGround = FindSendPropInfo("CBasePlayer", "m_hGroundEntity")) < 1)
		SetFailState("Offset 'CBasePlayer'::'m_hGroundEntity' not found!");

	HookEvent("player_death", Event_PlayerDeath,EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd,EventHookMode_Post); 
	HookEvent("round_start", Event_RoundStart,EventHookMode_Post); 
	HookEvent("player_hurt", Event_PlayerHurt);

	RegConsoleCmd("sm_hnsrank", Client_Top, "rank top");

	CreateTimer(0.1, Timer_Mytime, _, TIMER_REPEAT);
	BuildPath(Path_SM, RankStatspath, sizeof(RankStatspath), "logs/MultiServer/lvl.log");

	

	for(int i = 0 ; i < MaxClients; i++)
	{
		if(IsValidClient(i))
			OnClientPostAdminCheck(i);
	}
}

public void OnConnected(Database hDatabase)
{
	g_hDatabase = hDatabase;

	hDatabase.Query(SQLQueryCallback_RCSql_BaseLoaded, sql_CRC_STATS);

}

public Action OnClientCommandKeyValues(int client, KeyValues kv) 
{ 
	if(IsValidClient(client))
	{
		char sCmd[64]; 
		if (kv.GetSectionName(sCmd, sizeof(sCmd)) && StrEqual(sCmd, "ClanTagChanged", false)) 
		{ 
			char szValue[128];

			if(g_aPlayerStats[client][POINTS]>20)
			{
				if(g_aPlayerStats[client][RANK]>=1000)
				{
					Format(szValue, sizeof(szValue), "[Rank %dk+]", g_aPlayerStats[client][RANK]/1000);
				}
				else
				{
					Format(szValue, sizeof(szValue), "[Rank %d]", g_aPlayerStats[client][RANK]);
				}
			}	
			else 
				Format(szValue, sizeof(szValue), "[NEW]");

			if(IsValidClient(client))
				CS_SetClientClanTag(client,	szValue);

			return Plugin_Handled;
		}
	}
	return Plugin_Continue; 
}

public void OnMapStart()
{
	//g_Beam = PrecacheModel("materials/sprites/laserbeam.vmt");

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

	CreateTimer(1.0, Timer_OnClientPostAdminCheck, client, TIMER_REPEAT);
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

	for(int i=0;i<RANK_STAT;i++)
	g_aPlayerStats[client][i]=0;

	g_bSwithPlayer[client]=false;
	g_iSwithFollow[client]=0;
	

	for(int i=0;i<PLAYERFOLLOW;i++)
		g_aPlayerFollow[client][i]=0.0;

	for(int i=0;i<PLAYERABS;i++)
		for(int j=0;j<3;j++)
			g_PlayerAbs[client][i][j]=0.0;

	SetRank(client);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	
	int target;
	if ((target = GetEntDataEnt2(client, g_iOffsetGround)) > 0 && target <= MaxClients && GetClientTeam(client) != GetClientTeam(target))
	{	
		if(!IsValidClient(client) || !IsValidClient(target))
			return Plugin_Continue;

		if(!g_iClientUserId[client] || !g_iClientUserId[target])
			return Plugin_Continue;

		if(g_Mytime-g_iOwnerCount[client][target]>=2)
		{
			g_iOwnerCount[client][target]=RoundToCeil(g_Mytime);
			if (g_bSwithRound)
			{
				//client овнит
				//target заовненный
				if(GetClientTeam(client)==2 && GetClientTeam(target)==3)
				if(g_aPlayerStats[target][POINTS]>=5 && g_bSwithPlayer[client] && g_bSwithPlayer[target])
				if(GetEntityMoveType(client) != MOVETYPE_LADDER && GetEntityMoveType(target) != MOVETYPE_LADDER){
					//PointsOperation(client,5);
					PointsOperation(target,-5);
					PrintToChat(target,"\x01\04 \x04CYBERSHOKE \x01| \x01Вы потеряли  \x07%d поинт (у вас: \x02%d) за \x04 Head Own",5,g_aPlayerStats[target][POINTS]);
					//PrintToChat(client,"\x01\04 \x04CYBERSHOKE \x01| \x03Вы заработали  \x07%d поинт \x09(у вас: %d) \x0Bза Head Own",5,g_aPlayerStats[client][POINTS]);
				}		
			}	
		}
	}

	return Plugin_Continue;
}


static void Event_PlayerDeath(Handle event, const char[] sEvName, bool bDontBroadcast)   
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker")); 

	if(!IsValidClient(client) || !IsValidClient(attacker))
			return;

	if(!g_iClientUserId[client] || !g_iClientUserId[attacker])
			return;

	if(g_bSwithRound)
	{
		if(client==attacker)
		{
			g_aPlayerStats[client][DEATH]++;
			PointsOperation(client,-3);
			PrintToChat(client,"\x01\04 \x04CYBERSHOKE \x01| \x01Вы потеряли  \x07%d \x01поинт (у вас: \x02%d) \x01за \x04 суицид", 3, g_aPlayerStats[client][POINTS]);	
		}
		else if(attacker==0)
		{
			g_aPlayerStats[client][DEATH]++;
			int PIE=PlayerDeath(client);
			PointsOperation(client,-PIE);
			PrintToChat(client,"\x01\04 \x03[\x07RC\x03] \x01Вы потеряли  \x07%d \x01поинт (у вас: \x02%d) \x01за \x04 падение",PIE,g_aPlayerStats[client][POINTS]);
			for(int i=1;i<=MaxClients;i++)
				if(g_MatrixAssists[client][i] && attacker!=i && IsValidClient(i))
			{
				g_aPlayerStats[i][ASSISTS]++;
				PIE=PlayerAssist(i);
				PointsOperation(i,PIE);
				PrintToChat(i,"\x01\04 \x04CYBERSHOKE \x01| \x01Вы заработали  \x07%d \x01поинт (у вас: \x02%d) \x01за \x04 ассист",PIE,g_aPlayerStats[i][POINTS]);
				g_Murder[i]++;
			}	
		}
		else if(attacker!=0 && client!=0)
		{
			g_aPlayerStats[client][DEATH]++;
			g_aPlayerStats[attacker][KILL]++;	
			int PieAttacer=PlayerKill(attacker);
			int PieClient=PlayerDeath(attacker);
			PointsOperation(client,-PieClient);
			PointsOperation(attacker,PieAttacer);
			
			PrintToChat(client,"\x01\04 \x04CYBERSHOKE \x01| \x01Вы потеряли  \x07%d \x01поинт (у вас: \x02%d) \x01за \x04 смерть",PieClient,g_aPlayerStats[client][POINTS]);
			PrintToChat(attacker,"\x01\04 \x04CYBERSHOKE \x01| \x01Вы заработали  \x07%d \x01поинт (у вас: \x02%d) \x01за \x04 убийство",PieAttacer,g_aPlayerStats[attacker][POINTS]);
			for(int i=1;i<=MaxClients;i++)
				if(g_MatrixAssists[client][i] && attacker!=i && IsValidClient(i))
			{
				g_aPlayerStats[i][ASSISTS]++;
				int PIE=PlayerAssist(i);
				PointsOperation(i,PIE);
				PrintToChat(i,"\x01\04 \x04CYBERSHOKE \x01| \x01Вы заработали  \x07%d \x01поинт (у вас: \x02%d) \x01за \x04 ассист",PIE,g_aPlayerStats[i][POINTS]);
				g_Murder[i]++;
			}
			g_Murder[attacker]++;
		}
	}
}

static void Event_RoundEnd(Handle event, const char[] sEvName, bool bDontBroadcast) 
{ 
	g_bSwithRound=false;
	for(int client=1;client<=MaxClients;client++)
		if(IsValidClient(client))
	{
		if(g_iClientUserId[client])
		{
			if(GetClientTeam(client)==2 && g_bSwithPlayer[client])
			{	
				int PIE=RoundWin(client);
				PointsOperation(client,PIE);
				PrintToChat(client,"\x01\04 \x04CYBERSHOKE \x01| \x01Вы заработали  \x07%d \x01поинт (у вас: \x02%d) \x01за \x04 победный раунд",PIE,g_aPlayerStats[client][POINTS]);
			}
			if(GetClientTeam(client)==3 && g_bSwithPlayer[client])
			{
				int PIE=RoundLost(client);
				PointsOperation(client,-PIE);
				PrintToChat(client,"\x01\04 \x04CYBERSHOKE \x01| \x01Вы потеряли  \x07%d \x01поинт (у вас: \x02%d) \x01за \x04проигрыш",PIE,g_aPlayerStats[client][POINTS]);
			}
			g_bSwithPlayer[client]=false;	
		}
		
	}

}

static void Event_RoundStart(Handle event, const char[] sEvName, bool bDontBroadcast) 
{ 
	g_bSwithRound=true;

	if(GameRules_GetProp("m_bWarmupPeriod")==1) 
		g_bSwithRound=false;

	for(int client=1;client<=MaxClients;client++)
		if(IsValidClient(client))
	{
		if(g_iClientUserId[client])
		{
			g_Murder[client]=0;

			CreateTimer(12.0, g_Enable, client);

			float AbsOrigin[3];
			GetClientAbsOrigin(client, AbsOrigin);

			for(int i=0;i<25;i++) 
				g_PlayerAbsMas[client][i]=AbsOrigin;

			for(int i=0;i<PLAYERFOLLOW;i++) 
				g_aPlayerFollow[client][i]=0.0;
		}
	}
	for(int attacker=1;attacker<=MaxClients;attacker++)
		for(int client=1;client<=MaxClients;client++) 
			g_MatrixAssists[attacker][client]=false;
}

static Action g_Enable(Handle tmr, any client) 
{ 
	if(IsValidClient(client)) 
	{
		if(GetClientTeam(client)!=1)
			g_bSwithPlayer[client]=true;
		else 
			g_bSwithPlayer[client]=false;
	}

	return Plugin_Stop;
}

static void Event_PlayerHurt(Handle event, const char[] sEvName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker")); 

	if(!IsValidClient(client) || !IsValidClient(attacker))
			return;

	if(!g_iClientUserId[client] || !g_iClientUserId[attacker])
			return;

	if(client!=0 && attacker!=0 && (client != attacker))
		g_MatrixAssists[client][attacker]=true;
}

//////////////////////////////////////////////////////////////////////////////////////////
//TIMER
static Action Timer_Mytime(Handle timer, any data)
{
	g_Mytime+=0.1;
	
	if(RoundToCeil(g_Mytime*10) % 600==0)
	{
		
		for(int client=1;client<=MaxClients;client++)
			if(IsValidClient(client))
				if(GetClientTeam(client)!=1)
					if(g_iClientUserId[client])
		{
			
			g_aPlayerStats[client][TIME]++;
			/*
			for(int i=0;i<5;i++)
				if(g_Things[client][i][0]==1)
			{
				g_Things[client][i][1]--;
				if(g_Things[client][i][1]<=0)
				{
					g_Things[client][i][0]=0;
					g_Things[client][i][1]=0;
					g_aPlayerStats[client][g_MONEY]=g_aPlayerStats[client][g_MONEY]+(i+1)*1400;	
					PrintToChat(client,"\x01\04 \x03[\x07RC\x03] \x04You \x04get \x07%d \x03money \x04for Solar panel \x07#%d",(i+1)*1400,i+1);
				}
				g_SaveRank(client);
				g_SaveThings(client);
			}
			*/
			if(g_aPlayerStats[client][TIME]>10)
				SaveRank(client);
		}
	}
	
	
	for(int client=1;client<=MaxClients;client++)
		if(IsValidClient(client) && g_iClientUserId[client])
	{		

		if(RoundToCeil(g_Mytime*10) % 300==0)
		{
			char szQuery[512];
			Format(szQuery, sizeof(szQuery),sql_SRC_CUR_RANK,g_aPlayerStats[client][POINTS],"");
			g_hDatabase.Query(SQLQueryCallback_SetRec,szQuery,GetClientUserId(client));
		}

		float AbsOrigin[3];
		GetClientAbsOrigin(client, AbsOrigin);
		g_PlayerAbs[client][ABSNEW]=AbsOrigin;

		for(int i=24;i>0;i--) 
			g_PlayerAbsMas[client][i]=g_PlayerAbsMas[client][i-1];

		g_PlayerAbsMas[client][0]=AbsOrigin;

		if(GetClientTeam(client)!=1)
		{
			g_aPlayerFollow[client][TIMESTAND]+=1.0;
			g_aPlayerFollow[client][TIMEPERCENT]=g_aPlayerFollow[client][TIMEFOLLOW]/g_aPlayerFollow[client][TIMESTAND];
		}
		// if(GetClientTeam(client)==2 && IsPlayerAlive(client))
		if(GetClientTeam(client)==2 && IsPlayerAlive(client))
		{
			for(int i=1;i<=MaxClients;i++)
				if(IsValidClient(i)) 
					if(GetClientTeam(i)==3 && IsPlayerAlive(i))
			{	
				int icalc=calc(g_PlayerAbsMas[client],g_PlayerAbsMas[i],25,i,client);
				int f=icalc%100;
				int dist=icalc/100;
				if(f<100 && f>0)
				{
					g_FollowDelay[i][client][TICKFOLLOW]++;	
					if(g_FollowDelay[i][client][TICKFOLLOW]>3)
					{
						if(g_FollowDelay[i][client][TICKFOLLOW]>10)
							g_FollowDelay[i][client][TICKFOLLOW]=10;

						g_aPlayerFollow[i][TIMEFOLLOW]+=0.9;//ct

						float koef;

						if(dist<=8)
							koef=1.0;

						if(dist>8)
							koef=(1.2-float(dist)/40.0);
						//adm 
						char steam[32];

						if(!GetClientAuthId(client, AuthId_Engine, steam, sizeof(steam)))
							return;

						g_aPlayerFollow[client][TIMEFOLLOW]+=koef/SquareRoot(float(GetNumberCTFollowT(client)))*1.4;
					
						g_FollowDelay[i][client][DISTFOLLOW]=dist; 

						// if(g_iSwithFollow[i]==1 && IsClientAdmin(i))
						/*if(g_iSwithFollow[i]==1)
						{
							TE_SetupBeamPoints(g_PlayerAbs[client][ABSNEW], g_PlayerAbs[client][ABSLAST],  g_Beam, 0, 0, 0, 1.0, 1.5, 1.5, 2, 0.0, {255,0,0,155}, 0);
							TE_SendToClient(i);
						}*/
					}
				}
				else 
				{
					if(g_FollowDelay[i][client][TICKFOLLOW]>0)
					{
						g_FollowDelay[i][client][TICKFOLLOW]--;
					}		
				}
			}
		}
		g_PlayerAbs[client][ABSLAST]=AbsOrigin;	

		//if(g_iSwithFollow[client]==1)
		// if(g_iSwithFollow[client]==1 && IsClientAdmin(client))
		SendHud(client);
	}
}

static void SendHud(int client)
{
	char buf[512];  
	if(GetClientTeam(client)==2)//t
	{
		/*Format(buf, sizeof(buf), " Death -%d\n round Win + %d \n for kill +%d \n for assist +%d \n KDA %.2f \n KF %.2f\n",PlayerDeath(client),
																									RoundWin(client),
																									PlayerKill(client),
																									PlayerAssist(client),
																									GetKDA(client),
																									GetFollow(client));*/
		if(IsPlayerAlive(client))
			for(int i=1;i<MaxClients;i++)
				if(IsValidClient(i)) 
					if(GetClientTeam(i)==3 && IsPlayerAlive(i) && g_FollowDelay[i][client][TICKFOLLOW]>0)
		{
			Format(buf, sizeof(buf),"%s\n behind: %N (%d)",buf,i,g_FollowDelay[i][client][DISTFOLLOW]);
		}
		//SetHudTextParams(0.01, 0.01, 0.1, 100, 100, 255, 100, 0, 0.0, 0.2, 0.0);
		SetHudTextParams(0.01, 0.01, 0.2, 100, 100, 255, 255, 0.0, 0.0, 0.0, 0.0);
		ShowHudText(client, 4, buf);
	}
	if(GetClientTeam(client)==3)//ct
	{
		/*Format(buf, sizeof(buf), " Death -%d\n round Loss - %d \n for kill +%d \n for assist +%d \n KDA %.2f \n KF %.2f\n",PlayerDeath(client),
																									RoundLost(client),
																									PlayerKill(client),
																									PlayerAssist(client),
																									GetKDA(client),
																									GetFollow(client));     */
		if(IsPlayerAlive(client))
			for(int i=1;i<MaxClients;i++)
				if(IsValidClient(i)) 
					if(GetClientTeam(i)==2 && IsPlayerAlive(i) && g_FollowDelay[client][i][TICKFOLLOW]>0)
		{
			Format(buf, sizeof(buf),"%s\n %N (%d)",buf,i,g_FollowDelay[client][i][DISTFOLLOW]);
		}
		SetHudTextParams(0.01, 0.01, 0.2, 100, 100, 255, 255, 0.0, 0.0, 0.0, 0.0);
		ShowHudText(client, 4, buf);
	}
}

public void OnClientDisconnect(int client)
{
	g_iClientUserId[client] = 0;

	for(int i=0;i<RANK_STAT;i++)
		g_aPlayerStats[client][i]=0;

	g_bSwithPlayer[client]=false;
	g_iSwithFollow[client]=0;
	

	for(int i=0;i<PLAYERFOLLOW;i++)
		g_aPlayerFollow[client][i]=0.0;

	for(int i=0;i<PLAYERABS;i++)
		for(int j=0;j<3;j++)
			g_PlayerAbs[client][i][j]=0.0;
}