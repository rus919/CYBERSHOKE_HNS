// ================== DOUBLE INCLUDE ========================= //

#if defined _MovementHUD_Preference_included_
#endinput
#endif
#define _MovementHUD_Preference_included_

// =========================================================== //

#define MAX_PREFERENCE_NAME_LENGTH 64
#define MAX_PREFERENCE_VALUE_LENGTH 64
#define MAX_PREFERENCE_DISPLAY_LENGTH 64

enum
{
	PrefType_Numeric,
	PrefType_RGBA,
	PrefType_XY
};

// =========================================================== //

static char NAME_TOKEN[] = "name";
static char DISPLAY_TOKEN[] = "display";
static char COOKIE_TOKEN[] = "cookie";
static char PREF_TOKEN[] = "pref";
static char TYPE_TOKEN[] = "type";
static char LIMIT_TOKEN[] = "limit";
static char DEFAULT_TOKEN[] = "default";

// =========================================================== //

methodmap Preference < StringMapEx
{
	public Preference(char[] name, char[] display, char[] defValue,
						int type, int limit, int iPref)
	{
		StringMapEx pref = new StringMapEx();
		pref.SetString(NAME_TOKEN, name);
		pref.SetString(DISPLAY_TOKEN, display);
		pref.SetString(DEFAULT_TOKEN, defValue);
		pref.SetValue(TYPE_TOKEN, type);
		pref.SetValue(LIMIT_TOKEN, limit);
		pref.SetValue(PREF_TOKEN, iPref);

		// Dont conflict with v1 cookies!
		char newPrefName[MAX_PREFERENCE_NAME_LENGTH];
		strcopy(newPrefName, sizeof(newPrefName), name);

		ReplaceString(newPrefName, sizeof(newPrefName), "_", "-");
		Handle cookie = RegClientCookie(newPrefName, display, CookieAccess_Private);

		pref.SetValue(COOKIE_TOKEN, cookie);
		return view_as<Preference>(pref);
	}

	property int Pref
	{
		public get() { return this.GetInt(PREF_TOKEN); }
	}

	property int Type
	{
		public get() { return this.GetInt(TYPE_TOKEN); }
	}

	property int Limit
	{
		public get() { return this.GetInt(LIMIT_TOKEN); }
	}

	property Handle Cookie
	{
		public get() { return this.GetAny(COOKIE_TOKEN); }
	}

	public void GetDefault(char[] buffer, int maxlength)
	{
		this.GetString(DEFAULT_TOKEN, buffer, maxlength);
	}

	public void GetName(char[] buffer, int maxlength)
	{
		this.GetString(NAME_TOKEN, buffer, maxlength);
	}

	public void GetDisplay(char[] buffer, int maxlength)
	{
		this.GetString(DISPLAY_TOKEN, buffer, maxlength);
	}

	public void GetStringVal(int client, char[] buffer, int maxlength)
	{
		GetClientCookie(client, this.Cookie, buffer, maxlength);
	}

	public int GetIntVal(int client)
	{
		char buf[MAX_PREFERENCE_VALUE_LENGTH];
		this.GetStringVal(client, buf, sizeof(buf));

		return StringToInt(buf);
	}

	public void SetStringVal(int client, char[] buffer)
	{
		SetClientCookie(client, this.Cookie, buffer);
	}

	public void SetIntVal(int client, int value)
	{
		if (value < 0) value = 0;
		if (value > this.Limit) value = 0;

		char buf[12];
		IntToString(value, buf, sizeof(buf));
		SetClientCookie(client, this.Cookie, buf);
	}

	public void Init(int client)
	{
		char buf[2];
		GetClientCookie(client, this.Cookie, buf, sizeof(buf));

		if (StrEqual(buf, ""))
		{
			char def[MAX_PREFERENCE_VALUE_LENGTH];
			this.GetDefault(def, sizeof(def));
			this.SetStringVal(client, def);
		}
	}

	public void SetVal(int client, char[] buffer)
	{
		switch (this.Type)
		{
			case PrefType_RGBA:
			{
				int rgb[4];
				BufferToRGBA(buffer, rgb, sizeof(rgb));

				char input[3 * 4];
				Format(input, sizeof(input), "%d %d %d", rgb[0], rgb[1], rgb[2]);
				this.SetStringVal(client, input);
			}
			case PrefType_XY:
			{
				float xy[2];
				BufferToXY(buffer, xy, sizeof(xy));
				
				char input[2 * 6];
				Format(input, sizeof(input), "%.2f %.2f", xy[0], xy[1]);
				this.SetStringVal(client, input);
			}
			case PrefType_Numeric:
			{
				int value = StringToInt(buffer);
				this.SetIntVal(client, value);
			}
		}
	}

	public void Reset(int client)
	{
		char defValue[MAX_PREFERENCE_VALUE_LENGTH];
		this.GetDefault(defValue, sizeof(defValue));
		this.SetVal(client, defValue);
	}
}

// =========================================================== //