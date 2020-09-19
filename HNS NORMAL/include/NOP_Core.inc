#include <socket>
#include <json>


native int NOP_GetMainPluginState();

native int NOP_LogMSG(int iClient, char[] msg);
stock int NOP_LogMSGFormated(int iClient, char[] sFormat, any ...)
{
    char buffer[1024];
    VFormat(buffer, sizeof(buffer), sFormat, 3);

    NOP_LogMSG(iClient, buffer);
}

native int NOP_GetVar(int li_client, VAR li_StatID, char[] lc_StatString = "");


native int NOP_SendHTTPRequest(char[] path, char[] body, Function HTTPCallback, any value, int port, char[] url = "46.174.48.79", char[] method = "POST");

forward void NOP_OnClientLoaded(int client);
forward void NOP_OnClientDisconnect(int client);
forward void NOP_OnCoreStop();
forward void NOP_OnTimerUpdate(int NewTime);
forward void NOP_OnStateChanged(int prevState, int currState);


forward void NOP_OnDBConnect(Handle hndl_web, Handle hndl_lvl, Handle hndl_france);

enum {
    STATE_UNKNOWN = -1,
    STATE_OFF = 0,
    STATE_SERVER_CONNECTING,
    STATE_DB_CONNECTING,
    STATE_READY
}

enum {
    STATE_NOT_READY = 0,
    STATE_FULL_READY = 1
}

enum VAR {
    VAR_SID = 1,
    VAR_SNAME,
    VAR_SIP,
    VAR_SPORT,
    VAR_SMODE,
    VAR_SMAXPL,
    VAR_SRESERV,
    VAR_SPRIME,
    VAR_SLOC,

    VAR_CORE_READY,
    VAR_FRANCE_READY,
    VAR_LVL_READY,
    VAR_CORE_DB,
    VAR_FRANCE_DB,
    VAR_LVL_DB,

    VAR_CLIENT_ID,
    VAR_CLIENT_IS_VIP,
    VAR_CLIENT_VIP_GROUP,
    VAR_CLIENT_VIP_EXPIRES,
    VAR_CLIENT_FACEIT_ELO,
    VAR_CLIENT_FACEIT_LVL,
    VAR_CLIENT_WEAPON_SKINS,
    VAR_CLIENT_TABLE,
    VAR_SERVER_TABLE,

    VAR_CLIENT_STATE,
    VAR_CLIENT_IP,
    VAR_CLIENT_REGION
}


stock char[] NOP_IntToString(int i)
{
	char buffer[128];
	FormatEx(buffer, 128, "%i", i);
	return buffer;
}

stock char[] NOP_FormatEx(char[] msg, any...)
{
	char buffer[1024];
	VFormat(buffer, sizeof(buffer), msg, 2);
	return buffer;
}

stock char[] NOP_GetVarString(int li_client, VAR li_StatID)
{
    char buffer[128];
    NOP_GetVar(li_client, li_StatID, buffer);
    return buffer;
}

stock char[] NOP_Escape(char[] string, Handle DB_HANDLE = INVALID_HANDLE)
{
    char buffer[256];
    if(DB_HANDLE == INVALID_HANDLE)
    {
        ReplaceString(string, strlen(string), "\'", "\\\'"); 
        ReplaceString(string, strlen(string), "\"", "\\\""); 
        strcopy(buffer, strlen(buffer), string);
        return buffer;
    }
    else 
    {
        SQL_EscapeString(DB_HANDLE, string, buffer, 256);
        return buffer;
    }
}

stock Handle NOP_GetCoreDB()
{
    return view_as<Handle>(NOP_GetVar(0, VAR_CORE_DB));
}

stock bool NOP_IsClientLoaded(iClient)
{
    if(IsClientAuthorized(iClient) && NOP_GetVar(iClient, VAR_CLIENT_STATE) == STATE_FULL_READY) return true;
    else return false;
}

stock int StringURLEncode( const char[] szInput, char[] szOutput, int iLen )
{
    static const HEXCHARS[ 16 ] = {
        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
        0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66
    };
    
    new iPos, cChar, iFLen;
    while( ( cChar = szInput[ iPos ] ) && iFLen < iLen )
    {
        if( cChar == 0x20 )
        {
            szOutput[ iFLen++ ] = 0x2B;
        }
        else if( !( 0x41 <= cChar <= 0x5A )
        && !( 0x61 <= cChar <= 0x7A )
        && !( 0x30 <= cChar <= 0x39 )
        && cChar != 0x2D
        && cChar != 0x2E
        && cChar != 0x5F )
        {
            if( ( iFLen + 3 ) > iLen )
            {
                break;
            }
            else if( cChar > 0xFF
            || cChar < 0x00 )
            {
                cChar = 0x2A;
            }
            
            szOutput[ iFLen++ ] = 0x25;
            szOutput[ iFLen++ ] = HEXCHARS[ cChar >> 4 ];
            szOutput[ iFLen++ ] = HEXCHARS[ cChar & 15 ];
        }
        else
        {
            szOutput[ iFLen++ ] = cChar;
        }
        
        iPos++;
    }
    
    szOutput[ iFLen ] = 0;
    return iFLen;
}