/*
- SAMP API Script v2.0
- By Domm
*/
#file "sampapi_v2.pwn"
// MAIN INCLUDES
#include <a_samp>
#include <a_http>
#include <dini>
// YSI
#include <YSI\y_va>
// PRAGMA
#pragma unused ret_memcpy
// DEFINITIONS
#define SRC 		SendRconCommand
#define SAMP_API    "samp-api.domm98.cz/api/sa-mp.php"
#define SAMP_API_IP "samp-api.domm98.cz/api/ip.php"
#define SAMP_API_K  "samp-api.domm98.cz/api/get_key.php"
#define SAMP_API_C  "samp_api.cfg"
// DEVELOPER MODE
#define SAMP_API_DEVELOPER 1
// SERVER VARIABLES
new SERVER_IP[127];
new SERVER_KEY[127];
new disconnectmsg[3][] = {"CRASH", "QUIT", "KICK/BAN"}; //Don't touch this.
// PLAYER VARIABLES
enum Player_Info
{
	kills,
	deaths,
	time,
	info
}
new Player[MAX_PLAYERS][Player_Info];
// FORWARDS
forward PGetServerIP(index, response_code, data[]);
forward PKontrolaKlice(index, response_code, data[]);
forward GetServerIP();
forward WebServerStart();
forward WebServerStop();
forward Clear();
forward BeOnline();
forward KontrolaKlice();
//Script Publics
public GetServerIP()
{
    HTTP(MAX_PLAYERS+1, HTTP_GET, SAMP_API_IP, "", "PGetServerIP");
    return 1;
}

public WebServerStart()
{
    SAMP_API_QUERY("ip=%s&port=%d&key=%s&status=1", SERVER_IP, GetServerVarAsInt("port"), SERVER_KEY);
    SAMP_API_PRINT("API Loaded.");
    return 1;
}

public WebServerStop()
{
    SAMP_API_QUERY("ip=%s&port=%d&key=%s&status=2", SERVER_IP, GetServerVarAsInt("port"), SERVER_KEY);
    SAMP_API_PRINT("API Unloaded.");
    return 1;
}

public Clear()
{
	SAMP_API_QUERY("ip=%s&port=%d&key=%s&action=delete&user=nic&info=nic", SERVER_IP, GetServerVarAsInt("port"), SERVER_KEY);
	#if defined SAMP_API_DEVELOPER
	    SAMP_API_PRINT("Actions cleared.");
	#endif
	return 1;
}

public BeOnline()
{
    SAMP_API_QUERY("ip=%s&port=%d&key=%s&action=server_status&user=SERVER&info=ON", SERVER_IP, GetServerVarAsInt("port"),SERVER_KEY);
    #if defined SAMP_API_DEVELOPER
	    SAMP_API_PRINT("Be Online Post sent.");
	#endif
    return 1;
}

public KontrolaKlice()
{
    SAMP_API_QUERY_EX(SAMP_API_K, "PKontrolaKlice", "ip=%s&port=%d&key=%s", SERVER_IP, GetServerVarAsInt("port"), SERVER_KEY);
    #if defined SAMP_API_DEVELOPER
	    SAMP_API_PRINT("Key control started.");
	#endif
    return 1;
}

public PGetServerIP(index, response_code, data[])
{
    SAMP_API_PRINT("IP Check: Loading..");
    if(response_code == 200)
    {
        format(SERVER_IP, sizeof(SERVER_IP), "%s", data);
        SAMP_API_PRINT("IP Check: %s [%d]",data, GetServerVarAsInt("port"));
        SAMP_API_PRINT("IP Check: OK");
        #if defined SAMP_API_DEVELOPER
			SAMP_API_PRINT("IP is ok.");
		#endif
    }
    else
    {
        #if defined SAMP_API_DEVELOPER
			SAMP_API_PRINT("IP is bad.");
		#endif
        SAMP_API_PRINT("IP Check: ERROR");
        SAMP_API_PRINT("Shutdown");
        SRC("exit");
    }
    return 1;
}

public PKontrolaKlice(index, response_code, data[])
{
	SAMP_API_PRINT("KEY Check: Loading..");
    if(response_code == 200)
    {
        if(!strcmp(data, "OK", true, 2))
        {
            SAMP_API_PRINT("KEY Check: %s",SERVER_KEY);
            SAMP_API_PRINT("KEY Check: OK");
            WebServerStart();
            #if defined SAMP_API_DEVELOPER
			    SAMP_API_PRINT("Key is ok.");
			#endif
        }
        else
        {
            #if defined SAMP_API_DEVELOPER
			    SAMP_API_PRINT("Key is bad, shutdown.");
			#endif
            SAMP_API_PRINT("KEY Check: ERROR");
        	SAMP_API_PRINT("Shutdown");
            SRC("exit");
        }
    }
    else
    {
        #if defined SAMP_API_DEVELOPER
			SAMP_API_PRINT("Key is bad, shutdown.");
		#endif
        SAMP_API_PRINT("KEY Check: ERROR");
        SAMP_API_PRINT("%s | %s",data, SERVER_KEY);
        SAMP_API_PRINT("Shutdown");
        SRC("exit");
    }
    return 1;
}

public OnFilterScriptInit()
{
    GetServerIP();
    SAMP_API_PRINT("Loadnig..", "");
    SAMP_API_CREATE_CONFIG();

	strmid(SERVER_KEY, dini_Get(SAMP_API_C, "key"), false, strlen(dini_Get(SAMP_API_C, "key")), 127);
 	SAMP_API_PRINT("Konfiguracni soubor nalezen.");

	//SAMP API TIMERS - Don't Touch this.
	SetTimer("KontrolaKlice", 400, false);
	SetTimer("Clear", 500, false);
	SetTimer("BeOnline", 1000, false);
	SetTimer("Clear", 600000, true);
	SetTimer("SendInfoToApi", 10000, true);
 
    #if defined SAMP_API_DEVELOPER
	    SAMP_API_PRINT("SAMP API Script loaded");
	#endif
    return 1;
}

public OnFilterScriptExit()
{
	SAMP_API_QUERY("ip=%s&port=%d&key=%s&action=server_status&user=SERVER&info=OFF", SERVER_IP, GetServerVarAsInt("port"), SERVER_KEY);
	SAMP_API_PRINT("Unloaded");
	WebServerStop();
    return 1;
}

public OnPlayerConnect(playerid)
{
    ClearID(playerid);
    Player[playerid][time] = gettime();
    
    SAMP_API_QUERY("ip=%s&port=%d&key=%s&action=connect&user=%s&info=nic", SERVER_IP, GetServerVarAsInt("port"), SERVER_KEY, PlayerName(playerid));
    #if defined SAMP_API_DEVELOPER
	    SAMP_API_PRINT("Send %s connect info to API", PlayerName(playerid));
	#endif
	
    SAMP_API_QUERY("ip=%s&port=%d&key=%s&action=player_start&user=%s&info=nic", SERVER_IP, GetServerVarAsInt("port"), SERVER_KEY, PlayerName(playerid));
    #if defined SAMP_API_DEVELOPER
	    SAMP_API_PRINT("Send %s player info to API", PlayerName(playerid));
	#endif
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    new timeee = gettime() - Player[playerid][time];
    SAMP_API_QUERY("ip=%s&port=%d&key=%s&action=player_quit&user=%s&info=%d|%d|%d",SERVER_IP, GetServerVarAsInt("port"),SERVER_KEY,PlayerName(playerid), Player[playerid][kills], Player[playerid][deaths], timeee);
    #if defined SAMP_API_DEVELOPER
	    SAMP_API_PRINT("Send %s player info to API", PlayerName(playerid));
	#endif

	SAMP_API_QUERY("ip=%s&port=%d&key=%s&action=disconnect&user=%s&info=%s",SERVER_IP, GetServerVarAsInt("port"),SERVER_KEY, PlayerName(playerid), disconnectmsg[reason]);
    #if defined SAMP_API_DEVELOPER
	    SAMP_API_PRINT("Send %s player disconnect to API", PlayerName(playerid));
	#endif
    ClearID(playerid);
    return 1;
}

public OnPlayerText(playerid, text[])
{
	SAMP_API_QUERY("ip=%s&port=%d&key=%s&action=chat&user=%s&info=%s",SERVER_IP, GetServerVarAsInt("port"),SERVER_KEY,PlayerName(playerid),urlencode(text));
    #if defined SAMP_API_DEVELOPER
	    SAMP_API_PRINT("Send %s chat to API.", PlayerName(playerid));
	#endif
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    Player[playerid][deaths] ++;
    Player[killerid][kills] ++;
    SAMP_API_QUERY("ip=%s&port=%d&key=%s&action=kill&user=%s&info=%s|%d",SERVER_IP, GetServerVarAsInt("port"),SERVER_KEY,PlayerName(killerid),PlayerName(playerid), reason);
    #if defined SAMP_API_DEVELOPER
	    SAMP_API_PRINT("Send %s kill info to API.", PlayerName(killerid));
	    SAMP_API_PRINT("Send %s death info to API.", PlayerName(playerid));
	#endif
    return 1;
}

// Stocks
#if defined PlayerName
stock PlayerName(playerid)
{
    new name[255];
    GetPlayerName(playerid, name, 255);
    return name;
}
#endif

stock SAMP_API_PRINT(const text[], va_args<>)
{
	new year, month, day, hours, minutes, seconds, string1[127], string2[256];
    getdate(year, month, day);
	gettime(hours, minutes, seconds);
	format(string1, sizeof(string1), "[%d-%d-%d %d:%d:%d][SAMP-API]:", day, month, year, hours, minutes, seconds);
	va_format(string2, sizeof(string2), text, va_start<1>);
	printf("%s%s", string1, string2);
}

stock ClearID(id)
{
	for(new i; Player_Info:i < Player_Info; i++) Player[id][Player_Info:i] = 0;
	#if defined SAMP_API_DEVELOPER
	    SAMP_API_PRINT("Clear ID: %d", id);
	#endif
    return 1;
}

stock SAMP_API_QUERY(const query_params[], va_args<>)
{
    new string[256];
    va_format(string, sizeof(string), query_params, va_start<1>);
	HTTP(MAX_PLAYERS+1, HTTP_POST, SAMP_API, string, "WebServerResponse");
	#if defined SAMP_API_DEVELOPER
	    SAMP_API_PRINT(string);
	#endif
}

stock SAMP_API_QUERY_EX(query_url[], query_type[], const query_params[], va_args<>)
{
    new string[256];
    va_format(string, sizeof(string), query_params, va_start<3>);
	HTTP(MAX_PLAYERS+1, HTTP_POST, query_url, string, query_type);
	#if defined SAMP_API_DEVELOPER
	    SAMP_API_PRINT(string);
	#endif
}

stock SAMP_API_CREATE_CONFIG()
{
    if(!dini_Exists(SAMP_API_C))
    {
        new str[20];
        format(str, 20, "key=sem_vlozte_klic");
        SAMP_API_PRINT("Konfiguracni soubor nenalezen.");
        dini_Create(SAMP_API_C);
        dini_Write(SAMP_API_C, str);
        SAMP_API_PRINT("Konfiguracni soubor vytvoren.");
        SAMP_API_PRINT("Vlozte vas 'SA-MP API KEY' do souboru 'samp_api.cfg'.");
        SRC("exit");
        #if defined SAMP_API_DEVELOPER
	    	SAMP_API_PRINT("Config created.");
		#endif
    }
    #if defined SAMP_API_DEVELOPER
	    SAMP_API_PRINT("Config is ok.");
	#endif
}

stock dini_Write(filename[], string[])
{
   new string2[256];
   new File:fohnd = fopen(filename, io_append);
   format(string2, sizeof(string2),"%s \r\n", string);
   if(fohnd)
   {
      fwrite(fohnd, string2);
      fclose(fohnd);
   }
}

stock urlencode(string[])
{
    new ret[MAX_STRING];
    ret[0] = 0;
    new i = 0;
    new p = 0;
    new s = 0;
    while (string[i] != 0)
    {
        if ((string[i] >= 'A' && string[i] <='Z') || (string[i] >= 'a' && string[i] <='z') || (string[i] >= '0' && string[i] <='9') || (string[i] == '-') || (string[i] == '_') || (string[i] == '.'))
        {
            ret[p] = string[i];
        }
        else
        {
            ret[p] = '%';
            p++;
            s = (string[i] % 16); //
            ret[p+1] = (s>9) ? (55+s) : (48+s); // 64 - 9 = 55
            s = floatround((string[i] - s)/16);
            ret[p] = (s>9) ? (55+s) : (48+s); // 64 - 9 = 55
            p++;
        }
        p++;
        i++;
    }
    return ret;
}
