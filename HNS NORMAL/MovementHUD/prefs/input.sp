// =========================================================== //

static int ExpectingInputFor[MAXPLAYERS + 1] = { -1, ... };
static int ExpectingInputItem[MAXPLAYERS + 1] = { -1, ... };
static Handle ExpectingInputTimer[MAXPLAYERS + 1] = { null, ... };

// =========================================================== //

void ExpectInputForClient(int client, int pref, int item)
{
	int userid = GetClientUserId(client);
	ExpectingInputFor[client] = pref;
	ExpectingInputItem[client] = item;
	ExpectingInputTimer[client] = CreateTimer(INPUT_TIMEOUT, Timer_InputTimeout, userid);
}

void ResetExpectInputForClient(int client)
{
	ExpectingInputFor[client] = -1;
	ExpectingInputItem[client] = -1;

	if (ExpectingInputTimer[client] != null)
	{
		KillTimer(ExpectingInputTimer[client]);
		ExpectingInputTimer[client] = null;
	}
}

public Action Timer_InputTimeout(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (MHud_IsValidClient(client))
	{
		Preference pref = Pref(ExpectingInputFor[client]);
		MHud_Print(client, true, "\x07Input timed out!\x01");

		ResetExpectInputForClient(client);
		Call_OnInputCancelled(client, pref, true);
	}
}

// =========================================================== //

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (ExpectingInputFor[client] != -1)
	{
		char buf[MAX_PREFERENCE_VALUE_LENGTH];
		strcopy(buf, sizeof(buf), sArgs);

		TrimString(buf);
		Preference pref = Pref(ExpectingInputFor[client]);

		if (StrEqual(buf, "cancel", false))
		{
			MHud_Print(client, true, "\x07Cancelled input!\x01");
			Call_OnInputCancelled(client, pref, false);
		}
		else if (StrEqual(buf, "reset", false))
		{
			pref.Reset(client);
			MHud_Print(client, false, ">> Preference has been reset!");
		}
		else
		{
			pref.SetVal(client, buf);

			char prefValue[MAX_PREFERENCE_VALUE_LENGTH];
			pref.GetStringVal(client, prefValue, sizeof(prefValue));

			MHud_Print(client, false, ">> Preference set to: \"\x05%s\x01\"", prefValue);
			Call_OnPreferenceSet(client, pref, false);
		}

		DisplayAdvancedPreferenceMenu(client, ExpectingInputItem[client]);
		ResetExpectInputForClient(client);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

// =========================================================== //