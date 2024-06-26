#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <basecomm>

#pragma semicolon 1
#pragma newdecls required

#define ADMFLAG ADMFLAG_ROOT
#define ADMACCESS Admin_Root

#define PLUGIN_AUTHOR "Without#Name (Discord: WN4m3#1450)"
#define PLUGIN_VERSION "7.4.10"

////////////////////////////////////////////////////////////////////////////////////////////////////
public bool IsPluginLoaded(Handle plugin)
{
/* Check if the plugin handle is pointing to a valid plugin. */
	Handle hIterator = GetPluginIterator();
	bool bIsValid = false;
	
	while (MorePlugins(hIterator))
	{
		if (plugin == ReadPlugin(hIterator))
		{
			bIsValid = (GetPluginStatus(plugin) == Plugin_Running);
			break;
		}
	}
	
	delete hIterator;
	return bIsValid;
}
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
public bool 
GroundCheck(
	float[] 		aPlayerGround, 
	int 			n)
{
	for(int i=0;i<n;i++)
		for(int j=i;j<n;j++)
			if(i!=j)
				if(GetDistAbs(aPlayerGround[i],aPlayerGround[j])>3.0)
					return false;

	return true;
}
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
public float 
GetDistAbs(
	float 			a, 
	float 			b)
{
	return SquareRoot((a-b)*(a-b));
}
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
public void 
GetGroundOrigin(
	int 			client, 
	float 			pos[3])
{
	float 			fOrigin[3];
	float 			result[3];
	GetClientAbsOrigin(client, fOrigin);
	TraceClientGroundOrigin(client, result, 100.0);
	pos = fOrigin;
	pos[2] = result[2];
}
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
public void 
TraceClientGroundOrigin(
	int 			client, 
	float 			result[3], 
	float 			offset)
{
	float temp[2][3];
	GetClientEyePosition(client, temp[0]);
	temp[1] = temp[0];
	temp[1][2] -= offset;
	float mins[]={-16.0, -16.0, 0.0};
	float maxs[]={16.0, 16.0, 60.0};
	Handle trace = TR_TraceHullFilterEx(temp[0], temp[1], mins, maxs, MASK_SHOT, TraceEntityFilterPlayer);
	if(TR_DidHit(trace)) 
	{
		TR_GetEndPosition(result, trace);		
	}
	CloseHandle(trace);
}
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
public bool 
TraceEntityFilterPlayer(
	int 			entity, 
	int 			contentsMask) 
{
	return entity > MaxClients;
}
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
public int 
GetDirection(
	int 			client)
{
	float 			vVel[3];
	float 			vAngles[3];

	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vVel);
		
	GetClientEyeAngles(client, vAngles);
	float fTempAngle = vAngles[1];
	float tmp, yaw, pitch;
	
	if (vVel[1] == 0 && vVel[0] == 0)
	{
		yaw = 0.0;
		if (vVel[2] > 0)
			pitch = 270.0;
		else
			pitch = 90.0;
	}
	else
	{
		yaw = (ArcTangent2(vVel[1], vVel[0]) * (180 / 3.141593));
		if (yaw < 0)
			yaw += 360;

		tmp = SquareRoot(vVel[0]*vVel[0] + vVel[1]*vVel[1]);
		pitch = (ArcTangent2(-vVel[2], tmp) * (180 / 3.141593));
		if (pitch < 0)
			pitch += 360;
	}
	
	vAngles[0] = pitch;
	vAngles[1] = yaw;
	vAngles[2] = 0.0;

	if(fTempAngle < 0)
		fTempAngle += 360;

	float fTempAngle2 = fTempAngle - vAngles[1];

	if(fTempAngle2 < 0)
		fTempAngle2 = -fTempAngle2;
	
	if(fTempAngle2 < 22.5 || fTempAngle2 > 337.5)
		return 0; // Forwards
	if(fTempAngle2 > 22.5 && fTempAngle2 < 67.5 || fTempAngle2 > 292.5 && fTempAngle2 < 337.5 )
		return 0; // Half-sideways
	if(fTempAngle2 > 67.5 && fTempAngle2 < 112.5 || fTempAngle2 > 247.5 && fTempAngle2 < 292.5)
		return 2; // Sideways
	if(fTempAngle2 > 157.5 && fTempAngle2 < 202.5)
		return 3; // Backwards
	
	return 4; // Unknown
}
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
public float 
GetSpeed(
	int 			client)
{
	float fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	
	return SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0));
}
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
//является ли игрок админом
public bool 
IsClientAdmin(
	int 			client)
{
	if(GetUserAdmin(client) == INVALID_ADMIN_ID)
		return false;
		
	return true;
}
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
//получить индификатор админа
public AdminId 
GetClientAdmin(
	int 			client)
{
	return GetUserAdmin(client);
}
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
//взять число типа int по модулю
public int 
Abs(
	int 			number)
{	
	return number*GetSign(number);
}
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
//получить знак числа int типа
public int 
GetSign(
	int 			number)
{
	int 			res=0;

	if(number>=0)
		res = 1;
	else
		res = -1;
		
	return res;
}
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
//получить знак числа float типа
public int 
GetSignFloat(
	float 			number)
{
	int 			res=0;

	if(number>=0)
		res = 1;
	else
		res = -1;
		
	return res;
}
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
public float 
NormalizeAngle(
	float 			Angle)
{
	if (Angle > 180) 
		Angle -= 360;
	else if(Angle < -180) 
		Angle += 360;
		
	return Angle;
}
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
public bool 
IsValidClient(
	int 			client)
{
	if(client >= 1 && client <= MaxClients 
	&& IsValidEntity(client) 
	&& IsClientConnected(client) 
	&& IsClientInGame(client) 
	&& IsClientAuthorized(client) 
	&& !IsClientInKickQueue(client)
	&& !IsFakeClient(client))
		return true; 
		
	return false;
}
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
//Структрура для обработки команд
enum struct SCmd {
	int 			argc;
	char 			argv[256];	

	int         	client;
	int         	target;

	////////////////////////////////////////////////////////////////////////////////////////////////////
	//Создание и поиск цели
  	bool 
	  Create(
		  int 		client, 
		  int 		argc)
  	{
		this.argc = argc + 1;
		this.client = client;
		
		if(!GetCmdArgString(this.argv,256))
			return false;

		return true;	
  	}
	////////////////////////////////////////////////////////////////////////////////////////////////////

	////////////////////////////////////////////////////////////////////////////////////////////////////
	//Получить аргумент как строку
	bool 
	GetArg(
		int 		iCount, 
		char[] 		buffer, 
		int 		sizeBuf)
	{
		if(iCount>=this.argc)
			return false;

		if(!GetCmdArg(iCount, buffer, sizeBuf))
			return false;

		return true;
	}  
	////////////////////////////////////////////////////////////////////////////////////////////////////

	////////////////////////////////////////////////////////////////////////////////////////////////////
	//Получить аргумент как целое число
	bool 
	GetArgHowInt(
		int 		iCount,
		int			&buffer)
	{
		char 		argv[256];

		if(iCount>=this.argc)
			return false;

		if(!GetCmdArg(iCount, argv, 256))
			return false;

		if(!StringToIntEx(argv, buffer, 10))
			return false;

		return true;
	} 
	////////////////////////////////////////////////////////////////////////////////////////////////////

	////////////////////////////////////////////////////////////////////////////////////////////////////
	//Получить аргумент как число с точкой
	bool 
	GetArgHowFloat(
		int 		iCount,
		float		&buffer)
	{
		char 		argv[256];

		if(iCount>=this.argc)
			return false;

		if(!GetCmdArg(iCount, argv, 256))
			return false;

		if(!StringToFloatEx(argv, buffer))
			return false;

		return true;
	} 
	////////////////////////////////////////////////////////////////////////////////////////////////////

	////////////////////////////////////////////////////////////////////////////////////////////////////
	//вернуть клиента
	int 
	GetClient()
	{
		return this.client;
	} 
	////////////////////////////////////////////////////////////////////////////////////////////////////

	////////////////////////////////////////////////////////////////////////////////////////////////////
	//вернуть цель
	bool 
	GetTarget(
		int 		&buffer)
	{
		char bufferstr[64];

		this.GetArg(1, bufferstr, 64);

		this.target = FindTarget(this.client, bufferstr, true);

		if(!IsValidClient(this.target))
			return false;

		buffer = this.target;

		return true;
	} 
	////////////////////////////////////////////////////////////////////////////////////////////////////

	////////////////////////////////////////////////////////////////////////////////////////////////////
	//Получить всю строку 
	bool 
	GetAll(
		char[] 		buffer, 
		int 		sizeBuf)
	{
		GetCmdArgString(buffer, sizeBuf);
	
		ReplaceString(buffer, sizeBuf, "\"", "");	

		return true;
	}  
	////////////////////////////////////////////////////////////////////////////////////////////////////

	
}
////////////////////////////////////////////////////////////////////////////////////////////////////
