// =========================================================== //

ConVar gCV_Keys = null;
ConVar gCV_Speed = null;

// ======================== PUBLIC =========================== //

void CreateConvars()
{
	gCV_Keys = CreateConVar("mhud_keys_enabled", "1", "Enable/disable keys display server-side", _, true, 0.0, true, 1.0);
	gCV_Speed = CreateConVar("mhud_speed_enabled", "1", "Enable/disable speed display server-side", _, true, 0.0, true, 1.0);
}

// =========================================================== //