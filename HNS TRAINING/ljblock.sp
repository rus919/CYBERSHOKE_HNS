#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

new g_Beam[2];


#define WHITE 0x01
#define DARKRED 0x02
#define PURPLE 0x03
#define GREEN 0x04
#define MOSSGREEN 0x05
#define LIMEGREEN 0x06
#define RED 0x07
#define GRAY 0x08
#define YELLOW 0x09
#define DARKGREY 0x0A
#define BLUE 0x0B
#define DARKBLUE 0x0C
#define LIGHTBLUE 0x0D
#define PINK 0x0E
#define LIGHTRED 0x0F
#define QUOTE 0x22
#define PERCENT 0x25
#define CPLIMIT 50 
#define MYSQL 0

new Float:g_fOriginBlock[MAXPLAYERS + 1][2][3];
new Float:g_fDestBlock[MAXPLAYERS + 1][2][3];
new Float:g_fBlockHeight[MAXPLAYERS + 1];
new Float:g_fEdgePoint[MAXPLAYERS + 1][3];
new Float:g_fEdgeVector[MAXPLAYERS + 1][3];
new g_BlockDist[MAXPLAYERS + 1];
new bool:g_bLJBlock[MAXPLAYERS + 1];
new bool:g_bLJBlockValidJumpoff[MAXPLAYERS + 1];
new bool:g_js_bPlayerJumped[MAXPLAYERS+1];
new bool:g_bLjStarDest[MAXPLAYERS + 1];
new Float:g_fEdgeDist[MAXPLAYERS + 1];

int g_iPatchRestore[100];
bool g_bNoclip[MAXPLAYERS+1];

ConVar g_cvAllowNoclip;

public void OnPluginStart()
{
	LoadTranslations("kzjumpstats.phrases");
	RegConsoleCmd("sm_ljblock", Client_Ljblock,"registers a lj block");

	g_cvAllowNoclip = CreateConVar("fj_noclip", "1.0", "Allow players noclip, 1 to allow, 0 to disable", FCVAR_NOTIFY, true, 0.0, true, 1.0);


	g_iAllowNoclip = GetConVarInt(g_cvAllowNoclip);
	HookConVarChange(g_cvAllowNoclip, OnSettingChanged);

	g_iAllowNoclip = GetConVarInt(g_cvAllowNoclip);
	HookConVarChange(g_cvAllowNoclip, OnSettingChanged);
}

public int OnSettingChanged(ConVar convar, char[] oldValue, char[] newValue) {

	if(convar == g_cvAllowNoclip)
		g_iAllowNoclip = StringToInt(newValue[0]);
}

public void OnClientPutInServer(int client) {

	g_bNoclip[client] = false;
}

public OnMapStart()
{
	g_Beam[0] = PrecacheModel("materials/sprites/laser.vmt");
	g_Beam[1] = PrecacheModel("materials/sprites/halo01.vmt");
}

CorrectEdgePoint(client)
{
	decl Float:vec[3];
	vec[0] = 0.0 - g_fEdgeVector[client][1];
	vec[1] = g_fEdgeVector[client][0];
	vec[2] = 0.0;
	ScaleVector(vec, 16.0);
	AddVectors(g_fEdgePoint[client], vec, g_fEdgePoint[client]);
}

GetEdgeOrigin(client, Float:ground[3], Float:result[3])
{
	result[0] = (g_fEdgeVector[client][0]*ground[0] + g_fEdgeVector[client][1]*g_fEdgePoint[client][0] ) / (g_fEdgeVector[client][0]+g_fEdgeVector[client][1]);
	result[1] = (g_fEdgeVector[client][1]*ground[1] - g_fEdgeVector[client][0]*g_fEdgePoint[client][1]) / (g_fEdgeVector[client][1]-g_fEdgeVector[client][0]);
	result[2] = ground[2];
}

stock bool:IsCoordInBlockPoint(const Float:origin[3], const Float:pos[2][3], bool:ignorez)
{
	new bool:bX, bool:bY, bool:bZ;
	decl Float:temp[2][3];
	temp[0] = pos[0];
	temp[1] = pos[1];
	temp[0][0] += 16.0;
	temp[0][1] += 16.0;
	temp[1][0] -= 16.0;
	temp[1][1] -= 16.0;
	if (ignorez)
		bZ=true;	
	
	if(temp[0][0] > temp[1][0])
	{
		if(temp[0][0] >= origin[0] >= temp[1][0])
		{
			bX = true;
		}
	}
	else
	{
		if(temp[1][0] >= origin[0] >= temp[0][0])
		{
			bX = true;
		}
	}
	if(temp[0][1] > temp[1][1])
	{
		if(temp[0][1] >= origin[1] >= temp[1][1])
		{
			bY = true;
		}
	}
	else
	{
		if(temp[1][1] >= origin[1] >= temp[0][1])
		{
			bY = true;
		}
	}
	if(temp[0][2] + 0.002 >= origin[2] >= temp[0][2])
	{
		bZ = true;
	}
	
	if(bX&&bY&&bZ)
	{
		return true;
	}
	else
	{
		return false;
	}
}

stock bool:IsValidClient(client)
{
	if(client >= 1 && client <= MaxClients && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client))
		return true;  
	return false;
} 

public Action:Client_Ljblock(client, args)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
		LJBlockMenu(client);
	return Plugin_Handled;
}

public LJBlockMenu(client)
{	
	new Handle:menu = CreateMenu(LjBlockMenuHandler);
	SetMenuTitle(menu, "[CYBERSHOKE] Ljblock");
	AddMenuItem(menu, "0", "Выбор позиции");
	AddMenuItem(menu, "0", "Сброс позиции");
	if(g_bNoclip[client])
		menu.AddItem("0", "Выключить Noclip", ITEMDRAW_DEFAULT);
	else
		menu.AddItem("0", "Включить Noclip", g_iAllowNoclip == 1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}

public LjBlockMenuHandler(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		if(select == 0)
		{
			Function_BlockJump(client);
			LJBlockMenu(client);
		}
		else if(select == 1)
		{
			g_bLJBlock[client] = false;
			LJBlockMenu(client);
		}
		else if(select == 2)
		{
			g_bNoclip[client] = !g_bNoclip[client];
		}
	}
}

public Function_BlockJump(client)
{
	decl Float:pos[3], Float:origin[3];
	GetAimOrigin(client, pos);
	TraceClientGroundOrigin(client, origin, 100.0);
	new bool:funclinear;
	//get aim target
	new String:classname[32];
	new target = TraceClientViewEntity(client);
	if (IsValidEdict(target))
		GetEntityClassname(target, classname, 32);	
	if (StrEqual(classname,"func_movelinear"))
		funclinear=true;
	
	if((FloatAbs(pos[2] - origin[2]) <= 0.002) || (funclinear && FloatAbs(pos[2] - origin[2]) <= 0.6))
	{
		GetBoxFromPoint(origin, g_fOriginBlock[client]);
		GetBoxFromPoint(pos, g_fDestBlock[client]);
		CalculateBlockGap(client, origin, pos);
		g_fBlockHeight[client] = pos[2];
	}
	else
	{
		g_bLJBlock[client] = false;
		PrintToChat(client, "%t", "LJblock1",MOSSGREEN,WHITE,RED);	
	}
}

stock GetAimOrigin(client, Float:hOrigin[3]) 
{
	new Float:vAngles[3], Float:fOrigin[3];
	GetClientEyePosition(client,fOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace)) 
	{
		TR_GetEndPosition(hOrigin, trace);
		CloseHandle(trace);
		return 1;
	}

	CloseHandle(trace);
	return 0;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask) 
{
	return entity > MaxClients;
}

stock TraceClientGroundOrigin(client, Float:result[3], Float:offset)
{
	new Float:temp[2][3];
	GetClientEyePosition(client, temp[0]);
	temp[1] = temp[0];
	temp[1][2] -= offset;
	new Float:mins[]={-16.0, -16.0, 0.0};
	new Float:maxs[]={16.0, 16.0, 60.0};
	new Handle:trace = TR_TraceHullFilterEx(temp[0], temp[1], mins, maxs, MASK_SHOT, TraceEntityFilterPlayer);
	if(TR_DidHit(trace)) 
	{
		TR_GetEndPosition(result, trace);
		CloseHandle(trace);
		return 1;
	}
	CloseHandle(trace);
	return 0;
}

stock TraceClientViewEntity(client)
{
	new Float:m_vecOrigin[3];
	new Float:m_angRotation[3];
	GetClientEyePosition(client, m_vecOrigin);
	GetClientEyeAngles(client, m_angRotation);
	new Handle:tr = TR_TraceRayFilterEx(m_vecOrigin, m_angRotation, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, client);
	new pEntity = -1;
	if (TR_DidHit(tr))
	{
		pEntity = TR_GetEntityIndex(tr);
		CloseHandle(tr);
		return pEntity;
	}
	CloseHandle(tr);
	return -1;
}

public bool:TRDontHitSelf(entity, mask, any:data)
{
	if (entity == data)
		return false;
	return true;
}

stock GetBoxFromPoint(Float:origin[3], Float:result[2][3])
{
	decl Float:temp[3];
	temp = origin;
	temp[2] += 1.0;
	new Float:ang[4][3];
	ang[1][1] = 90.0;
	ang[2][1] = 180.0;
	ang[3][1] = -90.0;
	new bool:edgefound[4];
	new Float:dist[4];
	decl Float:tempdist[4], Float:position[3], Float:ground[3], Float:Last[4], Float:Edge[4][3];
	for(new i = 0; i < 4; i++)
	{
		TraceWallOrigin(temp, ang[i], Edge[i]);
		tempdist[i] = GetVectorDistance(temp, Edge[i]);
		Last[i] = origin[2];
		while(dist[i] < tempdist[i])
		{
			if(edgefound[i])
				break;
			GetBeamEndOrigin(temp, ang[i], dist[i], position);
			TraceGroundOrigin(position, ground);
			if((Last[i] != ground[2])&&(Last[i] > ground[2]))
			{
				Edge[i] = ground;
				edgefound[i] = true;
			}
			Last[i] = ground[2];
			dist[i] += 10.0;
		}
		if(!edgefound[i])
		{
			TraceGroundOrigin(Edge[i], Edge[i]);
			edgefound[i] = true;
		}
		else
		{
			ground = Edge[i];
			ground[2] = origin[2];
			MakeVectorFromPoints(ground, origin, position);
			GetVectorAngles(position, ang[i]);
			ground[2] -= 1.0;
			GetBeamHitOrigin(ground, ang[i], Edge[i]);
		}
		Edge[i][2] = origin[2];
	}
	if(edgefound[0]&&edgefound[1]&&edgefound[2]&&edgefound[3])
	{
		result[0][2] = origin[2];
		result[1][2] = origin[2];
		result[0][0] = Edge[0][0];
		result[0][1] = Edge[1][1];
		result[1][0] = Edge[2][0];
		result[1][1] = Edge[3][1];
	}
}

CalculateBlockGap(client, Float:origin[3], Float:target[3])
{
	new Float:distance = GetVectorDistance(origin, target);
	new Float:rad = DegToRad(15.0);
	new Float:newdistance = (distance) / (Cosine(rad));
	decl Float:eye[3], Float:eyeangle[2][3];
	new Float:temp = 0.0;
	GetClientEyePosition(client, eye);
	GetClientEyeAngles(client, eyeangle[0]);
	eyeangle[0][0] = 0.0;
	eyeangle[1] = eyeangle[0];
	eyeangle[0][1] += 10.0;
	eyeangle[1][1] -= 10.0;
	decl Float:position[3], Float:ground[3], Float:Last[2], Float:Edge[2][3];
	new bool:edgefound[2];
	while(temp < newdistance)
	{
		temp += 10.0;
		for(new i = 0; i < 2 ; i++)
		{
			if(edgefound[i])
				continue;
			GetBeamEndOrigin(eye, eyeangle[i], temp, position);
			TraceGroundOrigin(position, ground);
			if(temp == 10.0)
			{
				Last[i] = ground[2];
			}
			else
			{
				if((Last[i] != ground[2])&&(Last[i] > ground[2]))
				{
					Edge[i] = ground;
					edgefound[i] = true;
				}
				Last[i] = ground[2];
			}
		}
	}
	decl Float:temp2[2][3];
	if(edgefound[0] && edgefound[1])
	{
		for(new i = 0; i < 2 ; i++)
		{
			temp2[i] = Edge[i];
			temp2[i][2] = origin[2] - 1.0;
			if(eyeangle[i][1] > 0)
			{
				eyeangle[i][1] -= 180.0;
			}
			else
			{
				eyeangle[i][1] += 180.0;
			}
			GetBeamHitOrigin(temp2[i], eyeangle[i], Edge[i]);
		}
	}
	else
	{
		g_bLJBlock[client] = false;
		PrintToChat(client, "%t", "LJblock2",MOSSGREEN,WHITE,RED);	
		return;
	}



	g_fEdgePoint[client] = Edge[0];	
	MakeVectorFromPoints(Edge[0], Edge[1], position);
	g_fEdgeVector[client] = position;
	NormalizeVector(g_fEdgeVector[client], g_fEdgeVector[client]);
	CorrectEdgePoint(client);
	GetVectorAngles(position, position);
	position[1] += 90.0;
	GetBeamHitOrigin(Edge[0], position, Edge[1]);
	distance = GetVectorDistance(Edge[0], Edge[1]);
	g_BlockDist[client] = RoundToNearest(distance);


	new Float:surface = GetVectorDistance(g_fDestBlock[client][0],g_fDestBlock[client][1]);
	surface *= surface;
	if (surface > 1000000)
	{
		PrintToChat(client, "%t", "LJblock3",MOSSGREEN,WHITE,RED);	
		return;
	}	
	
	
	if(!IsCoordInBlockPoint(Edge[1],g_fDestBlock[client],true))	
	{	
		g_bLJBlock[client] = false;
		PrintToChat(client, "%t", "LJblock4",MOSSGREEN,WHITE,RED);	
		return;		
	}
	TE_SetupBeamPoints(Edge[0], Edge[1], g_Beam[0], 0, 0, 0, 1.0, 1.0, 1.0, 10, 0.0, {0,255,255,155}, 0);
	TE_SendToClient(client);	
	
	if(g_BlockDist[client] > 225 && g_BlockDist[client] <= 300)
	{
		PrintToChat(client, "%t", "LJblock5", MOSSGREEN,WHITE, LIMEGREEN,GREEN, g_BlockDist[client],LIMEGREEN);
		g_bLJBlock[client] = true;
	}
	else
	{
		if (g_BlockDist[client] < 225)
			PrintToChat(client, "%t", "LJblock6", MOSSGREEN,WHITE, RED,DARKRED,g_BlockDist[client],RED);
		else
			if (g_BlockDist[client] > 300)
				PrintToChat(client, "%t", "LJblock7", MOSSGREEN,WHITE, RED,DARKRED,g_BlockDist[client],RED);
	}
}

stock TraceWallOrigin(Float:fOrigin[3], Float:vAngles[3], Float:result[3])
{
	new Handle:trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace)) 
	{
		TR_GetEndPosition(result, trace);
		CloseHandle(trace);
		return 1;
	}
	CloseHandle(trace);
	return 0;
}

stock GetBeamEndOrigin(Float:fOrigin[3], Float:vAngles[3], Float:distance, Float:result[3])
{
	decl Float:AngleVector[3];
	GetAngleVectors(vAngles, AngleVector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(AngleVector, AngleVector);
	ScaleVector(AngleVector, distance);	
	AddVectors(fOrigin, AngleVector, result);
}

stock TraceGroundOrigin(Float:fOrigin[3], Float:result[3])
{
	new Float:vAngles[3] = {90.0, 0.0, 0.0};
	new Handle:trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace)) 
	{
		TR_GetEndPosition(result, trace);
		CloseHandle(trace);
		return 1;
	}
	CloseHandle(trace);
	return 0;
}

stock GetBeamHitOrigin(Float:fOrigin[3], Float:vAngles[3], Float:result[3])
{
	new Handle:trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace)) 
	{
		TR_GetEndPosition(result, trace);
		CloseHandle(trace);
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	new Float: origin[3];
	if (!IsValidClient(client))
		return Plugin_Continue;	
		
	//some methods..	
	if(IsPlayerAlive(client))	
	{	
	//ljblock
		if (g_js_bPlayerJumped[client] == false && GetEntityFlags(client) & FL_ONGROUND && ((buttons & IN_JUMP)))
		{
			decl Float:temp[3], Float: pos[3];
			GetClientAbsOrigin(client,pos);
			g_bLJBlockValidJumpoff[client]=false;
			if(g_bLJBlock[client])
			{
				g_bLJBlockValidJumpoff[client]=true;
				g_bLjStarDest[client]=false;
				GetEdgeOrigin(client, origin, temp);
				g_fEdgeDist[client] = GetVectorDistance(temp, origin);
				if(!IsCoordInBlockPoint(pos,g_fOriginBlock[client],false))				
					if(IsCoordInBlockPoint(pos,g_fDestBlock[client],false))
					{
						g_bLjStarDest[client]=true;
					}
					else
						g_bLJBlockValidJumpoff[client]=false;
			}
		}
		if(g_bLJBlock[client])
		{
			TE_SendBlockPoint(client, g_fDestBlock[client][0], g_fDestBlock[client][1], g_Beam[0]);
			TE_SendBlockPoint(client, g_fOriginBlock[client][0], g_fOriginBlock[client][1], g_Beam[0]);
		}		
	}
	return Plugin_Continue;
}

stock TE_SendBlockPoint(client, const Float:pos1[3], const Float:pos2[3], model)
{
	new Float:buffer[4][3];
	buffer[2] = pos1;
	buffer[3] = pos2;
	buffer[0] = buffer[2];
	buffer[0][1] = buffer[3][1];
	buffer[1] = buffer[3];
	buffer[1][1] = buffer[2][1];
	decl randco[4];
	randco[0] = GetRandomInt(0, 255);
	randco[1] = GetRandomInt(0, 255);
	randco[2] = GetRandomInt(0, 255);
	randco[3] = GetRandomInt(125, 255);
	TE_SetupBeamPoints(buffer[3], buffer[0], model, 0, 0, 0, 0.13, 2.0, 2.0, 10, 0.0, randco, 0);
	TE_SendToClient(client);
	TE_SetupBeamPoints(buffer[0], buffer[2], model, 0, 0, 0, 0.13, 2.0, 2.0, 10, 0.0, randco, 0);
	TE_SendToClient(client);
	TE_SetupBeamPoints(buffer[2], buffer[1], model, 0, 0, 0, 0.13, 2.0, 2.0, 10, 0.0, randco, 0);
	TE_SendToClient(client);
	TE_SetupBeamPoints(buffer[1], buffer[3], model, 0, 0, 0, 0.13, 2.0, 2.0, 10, 0.0, randco, 0);
	TE_SendToClient(client);
}