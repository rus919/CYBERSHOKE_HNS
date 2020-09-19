// =========================================================== //

#include <json>
#include <base64>

// =========================================================== //

static char FAILURE_TOKEN[] = "failure";
static char OWNER_TOKEN[] = "owner";
static char REVISION_TOKEN[] = "rev";

// =========================================================== //

methodmap PreferencesCode < StringMapEx
{
	public PreferencesCode()
	{
		StringMapEx codeObj = new StringMapEx();
		codeObj.SetValue(FAILURE_TOKEN, true);
		return view_as<PreferencesCode>(codeObj);
	}
	
	property int Owner
	{
		public get() { return this.GetInt(OWNER_TOKEN); }
		public set(int accountId) { this.SetValue(OWNER_TOKEN, accountId); }
	}
	
	property int Revision
	{
		public get() { return this.GetInt(REVISION_TOKEN); }
		public set(int revision) { this.SetValue(REVISION_TOKEN, revision); }
	}
	
	property bool Failure
	{
		public get() { return this.GetBool(FAILURE_TOKEN); }
		public set(bool failure) { this.SetValue(FAILURE_TOKEN, failure); }
	}

	public void GetSteamId2(char[] buffer, int maxlength)
	{
		int account = this.Owner / 2;
		if (account <= 0)
		{
			return;
		}

		int universe = this.Owner % 2 == 0 ? 0 : 1;
		Format(buffer, maxlength, "STEAM_1:%d:%d", universe, account);
	}
}

// =========================================================== //

void ExportPreferencesToCode(int client, char[] buffer, int maxlength)
{
	Preferences prefs = g_Prefs;
	JSON_Object prefsJson = new JSON_Object(false);

	prefsJson.SetInt(OWNER_TOKEN, GetSteamAccountID(client));
	prefsJson.SetInt(REVISION_TOKEN, MHUD_PREFERENCES_REVISION);
		
	JSON_Object dataArr = new JSON_Object(true);
	for (int i = 0; i < prefs.Length; i++)
	{
		Preference pref = prefs.Get(i);
		char value[MAX_PREFERENCE_VALUE_LENGTH];
		pref.GetStringVal(client, value, sizeof(value));

		dataArr.PushString(value);
	}

	prefsJson.SetObject("data", dataArr);

	char js[256];
	prefsJson.Encode(js, sizeof(js));
	EncodeBase64(buffer, maxlength, js);

	prefsJson.Cleanup();
	delete prefsJson;
}

// =========================================================== //

PreferencesCode ImportPreferencesFromCode(int client, char[] code)
{
	Preferences prefs = g_Prefs;
	PreferencesCode prefsObj = new PreferencesCode();
		
	char buffer[256];
	DecodeBase64(buffer, sizeof(buffer), code);
	JSON_Object prefsJson = json_decode(buffer);

	if (prefsJson == null)
	{
		delete prefsJson;
		return prefsObj;
	}

	prefsObj.Owner = prefsJson.GetInt(OWNER_TOKEN);
	prefsObj.Revision = prefsJson.GetInt(REVISION_TOKEN);

	if (prefsObj.Revision == -1)
	{
		prefsJson.Cleanup();
		delete prefsJson;
		return prefsObj;
	}

	JSON_Object dataArr = prefsJson.GetObject("data");
	if (dataArr == null)
	{
		prefsJson.Cleanup();
		delete prefsJson;
		return prefsObj;
	}

	for (int i = 0; i < dataArr.Length; i++)
	{
		if (i < prefs.Length)
		{
			char value[MAX_PREFERENCE_VALUE_LENGTH];
			dataArr.GetStringIndexed(i, value, sizeof(value));

			prefs.GetPreference(i).SetVal(client, value);
		}
	}

	prefsJson.Cleanup();
	delete prefsJson;

	prefsObj.Failure = false;
	return prefsObj;
}

// =========================================================== //