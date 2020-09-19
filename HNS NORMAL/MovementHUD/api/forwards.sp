// =========================================================== //

static Handle H_OnExpectingInput = null;
static Handle H_OnInputCancelled = null;

static Handle H_OnPreferencesInit = null;
static Handle H_OnPreferencesLoaded = null;

static Handle H_OnPreferencesImported = null;
static Handle H_OnPreferencesExported = null;

static Handle H_OnPreferenceSet = null;
static Handle H_OnPreferenceCommand = null;

static Handle H_Movement_OnTakeoff = null;

// ======================= LISTENERS ========================= //

void CreateForwards()
{
	H_OnExpectingInput = CreateGlobalForward("MHud_OnExpectingInput", ET_Ignore, Param_Cell, Param_Cell);
	H_OnInputCancelled = CreateGlobalForward("MHud_OnInputCancelled", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

	H_OnPreferencesInit = CreateGlobalForward("MHud_OnPreferencesInit", ET_Ignore);
	H_OnPreferencesLoaded = CreateGlobalForward("MHud_OnPreferencesLoaded", ET_Ignore, Param_Cell);

	H_OnPreferencesImported = CreateGlobalForward("MHud_OnPreferencesImported", ET_Ignore, Param_Cell, Param_Cell);
	H_OnPreferencesExported = CreateGlobalForward("MHud_OnPreferencesExported", ET_Ignore, Param_Cell, Param_String);

	H_OnPreferenceSet = CreateGlobalForward("MHud_OnPreferenceSet", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	H_OnPreferenceCommand = CreateGlobalForward("MHud_OnPreferenceCommand", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

	H_Movement_OnTakeoff = CreateGlobalForward("MHud_Movement_OnTakeoff", ET_Single, Param_Cell, Param_Cell, Param_CellByRef, Param_FloatByRef);
}

// =========================================================== //

void Call_OnExpectingInput(int client, Preference pref)
{
	Call_StartForward(H_OnExpectingInput);
	Call_PushCell(client);
	Call_PushCell(pref);
	Call_Finish();
}

void Call_OnInputCancelled(int client, Preference pref, bool timeout)
{
	Call_StartForward(H_OnInputCancelled);
	Call_PushCell(client);
	Call_PushCell(pref);
	Call_PushCell(timeout);
	Call_Finish();
}

void Call_OnPreferencesInit()
{
	Call_StartForward(H_OnPreferencesInit);
	Call_Finish();
}

void Call_OnPreferencesLoaded(int client)
{
	Call_StartForward(H_OnPreferencesLoaded);
	Call_PushCell(client);
	Call_Finish();
}

void Call_OnPreferencesImported(int client, PreferencesCode code)
{
	Call_StartForward(H_OnPreferencesImported);
	Call_PushCell(client);
	Call_PushCell(code);
	Call_Finish();
}

void Call_OnPreferencesExported(int client, char[] code)
{
	Call_StartForward(H_OnPreferencesExported);
	Call_PushCell(client);
	Call_PushString(code);
	Call_Finish();
}

void Call_OnPreferenceSet(int client, Preference pref, bool fromCommand)
{
	Call_StartForward(H_OnPreferenceSet);
	Call_PushCell(client);
	Call_PushCell(pref);
	Call_PushCell(fromCommand);
	Call_Finish();
}

void Call_OnPreferenceCommand(int client, Preference pref, bool hadValue)
{
	Call_StartForward(H_OnPreferenceCommand);
	Call_PushCell(client);
	Call_PushCell(pref);
	Call_PushCell(hadValue);
	Call_Finish();
}

bool Call_OnTakeoff(int client, bool didJump, bool &didPerf, float &takeoffSpeed)
{
	if (GetForwardFunctionCount(H_Movement_OnTakeoff) <= 0)
	{
		return false;
	}

	Call_StartForward(H_Movement_OnTakeoff);
	Call_PushCell(client);
	Call_PushCell(didJump);
	Call_PushCellRef(didPerf);
	Call_PushFloatRef(takeoffSpeed);
	Call_Finish();
	return true;
}

// =========================================================== //