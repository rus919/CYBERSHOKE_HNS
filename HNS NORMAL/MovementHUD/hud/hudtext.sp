// =========================================================== //

Handle gH_KeysHudText = null;
Handle gH_SpeedHudText = null;

// =========================================================== //

void InitHudText()
{
	gH_KeysHudText = CreateHudSynchronizer();
	gH_SpeedHudText = CreateHudSynchronizer();
}

// =========================================================== //

void DrawHudTextSpeed(int client, float targetCurrentSpeed, bool targetPerf, bool targetTakeoff, float targetTakeoffSpeed)
{
	int speedPos = Pref_Speed_Position;
	int speedDisp = Pref_Speed_Display;
	int speedColor = targetPerf ? Pref_Speed_Perf_Color : Pref_Speed_Normal_Color;

	char posBuf[10];
	Pref(speedPos).GetStringVal(client, posBuf, sizeof(posBuf));

	char colorBuf[16];
	Pref(speedColor).GetStringVal(client, colorBuf, sizeof(colorBuf));

	int color[4];
	BufferToRGBA(colorBuf, color, sizeof(color));

	float position[2];
	BufferToXY(posBuf, position, sizeof(position));

	char displayBuf[128];
	SetHudTextParamsEx(position[0], position[1], 1.0, color, _, 0, 1.0, 0.0, 0.0);

	switch (Pref(speedDisp).GetIntVal(client))
	{
		case 1: // Float
		{
			Format(displayBuf, sizeof(displayBuf), "%.2f", targetCurrentSpeed);

			if (targetTakeoff)
			{
				Format(displayBuf, sizeof(displayBuf), "%s\n(%.2f)", displayBuf, targetTakeoffSpeed);
			}
		}
		case 2: // Integer
		{
			Format(displayBuf, sizeof(displayBuf), "%d", RoundToFloor(targetCurrentSpeed));
			
			if (targetTakeoff)
			{
				Format(displayBuf, sizeof(displayBuf), "%s\n(%d)", displayBuf, RoundToFloor(targetTakeoffSpeed));
			}
		}
	}

	ShowSyncHudText(client, gH_SpeedHudText, "%s", displayBuf);
}

// =========================================================== //

void DrawHudTextKeys(int client, bool targetOverlapped, char keys[8][2])
{
	int keyPos = Pref_Keys_Position;
	int keyColor = targetOverlapped ? Pref_Keys_Overlap_Color : Pref_Keys_Normal_Color;

	char posBuf[10];
	Pref(keyPos).GetStringVal(client, posBuf, sizeof(posBuf));

	char colorBuf[16];
	Pref(keyColor).GetStringVal(client, colorBuf, sizeof(colorBuf));

	int color[4];
	BufferToRGBA(colorBuf, color, sizeof(color));

	float position[2];
	BufferToXY(posBuf, position, sizeof(position));

	SetHudTextParamsEx(position[0], position[1], 1.0, color, _, 0, 1.0, 0.0, 0.0);
	
	switch(Pref(Pref_Keys_Mouse_Direction).GetIntVal(client))
	{
		case 0:
			ShowSyncHudText(client, gH_KeysHudText, "%s  %s  %s\n%s  %s  %s", keys[4], keys[0], keys[5], keys[1], keys[2], keys[3]);
		case 1:
			ShowSyncHudText(client, gH_KeysHudText, "%s  %s  %s\n%s      %s\n%s  %s  %s", keys[4], keys[0], keys[5], keys[6], keys[7], keys[1], keys[2], keys[3]);
		case 2:
			ShowSyncHudText(client, gH_KeysHudText, "%s  %s  %s\n%s %s  %s  %s %s", keys[4], keys[0], keys[5], keys[6], keys[1], keys[2], keys[3], keys[7]);
	}
}

// =========================================================== //