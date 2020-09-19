#include "main\API\[UserId]Core.inc"

#include "main\Lib\Lib.sp"


/* Ядерные переменные *///////////////////////////
#define MAXSTR 20								//
//////////////////////////////////////////////////
bool g_bMakeDuck[MAXPLAYERS+1];					//
bool g_bMakeLadder[MAXPLAYERS+1];				//
bool g_bMakeJump[MAXPLAYERS+1];					//
bool g_bPlayerOnGround[MAXPLAYERS+1];			//
//////////////////////////////////////////////////
float g_fPlayerAbs[MAXPLAYERS+1][2][3];			//
float g_fPlayerAbsCheck[MAXPLAYERS+1][2][3];	//
float g_fPlayerAngLast[MAXPLAYERS+1];			//
float g_fPlayerSpeedLast[MAXPLAYERS+1];			//
int g_iHud[MAXPLAYERS+1][2];					//
//////////////////////////////////////////////////
bool g_bStrafe[MAXPLAYERS+1][2];				//
//////////////////////////////////////////////////
#define EVENT_GROUND_0 0						//	
#define EVENT_GROUND_1 1						//
#define EVENT_GROUND_2 2						//
#define EVENT_GROUND_NUMBER 3					//
#define EVENT_TICKOAFTERLADDER 3				//
#define EVENT_TICKONGROUND 4					//
#define EVENT_TICKONGROUNDLAST 5				//
#define EVENT_TICKONGROUNDLAST2 6				//		
#define EVENT_TICKBTW 7							//		
#define EVENT_MUCH 8							//
enum											//
{												//
	EVENT_JUMP = 1,    							//
	EVENT_DUCK = 2,        						//
	EVENT_LADDER = 3,        					//
	STEP_EVENT = 3,								//
};												//
int g_aPlayerSteps[MAXPLAYERS+1][EVENT_MUCH];	//
float g_aPlayerGround[MAXPLAYERS+1][EVENT_GROUND_NUMBER];
int g_aPlayerCH[MAXPLAYERS+1][3];				//
//////////////////////////////////////////////////


/* Описание типов прыжков *///////////////////////
#define JUMP_PATTERN 10							//
enum											//
{												//
	NONE_JUMP = -1,								//
	LJ_JUMP,									//
	BH_JUMP,									//
	MBH_JUMP,									//
	BCJ_JUMP,									//
	CJ_JUMP,									//
	CBHJ_JUMP,									//
	MCJ_JUMP,									//
	LAJ_JUMP,									//
	LABJ_JUMP,									//
	LACJ_JUMP,									//
};												//
//////////////////////////////////////////////////


/* Описание типа статистик прыжка *///////////////
#define JUMP_STATS 7							//
enum											//
{												//
	LAST_JUMP = 0,								//
	PRE_JUMP,									//
	GAIN_JUMP,									//
	MAX_JUMP,									//
	SYNC_JUMP,									//
	SYNCFRAME_JUMP,								//
	HEIGHT_JUMP,								//
};												//
int g_iNumberStarfe[MAXPLAYERS+1];				//
float g_fJS[MAXPLAYERS+1][JUMP_STATS];			//
int g_iNumberStarfeSave[MAXPLAYERS+1];			//
float g_fJSSave[MAXPLAYERS+1][JUMP_STATS];		//
//////////////////////////////////////////////////


/* Описание типа статистик стрефов *//////////////
#define STR_STATS 6								//
enum											//
{												//
	FRAME_STR = 0,								//
	SYNC_STR ,									//
	GAIN_STR,									//
	MAX_STR,									//
	LOST_STR,									//
	AIRTIME_STR,								//
};												//
float g_fStrS[MAXPLAYERS+1][MAXSTR][STR_STATS];	//
//////////////////////////////////////////////////



char sql_CJS_CMD[] 				= "CREATE TABLE IF NOT EXISTS cmd (cmd INT, user_id INT PRIMARY KEY, FOREIGN KEY(user_id) REFERENCES UserId(user_id));";
char sql_SJS_CMD[] 				= "SELECT cmd FROM cmd WHERE user_id = %d;";
char sql_IJS_CMD[] 				= "INSERT INTO cmd (cmd, user_id) VALUES(%d, %d);";
char sql_UJS_CMD[]          	= "UPDATE cmd SET cmd = %d WHERE user_id = %d;";

#define STATS_PUT g_fJSSave[client][LAST_JUMP], g_iNumberStarfeSave[client], g_fJSSave[client][PRE_JUMP], g_fJSSave[client][MAX_JUMP], g_fJSSave[client][HEIGHT_JUMP], g_fJSSave[client][GAIN_JUMP], g_fJSSave[client][SYNC_JUMP]

char sql_CJS_JUMP[JUMP_PATTERN][] = {
"CREATE TABLE IF NOT EXISTS LJ   (rec FLOAT, str INT, pre FLOAT, max FLOAT, height FLOAT, gain FLOAT, sync FLOAT, user_id INT PRIMARY KEY, FOREIGN KEY(user_id) REFERENCES UserId(user_id));",
"CREATE TABLE IF NOT EXISTS BH   (rec FLOAT, str INT, pre FLOAT, max FLOAT, height FLOAT, gain FLOAT, sync FLOAT, user_id INT PRIMARY KEY, FOREIGN KEY(user_id) REFERENCES UserId(user_id));",
"CREATE TABLE IF NOT EXISTS MBH  (rec FLOAT, str INT, pre FLOAT, max FLOAT, height FLOAT, gain FLOAT, sync FLOAT, user_id INT PRIMARY KEY, FOREIGN KEY(user_id) REFERENCES UserId(user_id));",
"CREATE TABLE IF NOT EXISTS BCJ  (rec FLOAT, str INT, pre FLOAT, max FLOAT, height FLOAT, gain FLOAT, sync FLOAT, user_id INT PRIMARY KEY, FOREIGN KEY(user_id) REFERENCES UserId(user_id));",
"CREATE TABLE IF NOT EXISTS CJ   (rec FLOAT, str INT, pre FLOAT, max FLOAT, height FLOAT, gain FLOAT, sync FLOAT, user_id INT PRIMARY KEY, FOREIGN KEY(user_id) REFERENCES UserId(user_id));",
"CREATE TABLE IF NOT EXISTS CBHJ (rec FLOAT, str INT, pre FLOAT, max FLOAT, height FLOAT, gain FLOAT, sync FLOAT, user_id INT PRIMARY KEY, FOREIGN KEY(user_id) REFERENCES UserId(user_id));",
"CREATE TABLE IF NOT EXISTS MCJ  (rec FLOAT, str INT, pre FLOAT, max FLOAT, height FLOAT, gain FLOAT, sync FLOAT, user_id INT PRIMARY KEY, FOREIGN KEY(user_id) REFERENCES UserId(user_id));",
"CREATE TABLE IF NOT EXISTS LAJ  (rec FLOAT, str INT, pre FLOAT, max FLOAT, height FLOAT, gain FLOAT, sync FLOAT, user_id INT PRIMARY KEY, FOREIGN KEY(user_id) REFERENCES UserId(user_id));",
"CREATE TABLE IF NOT EXISTS LABJ (rec FLOAT, str INT, pre FLOAT, max FLOAT, height FLOAT, gain FLOAT, sync FLOAT, user_id INT PRIMARY KEY, FOREIGN KEY(user_id) REFERENCES UserId(user_id));",
"CREATE TABLE IF NOT EXISTS LACJ (rec FLOAT, str INT, pre FLOAT, max FLOAT, height FLOAT, gain FLOAT, sync FLOAT, user_id INT PRIMARY KEY, FOREIGN KEY(user_id) REFERENCES UserId(user_id));"};

char sql_SJS_JUMP[JUMP_PATTERN][]	= {
"SELECT UserId.name, LJ.rec,   LJ.str,   LJ.pre,   LJ.max,   LJ.height,   LJ.gain,   LJ.sync,   0 FROM LJ   JOIN UserId USING(user_id) WHERE UserId.user_id =%d",
"SELECT UserId.name, BH.rec,   BH.str,   BH.pre,   BH.max,   BH.height,   BH.gain,   BH.sync,   1 FROM BH   JOIN UserId USING(user_id) WHERE UserId.user_id =%d",
"SELECT UserId.name, MBH.rec,  MBH.str,  MBH.pre,  MBH.max,  MBH.height,  MBH.gain,  MBH.sync,  2 FROM MBH  JOIN UserId USING(user_id) WHERE UserId.user_id =%d",
"SELECT UserId.name, BCJ.rec,  BCJ.str,  BCJ.pre,  BCJ.max,  BCJ.height,  BCJ.gain,  BCJ.sync,  3 FROM BCJ  JOIN UserId USING(user_id) WHERE UserId.user_id =%d",
"SELECT UserId.name, CJ.rec,   CJ.str,   CJ.pre,   CJ.max,   CJ.height,   CJ.gain,   CJ.sync,   4 FROM CJ   JOIN UserId USING(user_id) WHERE UserId.user_id =%d",
"SELECT UserId.name, CBHJ.rec, CBHJ.str, CBHJ.pre, CBHJ.max, CBHJ.height, CBHJ.gain, CBHJ.sync, 5 FROM CBHJ JOIN UserId USING(user_id) WHERE UserId.user_id =%d",
"SELECT UserId.name, MCJ.rec,  MCJ.str,  MCJ.pre,  MCJ.max,  MCJ.height,  MCJ.gain,  MCJ.sync,  6 FROM MCJ  JOIN UserId USING(user_id) WHERE UserId.user_id =%d",
"SELECT UserId.name, LAJ.rec,  LAJ.str,  LAJ.pre,  LAJ.max,  LAJ.height,  LAJ.gain,  LAJ.sync,  7 FROM LAJ  JOIN UserId USING(user_id) WHERE UserId.user_id =%d",
"SELECT UserId.name, LABJ.rec, LABJ.str, LABJ.pre, LABJ.max, LABJ.height, LABJ.gain, LABJ.sync, 8 FROM LABJ JOIN UserId USING(user_id) WHERE UserId.user_id =%d",
"SELECT UserId.name, LACJ.rec, LACJ.str, LACJ.pre, LACJ.max, LACJ.height, LACJ.gain, LACJ.sync, 9 FROM LACJ JOIN UserId USING(user_id) WHERE UserId.user_id =%d"};

char sql_IJS_JUMP[JUMP_PATTERN][] = { 
"INSERT INTO LJ   (user_id) VALUES(%d);",
"INSERT INTO BH   (user_id) VALUES(%d);",
"INSERT INTO MBH  (user_id) VALUES(%d);",
"INSERT INTO BCJ  (user_id) VALUES(%d);",
"INSERT INTO CJ   (user_id) VALUES(%d);",
"INSERT INTO CBHJ (user_id) VALUES(%d);",
"INSERT INTO MCJ  (user_id) VALUES(%d);",
"INSERT INTO LAJ  (user_id) VALUES(%d);",
"INSERT INTO LABJ (user_id) VALUES(%d);",
"INSERT INTO LACJ (user_id) VALUES(%d);"};

char sql_UJS_JUMP[JUMP_PATTERN][] = {
"UPDATE LJ   SET rec = %f, str = %d, pre = %f, max = %f, height = %f, gain = %f, sync = %f WHERE user_id = ",
"UPDATE BH   SET rec = %f, str = %d, pre = %f, max = %f, height = %f, gain = %f, sync = %f WHERE user_id = ",
"UPDATE MBH  SET rec = %f, str = %d, pre = %f, max = %f, height = %f, gain = %f, sync = %f WHERE user_id = ",
"UPDATE BCJ  SET rec = %f, str = %d, pre = %f, max = %f, height = %f, gain = %f, sync = %f WHERE user_id = ",
"UPDATE CJ   SET rec = %f, str = %d, pre = %f, max = %f, height = %f, gain = %f, sync = %f WHERE user_id = ",
"UPDATE CBHJ SET rec = %f, str = %d, pre = %f, max = %f, height = %f, gain = %f, sync = %f WHERE user_id = ",
"UPDATE MCJ  SET rec = %f, str = %d, pre = %f, max = %f, height = %f, gain = %f, sync = %f WHERE user_id = ",
"UPDATE LAJ  SET rec = %f, str = %d, pre = %f, max = %f, height = %f, gain = %f, sync = %f WHERE user_id = ",
"UPDATE LABJ SET rec = %f, str = %d, pre = %f, max = %f, height = %f, gain = %f, sync = %f WHERE user_id = ",
"UPDATE LACJ SET rec = %f, str = %d, pre = %f, max = %f, height = %f, gain = %f, sync = %f WHERE user_id = "};

char sql_SJS_JUMPREC[JUMP_PATTERN][] = {
"SELECT UserId.name, LJ.rec,   LJ.str,   UserId.user_id FROM LJ   JOIN UserId USING(user_id) WHERE LJ.rec   >%f ORDER BY LJ.rec   %s",
"SELECT UserId.name, BH.rec,   BH.str,   UserId.user_id FROM BH   JOIN UserId USING(user_id) WHERE BH.rec   >%f ORDER BY BH.rec   %s",
"SELECT UserId.name, MBH.rec,  MBH.str,  UserId.user_id FROM MBH  JOIN UserId USING(user_id) WHERE MBH.rec  >%f ORDER BY MBH.rec  %s",
"SELECT UserId.name, BCJ.rec,  BCJ.str,  UserId.user_id FROM BCJ  JOIN UserId USING(user_id) WHERE BCJ.rec  >%f ORDER BY BCJ.rec  %s",
"SELECT UserId.name, CJ.rec,   CJ.str,   UserId.user_id FROM CJ   JOIN UserId USING(user_id) WHERE CJ.rec   >%f ORDER BY CJ.rec   %s",
"SELECT UserId.name, CBHJ.rec, CBHJ.str, UserId.user_id FROM CBHJ JOIN UserId USING(user_id) WHERE CBHJ.rec >%f ORDER BY CBHJ.rec %s",
"SELECT UserId.name, MCJ.rec,  MCJ.str,  UserId.user_id FROM MCJ  JOIN UserId USING(user_id) WHERE MCJ.rec  >%f ORDER BY MCJ.rec  %s",
"SELECT UserId.name, LAJ.rec,  LAJ.str,  UserId.user_id FROM LAJ  JOIN UserId USING(user_id) WHERE LAJ.rec  >%f ORDER BY LAJ.rec  %s",
"SELECT UserId.name, LABJ.rec, LABJ.str, UserId.user_id FROM LABJ JOIN UserId USING(user_id) WHERE LABJ.rec >%f ORDER BY LABJ.rec %s",
"SELECT UserId.name, LACJ.rec, LACJ.str, UserId.user_id FROM LACJ JOIN UserId USING(user_id) WHERE LACJ.rec >%f ORDER BY LACJ.rec %s"};

char szJumps[JUMP_PATTERN][] = {
"LongJump",
"BunnyHop",
"MultiBunnyHop",
"BunnyCountJump",
"CountJump",
"CountBunnyHopJump",
"MultiCountJump",	
"LadderJump",
"LadderBunnyHop",
"LadderCountJump"};

char szJumpsShort[JUMP_PATTERN][] = {
"LJ",
"BH",
"MBH",
"BCJ",
"CJ",
"CBHJ",
"MCJ",	
"LAJ",
"LABH",
"LACJ"};

char sql_SUserId[]         		= "SELECT UserId.user_id, 0 FROM SteamId JOIN UserId USING(user_id) WHERE SteamId.steamid ='%s' UNION SELECT UserId.user_id, 1 FROM Ip JOIN UserId USING(user_id) WHERE Ip.ip ='%s';";


#define Green_DOWNLOAD "sound/JumpStats_WithoutName/perfect.mp3"
#define Green_PLAY "*JumpStats_WithoutName/perfect.mp3"
#define Red_DOWNLOAD "sound/JumpStats_WithoutName/godlike.mp3"
#define Red_PLAY "*JumpStats_WithoutName/godlike.mp3"
#define Yellow_DOWNLOAD "sound/JumpStats_WithoutName/ownage.mp3"
#define Yellow_PLAY "*JumpStats_WithoutName/ownage.mp3"
#define RAMPAGE_DOWNLOAD "sound/JumpStats_WithoutName/rampage.mp3"
#define RAMPAGE_PLAY "*JumpStats_WithoutName/rampage.mp3"

enum
{
	REQUEST_NONE = -1,
	REQUEST_WHITE,
	REQUEST_BLUE,
	REQUEST_GREEN,
	REQUEST_RED,
	REQUEST_YELLOW,
	REQUEST_GOLD,
};

char szDirEnum[5][] = {
"fw",
"hsw",
"sw",
"bw",
"-"};

//для чата
char szRequest_White_Short[]     = "\x01\04 \x04CYBERSHOKE \x01| \x01%N \x08%s\x08: \x01%.2f \x08units \x03[\x01%s\x03]";
char szRequest_Blue_Short[]      = "\x01\04 \x04CYBERSHOKE \x01| \x0B%N \x08%s\x08: \x0B%.2f \x08units \x03[\x0B%s\x03]";
char szRequest_Green_Short[]     = "\x01\04 \x04CYBERSHOKE \x01| \x04%N \x08%s\x08: \x04%.2f \x08units \x03[\x04%s\x03]";
char szRequest_Red_Short[]       = "\x01\04 \x04CYBERSHOKE \x01| \x02%N \x08%s\x08: \x02%.2f \x08units \x03[\x02%s\x03]";
char szRequest_Yellow_Short[]    = "\x01\04 \x04CYBERSHOKE \x01| \x09%N \x08%s\x08: \x09%.2f \x08units \x03[\x09%s\x03]";
#define STATS_SHORT client, szType, g_fJS[client][LAST_JUMP], szDir

char szRequest_White_Long[]      = "\x01\04 \x04CYBERSHOKE \x01| \x01%N \x08%s\x08: \x01%.2f \x08units \x03[\x01%d \x08Strafes\x03|\x01%.1f \x08Pre\x03|\x01%.1f \x08Gain\x03|\x01%.1f \x08Max\x03|\x01%.1f%%%% \x08Sync\x03]\x03[\x01%s\x03]";
char szRequest_Blue_Long[]       = "\x01\04 \x04CYBERSHOKE \x01| \x0B%N \x08%s\x08: \x0B%.2f \x08units \x03[\x0B%d \x08Strafes\x03|\x0B%.1f \x08Pre\x03|\x0B%.1f \x08Gain\x03|\x0B%.1f \x08Max\x03|\x0B%.1f%%%% \x08Sync\x03]\x03[\x0B%s\x03]";
char szRequest_Green_Long[]      = "\x01\04 \x04CYBERSHOKE \x01| \x04%N \x08%s\x08: \x04%.2f \x08units \x03[\x04%d \x08Strafes\x03|\x04%.1f \x08Pre\x03|\x04%.1f \x08Gain\x03|\x04%.1f \x08Max\x03|\x04%.1f%%%% \x08Sync\x03]\x03[\x04%s\x03]";
char szRequest_Red_Long[]        = "\x01\04 \x04CYBERSHOKE \x01| \x02%N \x08%s\x08: \x02%.2f \x08units \x03[\x02%d \x08Strafes\x03|\x02%.1f \x08Pre\x03|\x02%.1f \x08Gain\x03|\x02%.1f \x08Max\x03|\x02%.1f%%%% \x08Sync\x03]\x03[\x02%s\x03]";
char szRequest_Yellow_Long[]     = "\x01\04 \x04CYBERSHOKE \x01| \x09%N \x08%s\x08: \x09%.2f \x08units \x03[\x09%d \x08Strafes\x03|\x09%.1f \x08Pre\x03|\x09%.1f \x08Gain\x03|\x09%.1f \x08Max\x03|\x09%.1f%%%% \x08Sync\x03]\x03[\x09%s\x03]";
#define STATS_LONG client, szType, g_fJS[client][LAST_JUMP], g_iNumberStarfe[client], g_fJS[client][PRE_JUMP], g_fJS[client][GAIN_JUMP], g_fJS[client][MAX_JUMP], g_fJS[client][SYNC_JUMP], szDir

//для консоле
char szRequest_Console[]               	 = "\n[JS] %N jumped %.3f units with a %s [%d Strafes | %.3f Pre | %.3f Max | Height %.3f | Gain %.3f | %.1f Sync]";
#define STATS_CONSOLE  client, g_fJS[client][LAST_JUMP], szType, g_iNumberStarfe[client], g_fJS[client][PRE_JUMP], g_fJS[client][MAX_JUMP], g_fJS[client][HEIGHT_JUMP], g_fJS[client][GAIN_JUMP], g_fJS[client][SYNC_JUMP]

char szRequest_Console_byStarfe[]        = "%s%3d. %8.2f %% %10.3f %14.3f %10.3f %10.2f %%\n";
#define STATS_CONSOLE_byStr i+1, g_fStrS[client][i][SYNC_STR], g_fStrS[client][i][GAIN_STR], g_fStrS[client][i][MAX_STR], g_fStrS[client][i][LOST_STR], g_fStrS[client][i][AIRTIME_STR]	

char szRequest_Console_byStarfePercent[] = "%s \x08%d.\x03[\x01%.1f\x03]";
#define STATS_CONSOLE_byStrPercent i+1, g_fStrS[client][i][SYNC_STR]

#define	SHOWSPEED_OPTION 	(1 << 0)
#define SENDTOCHAT_OPTION 	(1 << 1)
#define FULLSTATS_OPTION 	(1 << 2)
#define SOUND_GREEN_OPTION 	(1 << 3)
#define SOUND_RED_OPTION 	(1 << 4)
#define SOUND_YELLOW_OPTION (1 << 5)
#define SYNCINCHAT_OPTION 	(1 << 6)
#define ONLYMYSTATS_OPTION 	(1 << 7)

int g_iOptionStats[MAXPLAYERS+1];

float g_fJumpPattern[MAXPLAYERS+1][JUMP_PATTERN];



//частный случай для кажого плагина
Database    g_hDatabase;
int         g_iTableLoaded;
int        	g_iClientUserId[MAXPLAYERS  + 1];

#define MAX_TABLE 11
#define IsDatabaseLoadedDef (g_iTableLoaded==MAX_TABLE)
#define IsUserIdLoadedDef (IsDatabaseLoadedDef && g_iClientUserId[client])
//**********************************************************************

#include "main\[UserId]JST\JSEnter.sp"
#include "main\[UserId]JST\JSSql.sp"
#include "main\[UserId]JST\JSMenu.sp"


public Plugin myinfo = 
{
	name = "[UserId]JumpStats",
	author = PLUGIN_AUTHOR,
	description = "JS",
	version = PLUGIN_VERSION,
}

/** 
* Функция входа в плагин.
*/
public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	HookEvent("player_jump",Event_PlayerJump, EventHookMode_Pre);

	RegConsoleCmd("sm_js", Jump_Cmd, "js");
	RegConsoleCmd("sm_jt", Jump_Top, "jt");
	RegConsoleCmd("sm_stats", Jump_Rank, "stats");

	RegAdminCmd("sm_delstats", Jump_Delstats,ADMFLAG_ROOT, "del stats");
	
	CreateTimer(0.1, Timer_JS, _, TIMER_REPEAT);

	IsDatabaseLoaded(OnConnected);

	for(int i = 0 ; i < MaxClients; i++)
	{
		if(IsValidClient(i))
			OnClientPostAdminCheck(i);
	}
}

public void OnConnected(Database hDatabase)
{
	g_hDatabase = hDatabase;

	g_hDatabase.Query(SQLQueryCallback_JsSql_BaseLoaded ,sql_CJS_CMD);

	for(int i = 0; i< JUMP_PATTERN ;i++)
			g_hDatabase.Query(SQLQueryCallback_JsSql_BaseLoaded ,sql_CJS_JUMP[i]);	

}

/** 
* Функция удаления статисти.
*/
public Action Jump_Delstats(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: !delstats <steamid|#userid|name>");
		return Plugin_Handled;
	}

	char arg[50];
	GetCmdArgString(arg, sizeof(arg));

	int target = FindTarget(client, arg, true);
	if (target == -1)
	{
		ReplaceString(arg, sizeof(arg), "\"", "");	

		int ban_flags;
		if (IsCharNumeric(arg[0]))
		{
			ban_flags |= BANFLAG_IP;
		}
		else
		{
			ban_flags |= BANFLAG_AUTHID;
		}
		
		
		char szQuery[256];
		Format(szQuery, sizeof(szQuery),sql_SUserId,arg,"");
		g_hDatabase.Query(SQLQueryCallback_Delete_statsUserId,szQuery);

		return Plugin_Handled;
	}
	
	
	Delete_stats(target);

	return Plugin_Handled;
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

	CreateTimer(0.1, Timer_OnClientPostAdminCheck, client, TIMER_REPEAT);
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
	StepToAct(0, g_aPlayerSteps[client], true);
	ResetJump(client);

	g_iHud[client][0] = 0;
	g_iHud[client][1] = 0;

	for(int i = 0 ; i < JUMP_STATS ; i++)
		g_fJSSave[client][i] = 0.0;

	for(int i = 0 ; i < JUMP_PATTERN ; i++)
		g_fJumpPattern[client][i] = -999.0;

	g_iNumberStarfeSave[client] = 0;

	SetJumpCmd(client);
	SetJumpStats(client);
}

/**
* Функция обработки каждого тика.
*/
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(!IsPlayerAlive(client) || !IsValidClient(client))
		return Plugin_Continue;

	if(!g_iClientUserId[client])
		return Plugin_Continue;

	CheckInvalidJump(client);
	CalcJumpStats(client);
	CalcJumpSync(client, buttons);
	Event_PlayerLadder(client);
	Event_PlayerOnGround(client);
	Event_PlayerDuck(client, buttons);
		
	g_iHud[client][0] = buttons;

	return Plugin_Continue;
}

/**
* Функция события прыжка.
*/
static void Event_PlayerJump(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	if(!g_iClientUserId[client])
		return;
	
	StepToAct(EVENT_JUMP, g_aPlayerSteps[client], false);

	CheckBTW(client);
	PreJump(client,true);
}

/**
* Функция события ддрана.
*/
static void Event_PlayerDuck(int client, int buttons)
{
	if ( (buttons & IN_DUCK) && !(GetEntityFlags ( client ) & FL_DUCKING) && (GetEntityFlags(client) & FL_ONGROUND) )
	{
		if(!g_bMakeDuck[client])
		{
			g_bMakeDuck[client]=true;
			StepToAct(EVENT_DUCK, g_aPlayerSteps[client], false);

			CheckBTW(client);
			PreJump(client,true);	
		}
	}
	else if(g_bMakeDuck[client]) 
		g_bMakeDuck[client]=false;
}

/**
* Функция обработки игрока на лестнеце.
* @param[in] int client значение внутре игрового id.
*/
static void Event_PlayerLadder(int client)
{
	g_aPlayerSteps[client][EVENT_TICKOAFTERLADDER]++;
	if(GetEntityMoveType(client) == MOVETYPE_LADDER)
	{
		g_aPlayerSteps[client][EVENT_TICKOAFTERLADDER]=0;
		if(!g_bMakeLadder[client])
		{
			g_bMakeLadder[client]=true;
			StepToAct(EVENT_LADDER, g_aPlayerSteps[client], true);
		}
	}
	else if(g_bMakeLadder[client]) 
	{
		g_bMakeLadder[client] = false;
		
		PreJump(client,true);	
	}	
}

/**
* Функция обработки игрока на земле.
* @param[in] int client значение внутре игрового id.
*/
static void Event_PlayerOnGround(int client)
{
	if (GetEntityFlags(client) & FL_ONGROUND) 
	{
		SetPlayerSpeedOnGround(client,g_aPlayerSteps[client]);
		g_aPlayerSteps[client][EVENT_TICKONGROUND]++;
		CheckJB(client,true);
		
		if(g_aPlayerSteps[client][EVENT_TICKONGROUND] == 40)
		{
			ResetJump(client);
			StepToAct(0, g_aPlayerSteps[client], true);
		}
		
		if(!g_bPlayerOnGround[client])
		{	
			

			g_bPlayerOnGround[client] = true;
			if(g_bMakeJump[client])
				DoneJump(client);	

			
			g_aPlayerGround[client][EVENT_GROUND_2] = g_aPlayerGround[client][EVENT_GROUND_1];
			g_aPlayerGround[client][EVENT_GROUND_1] = g_aPlayerGround[client][EVENT_GROUND_0];
			
								
		}	
		float fVec[3];
		GetClientAbsOrigin (client,fVec);
		g_aPlayerGround[client][EVENT_GROUND_0] = fVec[2];
	}
	else 
	{
		if(g_aPlayerSteps[client][EVENT_TICKOAFTERLADDER]>10)
			CheckJB(client,false);
		else	
			CheckJB(client,true);

		if(g_bPlayerOnGround[client]) 
		{
			g_bPlayerOnGround[client] = false;
			g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST2] = g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST];
			g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST] = g_aPlayerSteps[client][EVENT_TICKONGROUND];
			g_aPlayerSteps[client][EVENT_TICKONGROUND]  = 0;			
		}
	}
}

/**
* Происходит после события EVENT_JUMP,EVENT_DUCK, EVENT_LADDER.
* Приготавливаемся к расчетам статистик.
* @param[in] int client значение внутре игрового id.
* @param[in] bool bMakeJump принимает значение
* ->false после EVENT_DUCK 
* ->true после EVENT_JUMP,EVENT_DUCK 
*/
static void PreJump(int client, bool bMakeJump)
{
	ResetJump(client);

	if(bMakeJump)
		g_bMakeJump[client] = true;
	else
		g_bMakeJump[client] = false;

	if(g_aPlayerSteps[client][0] == 3 && g_aPlayerSteps[client][1] == 0)
		GetClientAbsOrigin (client, g_fPlayerAbs[client][0]);
	else
		GetGroundOrigin (client, g_fPlayerAbs[client][0]);
	
	g_fJS[client][PRE_JUMP] = GetSpeed(client);
}

/**
* Происходит после полного завершения прыжка.
* Досчитываем статистику и выводим ее игроку.
* @param[in] int client значение внутре игрового id.
*/
static void DoneJump(int client)
{
	GetGroundOrigin (client, g_fPlayerAbs[client][1]);

	//досчет статистик
	//
	//высоты
	g_fJS[client][HEIGHT_JUMP]-=g_fPlayerAbs[client][1][2];

	//тики airtime
	float iTickForAirTime;
	for(int j=0;j < g_iNumberStarfe[client];j++) 
	{
		iTickForAirTime+=g_fStrS[client][j][AIRTIME_STR];
	}

	for(int i=0;i < g_iNumberStarfe[client];i++) 
	{
		//гейна общего
		g_fJS[client][GAIN_JUMP]+=g_fStrS[client][i][GAIN_STR];
		//sync на каждый стрейф
		g_fStrS[client][i][SYNC_STR] = g_fStrS[client][i][SYNC_STR] / g_fStrS[client][i][FRAME_STR] * 100.0;
		//airtime на каждый стрейф		
		g_fStrS[client][i][AIRTIME_STR] = g_fStrS[client][i][AIRTIME_STR]/iTickForAirTime * 100.0;
	}
	//sync общего
	g_fJS[client][SYNC_JUMP] = g_fJS[client][SYNC_JUMP] / g_fJS[client][SYNCFRAME_JUMP] * 100.0;	

	float fDifDist=g_fPlayerAbs[client][0][2]-g_fPlayerAbs[client][1][2];
	//PrintToChat(client,"%f %f ",g_fPlayerAbs[client][0][2],g_fPlayerAbs[client][1][2]);
	fDifDist=SquareRoot(fDifDist*fDifDist);

	float fDist=GetVectorDistance(g_fPlayerAbs[client][0],g_fPlayerAbs[client][1])+32;
	//PrintToChatAll("%N %d %d %d",client,g_aPlayerSteps[client][0],g_aPlayerSteps[client][1],g_aPlayerSteps[client][2]);
	
	switch(GetJumpPattern(g_aPlayerSteps[client]))
	{
		case LJ_JUMP:
		{
			if(fDifDist<0.0001 && g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST]>40 && g_fJS[client][PRE_JUMP]>200 && g_fJS[client][HEIGHT_JUMP]>54 && g_fJS[client][HEIGHT_JUMP]<67)
			{
				//тут расскоментил
				//PrintToChat(client,"dist=%.1f LJ dif=%.1f time=%d(0 1 4 > 10)",fDist,fDifDist,g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST]);
				g_fJS[client][LAST_JUMP] = fDist;

				if(g_fJS[client][PRE_JUMP]>=278.4)
					g_fJS[client][PRE_JUMP]=278.4;

				int TRequestCode = REQUEST_NONE;	

				if(fDist>280)
					TRequestCode = REQUEST_YELLOW;
				else if(fDist>275)
					TRequestCode = REQUEST_RED;
				else if(fDist>270)
					TRequestCode = REQUEST_GREEN;
				else if(fDist>265)
					TRequestCode = REQUEST_BLUE;
				else if(fDist>244)
					TRequestCode = REQUEST_WHITE;

				if(TRequestCode>REQUEST_NONE)
					SendJumpStatToChat(client,"LongJump",TRequestCode);
				return;
			}
		}
		case BH_JUMP:
		{
			if(fDifDist<0.0001 && g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST2]>40 && g_fJS[client][PRE_JUMP]>200 && g_fJS[client][HEIGHT_JUMP]>54 && g_fJS[client][HEIGHT_JUMP]<67 && GroundCheck(g_aPlayerGround[client],2))
			{
				//PrintToChat(client,"1=%d 2=%d 3=%d 4=%d",g_aPlayerSteps[client][EVENT_TICKONGROUND],g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST],g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST2],g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST3]);
				//PrintToChat(client,"dist=%.1f BH dif=%.1f time=%d(0 1 4 > 10)",fDist,fDifDist,g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST]);
				g_fJS[client][LAST_JUMP] = fDist;

				if(g_fJS[client][PRE_JUMP]>=280.4)
					g_fJS[client][PRE_JUMP]=280.4;

				int TRequestCode = REQUEST_NONE;		

				if(fDist>287)
					TRequestCode = REQUEST_YELLOW;
				else if(fDist>280)
					TRequestCode = REQUEST_RED;
				else if(fDist>275)
					TRequestCode = REQUEST_GREEN;
				else if(fDist>270)
					TRequestCode = REQUEST_BLUE;
				else if(fDist>260)
					TRequestCode = REQUEST_WHITE;

				if(TRequestCode>REQUEST_NONE)
					SendJumpStatToChat(client,"BunnyHop", TRequestCode);
				return;
			}			
		}
		case MBH_JUMP:
		{
			if(fDifDist<0.0001 && g_fJS[client][PRE_JUMP]>200 && g_fJS[client][HEIGHT_JUMP]>54 && g_fJS[client][HEIGHT_JUMP]<67 && GroundCheck(g_aPlayerGround[client],3))
			{
				//PrintToChat(client,"dist=%.1f MBH dif=%.1f time=%d(0 1 4 > 10)",fDist,fDifDist,g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST]);
				g_fJS[client][LAST_JUMP] = fDist;

				if(g_fJS[client][PRE_JUMP]>=285.9)
					g_fJS[client][PRE_JUMP]=285.9;

				int TRequestCode = REQUEST_NONE;	

				if(fDist>290)
					TRequestCode = REQUEST_YELLOW;
				else if(fDist>285)
					TRequestCode = REQUEST_RED;
				else if(fDist>275)
					TRequestCode = REQUEST_GREEN;
				else if(fDist>265)
					TRequestCode = REQUEST_BLUE;
				else if(fDist>260)
					TRequestCode = REQUEST_WHITE;

				if(TRequestCode>REQUEST_NONE)
					SendJumpStatToChat(client,"MultiBunnyHop", TRequestCode);
				return;
			}
		}
		case BCJ_JUMP:
		{
			if(fDifDist<0.0001 && g_fJS[client][PRE_JUMP]>200 && g_fJS[client][HEIGHT_JUMP]>54 && g_fJS[client][HEIGHT_JUMP]<67 && GroundCheck(g_aPlayerGround[client],2))
			{
				//PrintToChat(client,"dist=%.1f BCJ dif=%.1f time=%d(0 1 4 > 10)",fDist,fDifDist,g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST]);
				g_fJS[client][LAST_JUMP] = fDist;

				if(g_fJS[client][PRE_JUMP]>=291.4)
					g_fJS[client][PRE_JUMP]=291.4;

				int TRequestCode = REQUEST_NONE;	

				if(fDist>293)
					TRequestCode = REQUEST_YELLOW;
				else if(fDist>285)
					TRequestCode = REQUEST_RED;
				else if(fDist>280)
					TRequestCode = REQUEST_GREEN;
				else if(fDist>275)
					TRequestCode = REQUEST_BLUE;
				else if(fDist>260)
					TRequestCode = REQUEST_WHITE;

				if(TRequestCode>REQUEST_NONE)
					SendJumpStatToChat(client,"BunnyCountJump", TRequestCode);
				return;
			}
		}
		case CJ_JUMP:
		{
			if(fDifDist<0.0001 && g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST2]>40 && g_fJS[client][PRE_JUMP]>200 && g_fJS[client][HEIGHT_JUMP]>54 && g_fJS[client][HEIGHT_JUMP]<67  && GroundCheck(g_aPlayerGround[client],2))
			{
				//PrintToChat(client,"1=%d 2=%d 3=%d 4=%d",g_aPlayerSteps[client][EVENT_TICKONGROUND],g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST],g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST2],g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST3]);
				//PrintToChat(client,"dist=%.1f CJ dif=%.1f time=%d(0 1 4 > 10)",fDist,fDifDist,g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST]);
				g_fJS[client][LAST_JUMP] = fDist;

				if(g_fJS[client][PRE_JUMP]>=296.4)
					g_fJS[client][PRE_JUMP]=296.4;

				int TRequestCode = REQUEST_NONE;	

				if(fDist>295)
					TRequestCode = REQUEST_YELLOW;
				else if(fDist>285)
					TRequestCode = REQUEST_RED;
				else if(fDist>280)
					TRequestCode = REQUEST_GREEN;
				else if(fDist>270)
					TRequestCode = REQUEST_BLUE;
				else if(fDist>260)
					TRequestCode = REQUEST_WHITE;

				if(TRequestCode>REQUEST_NONE)
					SendJumpStatToChat(client,"CountJump", TRequestCode);
				return;
			}
		}
		case CBHJ_JUMP:
		{
			if(fDifDist<0.0001 && g_fJS[client][PRE_JUMP]>200 && g_fJS[client][HEIGHT_JUMP]>54 && g_fJS[client][HEIGHT_JUMP]<67 && GroundCheck(g_aPlayerGround[client],3))
			{
				//PrintToChat(client,"dist=%.1f CBHJ dif=%.1f time=%d(0 1 4 > 10)",fDist,fDifDist,g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST]);
				g_fJS[client][LAST_JUMP] = fDist;

				if(g_fJS[client][PRE_JUMP]>=291.4)
					g_fJS[client][PRE_JUMP]=291.4;

				int TRequestCode = REQUEST_NONE;

				if(fDist>293)
					TRequestCode = REQUEST_YELLOW;
				else if(fDist>285)
					TRequestCode = REQUEST_RED;
				else if(fDist>280)
					TRequestCode = REQUEST_GREEN;
				else if(fDist>275)
					TRequestCode = REQUEST_BLUE;
				else if(fDist>260)
					TRequestCode = REQUEST_WHITE;

				if(TRequestCode>REQUEST_NONE)
					SendJumpStatToChat(client,"CountBunnyHopJump", TRequestCode);
				return;
			}
		}
		case MCJ_JUMP:
		{
			if(fDifDist<0.0001 && g_fJS[client][PRE_JUMP]>200 && g_fJS[client][HEIGHT_JUMP]>54 && g_fJS[client][HEIGHT_JUMP]<67 && GroundCheck(g_aPlayerGround[client],3))
			{
				//PrintToChat(client,"dist=%.1f MCJ dif=%.1f time=%d(0 1 4 > 10)",fDist,fDifDist,g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST]);
				g_fJS[client][LAST_JUMP] = fDist;

				if(g_fJS[client][PRE_JUMP]>=302.4)
					g_fJS[client][PRE_JUMP]=302.4;

				int TRequestCode = REQUEST_NONE;

				if(fDist>300)
					TRequestCode = REQUEST_YELLOW;
				else if(fDist>295)
					TRequestCode = REQUEST_RED;
				else if(fDist>290)
					TRequestCode = REQUEST_GREEN;
				else if(fDist>280)
					TRequestCode = REQUEST_BLUE;
				else if(fDist>260)
					TRequestCode = REQUEST_WHITE;

				if(TRequestCode>REQUEST_NONE)
					SendJumpStatToChat(client,"MultiCountJump", TRequestCode);
				return;
			}
		}
		case LAJ_JUMP:
		{
			if(fDifDist<10.0 && g_fJS[client][PRE_JUMP]>20 && g_fJS[client][PRE_JUMP]<210 && g_fJS[client][HEIGHT_JUMP]>20 && g_fJS[client][HEIGHT_JUMP]<120)
			{
				//PrintToChat(client,"dist=%.1f LAJ dif=%.1f time=%d(0 1 4 > 10)",fDist,fDifDist,g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST]);
				g_fJS[client][LAST_JUMP] = fDist;

				int TRequestCode = REQUEST_NONE;	

				if(fDist>220)
					TRequestCode = REQUEST_YELLOW;
				else if(fDist>210)
					TRequestCode = REQUEST_RED;
				else if(fDist>200)
					TRequestCode = REQUEST_GREEN;
				else if(fDist>180)
					TRequestCode = REQUEST_BLUE;
				else if(fDist>100)
					TRequestCode = REQUEST_WHITE;

				if(TRequestCode>REQUEST_NONE)
					SendJumpStatToChat(client,"LadderJump", TRequestCode);
				return;
			}
		}
		case LABJ_JUMP:
		{
			if(fDifDist<0.0001 && g_fJS[client][PRE_JUMP]>200 && g_fJS[client][HEIGHT_JUMP]>54 && g_fJS[client][HEIGHT_JUMP]<67)
			{
				//PrintToChat(client,"dist=%.1f LABJ dif=%.1f time=%d(0 1 4 > 10)",fDist,fDifDist,g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST]);
				g_fJS[client][LAST_JUMP] = fDist;

				if(g_fJS[client][PRE_JUMP]>=291.4)
					g_fJS[client][PRE_JUMP]=291.4;

				int TRequestCode = REQUEST_NONE;	

				if(fDist>290)
					TRequestCode = REQUEST_YELLOW;
				else if(fDist>285)
					TRequestCode = REQUEST_RED;
				else if(fDist>280)
					TRequestCode = REQUEST_GREEN;
				else if(fDist>270)
					TRequestCode = REQUEST_BLUE;
				else if(fDist>260)
					TRequestCode = REQUEST_WHITE;

				if(TRequestCode>REQUEST_NONE)
					SendJumpStatToChat(client,"LadderBunnyHop", TRequestCode);
				return;
			}
		}
		case LACJ_JUMP:
		{
			if(fDifDist<0.0001 && g_fJS[client][PRE_JUMP]>200 && g_fJS[client][HEIGHT_JUMP]>54 && g_fJS[client][HEIGHT_JUMP]<67)
			{
				//PrintToChat(client,"dist=%.1f LACJ dif=%.1f time=%d(0 1 4 > 10)",fDist,fDifDist,g_aPlayerSteps[client][EVENT_TICKONGROUNDLAST]);
				g_fJS[client][LAST_JUMP] = fDist;

				if(g_fJS[client][PRE_JUMP]>=296.4)
					g_fJS[client][PRE_JUMP]=296.4;

				int TRequestCode = REQUEST_NONE;	

				if(fDist>293)
					TRequestCode = REQUEST_YELLOW;
				else if(fDist>288)
					TRequestCode = REQUEST_RED;
				else if(fDist>280)
					TRequestCode = REQUEST_GREEN;
				else if(fDist>270)
					TRequestCode = REQUEST_BLUE;
				else if(fDist>260)
					TRequestCode = REQUEST_WHITE;

				if(TRequestCode>REQUEST_NONE)
					SendJumpStatToChat(client,"LadderCountJump", TRequestCode);
				return;
			}
		}
	}
	g_fJS[client][LAST_JUMP] = 0.0;	
	ResetJump(client);
}

/**
* Обнуляем всю статистику прыжка.
* @param[in] int client значение внутре игрового id.
*/
public void ResetJump(int client)
{
	for(int i = 0 ; i < JUMP_STATS ; i++)
		g_fJS[client][i] = 0.0;

	g_fJS[client][HEIGHT_JUMP]=-9999.0;

	for(int i = 0 ; i < MAXSTR ; i++)
		for(int j = 0 ; j < STR_STATS ; j++)
			g_fStrS[client][i][j] = 0.0;

	g_iNumberStarfe[client]=0;		

	g_bMakeJump[client] = false;
	g_bStrafe[client][0] = false;
	g_bStrafe[client][1] = false;	
}

/**
* Проверки на ограничене прыжка .
* Сброс, прыжка если они есть.
* @param[in] int client значение внутре игрового id.
*/
static void CheckInvalidJump(int client)
{
	bool bFlag;

	if (GetEntityMoveType(client) == MOVETYPE_NOCLIP)
		bFlag = true;

	if (GetEntProp(client, Prop_Data, "m_nWaterLevel") > 0)
		bFlag = true;

	float flbaseVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", flbaseVelocity);
	if (flbaseVelocity[0] != 0.0 || flbaseVelocity[1] != 0.0 || flbaseVelocity[2] != 0.0)
		bFlag = true;

	if (!IsValidPlayerPos (client))
		if(g_aPlayerSteps[client][EVENT_TICKOAFTERLADDER]>10)
			bFlag = true;
	
	GetClientAbsOrigin (client, g_fPlayerAbsCheck[client][0]);
	if(GetVectorDistance(g_fPlayerAbsCheck[client][0],g_fPlayerAbsCheck[client][1])>50.0)
		bFlag = true;

	if(FloatAbs(g_fPlayerSpeedLast[client]-GetSpeed(client))>RadToDeg( ArcTangent( 30.0 / SquareRoot( g_fPlayerSpeedLast[client] ) )) && IsValidPlayerPos2(client) )
		bFlag = true;

	for(int i = 0 ; i < 3 ; i++)
		g_fPlayerAbsCheck[client][1][i] = g_fPlayerAbsCheck[client][0][i];

	if(bFlag)
	{
		StepToAct(0, g_aPlayerSteps[client], true);
		ResetJump(client);
	}
}

/**
* Допустимое положение для расчета прыжка.
* @param[in] int client значение внутре игрового id.
* return TRUE если положение допустимо
* return FALSE если положение не допустимо
*/
public bool IsValidPlayerPos2 (int client) 
{ 
	float vecPos [ 3 ]; 
	GetClientAbsOrigin  ( client , vecPos ); 

	float vecMins [3] = { - 18.0 , - 18.0 ,-5.0 }; 
	float vecMaxs [3] = { 18.0 , 18.0 , 72.0 }; 
	TR_TraceHullFilter ( vecPos , vecPos , vecMins , vecMaxs , MASK_SOLID , TraceFilter_IgnorePlayer , client ); 
	return ( ! TR_DidHit ( null ) ); 
} 

/**
* Допустимое положение для расчета прыжка.
* @param[in] int client значение внутре игрового id.
* return TRUE если положение допустимо
* return FALSE если положение не допустимо
*/
public bool IsValidPlayerPos (int client) 
{ 
	float vecPos [ 3 ]; 
	GetClientAbsOrigin  ( client , vecPos ); 

	float vecMins [3] = { - 18.0 , - 18.0 ,0.0 }; 
	float vecMaxs [3] = { 18.0 , 18.0 , 72.0 }; 
	TR_TraceHullFilter ( vecPos , vecPos , vecMins , vecMaxs , MASK_SOLID , TraceFilter_IgnorePlayer , client ); 
	return ( ! TR_DidHit ( null ) ); 
} 

/**
* Call back функции IsValidPlayerPos.
* Фильтр по которому ослеживается допустимость положения.
* @param[in] int entity объект проверки.
* @param[in] int mask параметр обработки.
* @param[in] any ignore_me значение своего внутре игрового id.
* return FALSE если положение не игнорируется.
* return TRUE если положение игнорируется.
*/
public bool TraceFilter_IgnorePlayer ( int entity , int mask , any ignore_me ) 
{	
	if (entity > 0 && entity <= MaxClients) 
	{ 
		if((GetClientTeam(entity)== 1 || GetClientTeam(entity)== 2 || GetClientTeam(entity)== 3) && (GetClientTeam(ignore_me)== 1 || GetClientTeam(ignore_me)== 2 || GetClientTeam(ignore_me)== 3)) 
			return false; 
		else 
			return true; 
	}
	else 
		return true; 
}

/**
* Расчитываем статистику прыжка.
* ->Высоту , максимальную скорость.
* @param[in] int client значение внутре игрового id.
*/
static void CalcJumpStats(int client)
{
	float height[3];
	GetClientAbsOrigin (client, height);

	if (height[2] > g_fJS[client][HEIGHT_JUMP]) 
		g_fJS[client][HEIGHT_JUMP] = height[2];	

	float speed = GetSpeed(client);
	if (speed > g_fJS[client][MAX_JUMP]) 
		g_fJS[client][MAX_JUMP] = speed;
}

/**
* Расчитываем статистику прыжка.
* ->sync, airtime ,gain, lost, strafes
* @param[in] int client значение внутре игрового id.
* @param[in] int buttons значение кнопок игрока.
*/
static void CalcJumpSync(int client, int buttons)
{
	if(g_iNumberStarfe[client]<MAXSTR)
	{
		bool turning_right = false;
		bool turning_left = false;

		float ang[3];
		GetClientEyeAngles(client, ang);
		float speed = GetSpeed(client);
		
		if( ang[1] < g_fPlayerAngLast[client])
			turning_right = true;
		else if( ang[1] > g_fPlayerAngLast[client])
			turning_left = true;	
		
		//strafestats
		if(turning_left || turning_right)
		{
			if( !g_bStrafe[client][0] && ((buttons & IN_FORWARD) || (buttons & IN_MOVELEFT)) && !(buttons & IN_MOVERIGHT) && !(buttons & IN_BACK) )
			{
				g_bStrafe[client][0] = true;
				g_bStrafe[client][1] = false;	

				g_iNumberStarfe[client]++; 

				g_fStrS[client][g_iNumberStarfe[client]-1][SYNC_STR] = 0.0;
				g_fStrS[client][g_iNumberStarfe[client]-1][FRAME_STR] = 0.0;		
				g_fStrS[client][g_iNumberStarfe[client]-1][MAX_STR] = speed;	
			}
			else if( !g_bStrafe[client][1] && ((buttons & IN_BACK) || (buttons & IN_MOVERIGHT)) && !(buttons & IN_MOVELEFT) && !(buttons & IN_FORWARD) )
			{
				g_bStrafe[client][0] = false;
				g_bStrafe[client][1] = true;

				g_iNumberStarfe[client]++; 

				g_fStrS[client][g_iNumberStarfe[client]-1][SYNC_STR] = 0.0;
				g_fStrS[client][g_iNumberStarfe[client]-1][FRAME_STR] = 0.0;		
				g_fStrS[client][g_iNumberStarfe[client]-1][MAX_STR] = speed;		
			}	

			if(g_iNumberStarfe[client]>0)
				g_fStrS[client][g_iNumberStarfe[client] - 1][AIRTIME_STR]++;	
		}	
		
		//sync
		if( g_fPlayerSpeedLast[client] < speed )
		{
			g_fJS[client][SYNC_JUMP]++;		
			if( 0 < g_iNumberStarfe[client] < MAXSTR )
			{
				g_fStrS[client][g_iNumberStarfe[client]-1][SYNC_STR]++;
				g_fStrS[client][g_iNumberStarfe[client]-1][GAIN_STR] += (speed - g_fPlayerSpeedLast[client]);
			}
		}	
		else 
		{
			if( g_fPlayerSpeedLast[client] > speed )
			{
				if( 0 < g_iNumberStarfe[client] < MAXSTR )
					g_fStrS[client][g_iNumberStarfe[client]-1][LOST_STR] += (g_fPlayerSpeedLast[client] - speed);
			}
		}

		//strafe frames
		if( 0 < g_iNumberStarfe[client] < MAXSTR )
		{
			g_fStrS[client][g_iNumberStarfe[client]-1][FRAME_STR]++;

			if( g_fStrS[client][g_iNumberStarfe[client]-1][MAX_STR] < speed )
				g_fStrS[client][g_iNumberStarfe[client]-1][MAX_STR] = speed;			
		}

		//total frames
		g_fJS[client][SYNCFRAME_JUMP]++;
		g_fPlayerAngLast[client]=ang[1];
		g_fPlayerSpeedLast[client]=speed;
	}
}

/**
* Узнать тип прыжка.
* @param[inout] int[] aPlayerSteps значение массива действий.
* return LJ_JUMP
* return BH_JUMP
* return MBH_JUMP
* return BCJ_JUMP
* return CJ_JUMP
* return CBHJ_JUMP
* return MCJ_JUMP
* return LAJ_JUMP
* return LABJ_JUMP
* return LACJ_JUMP
* return NONE_JUMP ошибка последовательности
*/
static int GetJumpPattern(int[] aPlayerSteps)
{
	if(aPlayerSteps[0] == 1 && aPlayerSteps[1] == 0 && aPlayerSteps[2] == 0)
		return LJ_JUMP;
	else if(aPlayerSteps[0] == 1 && aPlayerSteps[1] == 1 && aPlayerSteps[2] == 0)
		return BH_JUMP;
	else if(aPlayerSteps[0] == 1 && aPlayerSteps[1] == 1 && (aPlayerSteps[2] == 1 || aPlayerSteps[2] == 3))
		return MBH_JUMP;
	else if(aPlayerSteps[0] == 1 && aPlayerSteps[1] == 2 && aPlayerSteps[2] == 1)
		return BCJ_JUMP;
	else if(aPlayerSteps[0] == 1 && aPlayerSteps[1] == 2 && aPlayerSteps[2] == 0)
		return CJ_JUMP;
	else if(aPlayerSteps[0] == 1 && aPlayerSteps[1] == 1 && aPlayerSteps[2] == 2)
		return CBHJ_JUMP;
	else if(aPlayerSteps[0] == 1 && aPlayerSteps[1] == 2 && aPlayerSteps[2] == 2)
		return MCJ_JUMP;
	else if(aPlayerSteps[0] == 3 && aPlayerSteps[1] == 0 && aPlayerSteps[2] == 0)
		return LAJ_JUMP;
	else if(aPlayerSteps[0] == 1 && aPlayerSteps[1] == 3 && aPlayerSteps[2] == 0)
		return LABJ_JUMP;
	else if(aPlayerSteps[0] == 1 && aPlayerSteps[1] == 2 && aPlayerSteps[2] == 3)
		return LACJ_JUMP;
		
	return NONE_JUMP;
}

/**
* Устанавливаем максимальный престрейф на поверхности.
* @param[in] int client значение внутре игрового id.
* @param[inout] int[] aPlayerSteps значение массива действий.
*/
static void SetPlayerSpeedOnGround(int client, int[] aPlayerSteps)
{		
	if(aPlayerSteps[0] == 0 && aPlayerSteps[1] == 0)
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 253.0);
	else if(aPlayerSteps[0] == 1 && aPlayerSteps[1] == 0)
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 255.0);
	else if(aPlayerSteps[0] == 1 && aPlayerSteps[1] == 1)
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 260.0);
	else if(aPlayerSteps[0] == 2 && aPlayerSteps[1] == 1)
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 265.0);
	else if(aPlayerSteps[0] == 2 && aPlayerSteps[1] == 0)
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 270.0);
	else if(aPlayerSteps[0] == 1 && aPlayerSteps[1] == 2)
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 265.0);
	else if(aPlayerSteps[0] == 2 && aPlayerSteps[1] == 2)
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 275.0);
	else if(aPlayerSteps[0] == 3 && aPlayerSteps[1] == 0)
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 260.0);
	else if(aPlayerSteps[0] == 2 && aPlayerSteps[1] == 3)
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 265.0);
	else 
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 253.0);

	char szWeap[32];    
	GetClientWeapon(client,szWeap, sizeof(szWeap)); 

	if(!szWeap[0])
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 1.0);
}

/**
* Обработка дальнейших действий при новом акте.
* @param[in] int client значение внутре игрового id.
* @param[in] int TStep код шага.
* @param[inout] int[] aPlayerSteps массив акта игрока.
* @param[in] bool bReset флаг обнуления акта действий.
*/
public void StepToAct(int TStep, int[] aPlayerSteps, bool bReset)
{
	if(!bReset)
	{
		int iNumberStep;
		
		for(iNumberStep = 0 ; iNumberStep < STEP_EVENT ; iNumberStep++)
		{
			if(!aPlayerSteps[iNumberStep])
				break;
		}
		
		if(iNumberStep)
			for(int i = STEP_EVENT-1 ; i > 0 ; i--)
				aPlayerSteps[i] = aPlayerSteps[i-1];
	}
	else
	{
		for(int i = 0 ; i < STEP_EVENT ; i++)
		aPlayerSteps[i] = 0;
	}
	
	aPlayerSteps[0] = TStep;
}

/**
* Проверка крауч джампа.
* @param[in] int client значение внутре игрового id.
* return true,false
*/
static void CheckBTW(int client)
{
	if (!(GetGameTickCount()-g_aPlayerSteps[client][EVENT_TICKBTW]>10))
	{
		StepToAct(NONE_JUMP, g_aPlayerSteps[client], true);
	
	}
	//*PrintToChatAll("%d",GetGameTickCount()-g_aPlayerSteps[client][EVENT_TICKBTW]);
	
	g_aPlayerSteps[client][EVENT_TICKBTW]=GetGameTickCount();
}

static void CheckJB(int client,bool bFlag)
{
	if(!bFlag)
	{
		float fVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);

		if(fVelocity[2]>0)
		{
			if(!g_aPlayerCH[client][0])
			{
				g_aPlayerCH[client][0]=1;
				g_aPlayerCH[client][1]=0;
				g_aPlayerCH[client][2]++;
			}
		}
		if(fVelocity[2]<0)
		{
			if(!g_aPlayerCH[client][1])
			{
				g_aPlayerCH[client][1]=1;
				g_aPlayerCH[client][0]=0;
				g_aPlayerCH[client][2]++;
			}
		}
	}
	else
	{
		if(g_aPlayerCH[client][2]>2)
			ResetJump(client);

		for(int i=0;i<3;i++)
			g_aPlayerCH[client][i]=0;
	}
}
