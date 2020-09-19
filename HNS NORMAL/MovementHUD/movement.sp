// =========================================================== //

int gI_Buttons[MAXPLAYERS + 1];
int gI_Mouse[MAXPLAYERS + 1][2];
bool gB_Takeoff[MAXPLAYERS + 1];
bool gB_DidPerf[MAXPLAYERS + 1];
int gI_GroundTicks[MAXPLAYERS + 1];

float gF_CurrentSpeed[MAXPLAYERS + 1];
float gF_TakeoffSpeed[MAXPLAYERS + 1];
float gF_LastJumpInput[MAXPLAYERS + 1];

static bool _DidJump[MAXPLAYERS + 1];
static bool _OldOnGround[MAXPLAYERS + 1];
static MoveType _OldMoveType[MAXPLAYERS + 1];

// =========================================================== //

void InitMovement()
{
	HookEvent("player_jump", Event_Jump, EventHookMode_Post);
}

public void Event_Jump(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	_DidJump[client] = true;
}

// ======================= LISTENERS ========================= //

void TrackMovement(int client, int buttons, const int mouse[2])
{
	gI_Buttons[client] = buttons;
	gI_Mouse[client] = mouse;
	gF_CurrentSpeed[client] = GetSpeed(client);

	if (IsJumping(client))
	{
		gF_LastJumpInput[client] = GetEngineTime();
	}

	if (IsOnGround(client))
	{
		gI_GroundTicks[client]++;
		
		if (_DidJump[client])
		{
			_DidJump[client] = false;
		}
		else
		{
			gB_Takeoff[client] = false;
			gB_DidPerf[client] = false;
			gF_TakeoffSpeed[client] = 0.0;
		}
	}
	else
	{
		MoveType newMoveType = GetEntityMoveType(client);
		if (newMoveType != _OldMoveType[client])
		{
			if (_OldMoveType[client] == MOVETYPE_LADDER)
			{
				DoTakeoff(client, false);
			}
		}
		else if (_OldOnGround[client] && _DidJump[client])
		{
			DoTakeoff(client, true);
		}

		gI_GroundTicks[client] = 0;
	}

	UpdateOldMovement(client);
}

void ResetMovementForClient(int client)
{
	gI_Buttons[client] = 0;
	gI_Mouse[client][0] = 0;
	gI_Mouse[client][1] = 0;
	gB_Takeoff[client] = false;
	gB_DidPerf[client] = false;
	gI_GroundTicks[client] = 0;

	gF_CurrentSpeed[client] = 0.0;
	gF_TakeoffSpeed[client] = 0.0;
	gF_LastJumpInput[client] = 0.0;
	
	_DidJump[client] = false;
	_OldOnGround[client] = false;
	_OldMoveType[client] = MOVETYPE_NONE;
}

// ======================== PRIVATE ========================== //

static bool IsJumping(int client)
{
	return (gI_Buttons[client] & IN_JUMP == IN_JUMP);
}

static bool IsOnGround(int client)
{
	return (GetEntityFlags(client) & FL_ONGROUND == FL_ONGROUND);
}

static void UpdateOldMovement(int client)
{
	_OldOnGround[client] = IsOnGround(client);
	_OldMoveType[client] = GetEntityMoveType(client);
}

void DoTakeoff(int client, bool didJump)
{
	bool didPerf = false;
	float takeoffSpeed = -1.0;

	// If no other plugin wants to track... do our own
	if (!Call_OnTakeoff(client, didJump, didPerf, takeoffSpeed))
	{
		didPerf = gI_GroundTicks[client] == 1;
		takeoffSpeed = gF_CurrentSpeed[client];
	}

	gB_Takeoff[client] = true;
	gB_DidPerf[client] = didPerf;
	gF_TakeoffSpeed[client] = takeoffSpeed;
}

// =========================================================== //