#include <a_samp>
#include <a_http>
#include <dini>

#pragma unused ret_memcpy

#define SRC SendRconCommand
#define SAMP_API    "samp-api.domm98.cz/api/sa-mp.php"
#define SAMP_API_IP "samp-api.domm98.cz/api/ip.php"
#define SAMP_API_K  "samp-api.domm98.cz/api/get_key.php"

new SERVER_IP[127];
new SERVER_KEY[127];

forward PGetServerIP(index, response_code, data[]);
forward PKontrolaKlice(index, response_code, data[]);

forward GetServerIP();
forward WebServerStart();
forward WebServerStop();
forward Clear();
forward BeOnline();
forward KontrolaKlice();

enum Player_Info
{
    kills,
    deaths,
    time,
    info
}
new Player[MAX_PLAYERS][Player_Info];

public GetServerIP()
{
    HTTP(MAX_PLAYERS+1, HTTP_GET, SAMP_API_IP, "", "PGetServerIP");
    return 1;
}

public WebServerStart()
{
    new string[256];
    format(string, sizeof(string), "ip=%s&port=%d&key=%s&status=1", SERVER_IP, GetServerVarAsInt("port"),SERVER_KEY);
    HTTP(MAX_PLAYERS+1, HTTP_POST, SAMP_API, string, "WebServerResponse");
    print("SA-MP API >> Load");
    return 1;
}

public WebServerStop()
{
    new string[256];
    format(string, sizeof(string), "ip=%s&port=%d&key=%s&status=2", SERVER_IP, GetServerVarAsInt("port"),SERVER_KEY);
    HTTP(MAX_PLAYERS+1, HTTP_POST, SAMP_API, string, "WebServerResponse");
    print("SA-MP API >> Unload");
    return 1;
}

public Clear()
{
    new string[120];
    format(string, sizeof(string), "ip=%s&port=%d&key=%s&action=delete&user=nic&info=nic",SERVER_IP, GetServerVarAsInt("port"),SERVER_KEY);
    HTTP(MAX_PLAYERS+1, HTTP_POST, SAMP_API, string, "WebServerResponse");
    return 1;
}

public BeOnline()
{
    new string[120];
    format(string, sizeof(string),"ip=%s&port=%d&key=%s&action=server_status&user=SERVER&info=ON",SERVER_IP, GetServerVarAsInt("port"),SERVER_KEY);
    HTTP(MAX_PLAYERS+1, HTTP_POST, SAMP_API, string, "WebServerResponse");
    return 1;
}

public OnFilterScriptInit()
{
    AntiDeAMX();
    GetServerIP();
    print("SA-MP API >> Loadnig..");
    new cfgfile[50];
    format(cfgfile, sizeof(cfgfile),"samp_api.cfg");
    if(!dini_Exists(cfgfile))
    {
        new str[20];
        format(str, 20, "key=sem_vlozte_klic");
        print("SA-MP API >> Konfiguracni soubor nenalezen.");
        dini_Create(cfgfile);
        dini_Write(cfgfile, str);
        print("SA-MP API >> Konfiguracni soubor vytvoren.");
        print("SA-MP API >> Vlozte vas 'SA-MP API KEY' do souboru 'samp_api.cfg'.");
        SRC("exit");
    }
    else
    {
        strmid(SERVER_KEY, dini_Get(cfgfile, "key"), false, strlen(dini_Get(cfgfile, "key")), 127);
        print("SA-MP API >> Konfiguracni soubor nalezen.");
        SetTimer("KontrolaKlice",400, false);
        SetTimer("Clear",500, false);
        SetTimer("BeOnline",1000, false);
        SetTimer("Clear", 600000, true);
        SetTimer("SendInfoToApi", 10000, true);
    }
    return 1;
}

public KontrolaKlice()
{
    new string[256];
    format(string, sizeof(string), "ip=%s&port=%d&key=%s", SERVER_IP, GetServerVarAsInt("port"), SERVER_KEY);
    HTTP(MAX_PLAYERS+1, HTTP_POST, SAMP_API_K, string, "PKontrolaKlice");
    return 1;
}

public OnFilterScriptExit()
{
    new string[120];
    format(string, sizeof(string), "ip=%s&port=%d&key=%s&action=server_status&user=SERVER&info=OFF",SERVER_IP, GetServerVarAsInt("port"),SERVER_KEY);
    HTTP(MAX_PLAYERS+1, HTTP_POST, SAMP_API, string, "WebServerResponse");
    WebServerStop();
    return 1;
}

public OnPlayerConnect(playerid)
{
    ClearID(playerid);
    Player[playerid][time] = gettime();
    new string[120];
    format(string, sizeof(string), "ip=%s&port=%d&key=%s&action=connect&user=%s&info=nic",SERVER_IP, GetServerVarAsInt("port"),SERVER_KEY,PlayerName(playerid));
    HTTP(MAX_PLAYERS+1, HTTP_POST, SAMP_API, string, "WebServerResponse");
    
    new string2[120];
	format(string2, sizeof(string2), "ip=%s&port=%d&key=%s&action=player_start&user=%s&info=nic",SERVER_IP, GetServerVarAsInt("port"),SERVER_KEY,PlayerName(playerid));
	HTTP(MAX_PLAYERS+1, HTTP_POST, SAMP_API, string2, "WebServerResponse");
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    new timeee = gettime() - Player[playerid][time];
    new string2[150];
    format(string2, sizeof(string2), "ip=%s&port=%d&key=%s&action=player_quit&user=%s&info=%d|%d|%d",SERVER_IP, GetServerVarAsInt("port"),SERVER_KEY,PlayerName(playerid), Player[playerid][kills], Player[playerid][deaths], timeee);
    HTTP(MAX_PLAYERS+1, HTTP_POST, SAMP_API, string2, "WebServerResponse");
    new disconnectmsg[3][] =
    {
        "CRASH",
        "QUIT",
        "KICK/BAN"
    };
    new string[150];
    format(string, sizeof(string), "ip=%s&port=%d&key=%s&action=disconnect&user=%s&info=%s",SERVER_IP, GetServerVarAsInt("port"),SERVER_KEY,PlayerName(playerid),disconnectmsg[reason]);
    HTTP(MAX_PLAYERS+1, HTTP_POST, SAMP_API, string, "WebServerResponse");
    ClearID(playerid);
    return 1;
}

public OnPlayerText(playerid, text[])
{
    new string[300];
    format(string, sizeof(string), "ip=%s&port=%d&key=%s&action=chat&user=%s&info=%s",SERVER_IP, GetServerVarAsInt("port"),SERVER_KEY,PlayerName(playerid),urlencode(text));
    HTTP(MAX_PLAYERS+1, HTTP_POST, SAMP_API, string, "WebServerResponse");
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    Player[playerid][deaths] ++;
    Player[killerid][kills] ++;
    new string[300];
    format(string, sizeof(string), "ip=%s&port=%d&key=%s&action=kill&user=%s&info=%s|%d",SERVER_IP, GetServerVarAsInt("port"),SERVER_KEY,PlayerName(killerid),PlayerName(playerid), reason);
    HTTP(MAX_PLAYERS+1, HTTP_POST, SAMP_API, string, "WebServerResponse");
    return 1;
}

public PGetServerIP(index, response_code, data[])
{
    print("SA-MP API >> IP Check: Loading..");
    if(response_code == 200)
    {
        format(SERVER_IP, sizeof(SERVER_IP), "%s", data);
        printf("SA-MP API >> IP Check: %s [%d]",data, GetServerVarAsInt("port"));
        print("SA-MP API >> IP Check: OK");
    }
    else
    {
        print("SA-MP API >> IP Check: ERROR");
        print("SA-MP API >> Shutdown");
        SRC("exit");
    }
    return 1;
}

public PKontrolaKlice(index, response_code, data[])
{
    print("SA-MP API >> KEY Check: Loading..");
    if(response_code == 200)
    {
        if(!strcmp(data, "OK", true, 2))
        {
            printf("SA-MP API >> KEY Check: %s",SERVER_KEY);
            print("SA-MP API >> KEY Check: OK");
            WebServerStart();
        }
        else
        {
            print("SA-MP API >> KEY Check: ERROR");
            print("SA-MP API >> Shutdown");
            SRC("exit");
        }
    }
    else
    {
        print("SA-MP API >> KEY Check: ERROR");
        printf("SA-MP API >> %s | %s",data, SERVER_KEY);
        print("SA-MP API >> Shutdown");
        SRC("exit");
    }
    return 1;
}

stock PlayerName(playerid)
{
    new name[255];
    GetPlayerName(playerid, name, 255);
    return name;
}

stock ClearID(playerid)
{
    Player[playerid][kills] = 0;
    Player[playerid][deaths] = 0;
    Player[playerid][time] = 0;
    Player[playerid][info] = 0;
    return 1;
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

AntiDeAMX()
{
    new antidamx[][] =
    {
        "Unarmed (Fist)",
        "Brass K",
        "Fire Ex"
   };
   #pragma unused antidamx
}
