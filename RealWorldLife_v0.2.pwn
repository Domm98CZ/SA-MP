/* INCLUDES */
#include <a_samp>
#include <zcmd>
#include <a_http>
#include <a_mysql>
/* NATIVES */
native WP_Hash(buffer[], len, const str[]);
/* MAIN CONFIG */
#define MOD_SNAME                        "[CZ / SK] Real World Life [0.3z]"
#define MOD_MNAME                        "Real World Life"
#define MOD_VERSION                      "0.1"
#define MOD_AUTOR                        "Domm"
#define MOD_WEB                          "rwl.domm98.cz"
#define MOD_MAP                          "San Andreas"
/* DATABASE CONFIG */
#define SQL_HOST                        ""
#define SQL_DB                          ""
#define SQL_USER                        ""
#define SQL_PASS                        ""
/* FILES */

/* DEFINITIONS - WEB */
#define WEB_API                         "rwl.domm98.cz/api/rwl.php"
#define WEB_API_PAIR                    "rwl.domm98.cz/api/rwl_pair.php"
/* DEFINITIONS - OTHER */
#define SCM                             SendClientMessage
#define SCMTA                           SendClientMessageToAll
#define SRC                             SendRconCommand
#define CMD_E                           SCM(playerid, -1, "{ff0000}[ ! ]{ffffff} Pøíkaz neexistuje!")
#define SCMF(%0,%1,%2,%3)               format(_string,sizeof(_string),%2,%3); SendClientMessage(%0,%1,_string)
#define SCMTAF(%0,%1,%2)                format(_strng,sizeof(_strng),%1,%2); SendClientMessageToAll(%0,_strng)
#define ForPlayers(%0)                  for(new %0; %0 <= MAX_PLAYERS;%0++) if(IsPlayerConnected(%0))
#define MAX_ENTRY                       500
#define MAX_LEN                         500
/* COLOR DEFINITIONS */
#define F_CERVENA                       0xFF0000AA
#define F_CYAN                          0x00FFFFAA
#define F_ZELENA                        0x00FF00AA
#define F_ZelenaV                       0x008000AA
#define F_SZelenaV                      0x00FF00AA
#define F_ModraV                        0x0000FFAA
#define F_CyanV                         0x00FFFFAA
#define F_MODRA                         0x33CCFFAA
#define F_BILA                          0xEFEFF7AA
#define F_RuzovaV                       0xBF00BFAA
#define F_SRuzovaV                      0xFF00FFAA
#define F_ZltaV                         0xFFFF00AA
#define F_OranzovaV                     0xDB881AAA
#define F_FialovaV                      0x7340DBAA
#define F_ZlataV                        0xFFd700AA
#define F_StriebornaV                   0xC0C0C0AA
#define F_CervenaV                      0xFF0000AA
#define F_ZelenaN                       0x00800000
#define F_SZelenaN                      0x00FF0000
#define F_ModraN                        0x0000FF00
#define F_CyanN                         0x00FFFF00
#define F_RuzovaN                       0xBF00BF00
#define F_SRuzovaN                      0xFF00FF00
#define F_ZltaN                         0xFFFF0000
#define F_OranzovaN                     0xDB881A00
#define F_FialovaN                      0x7340DB00
#define F_ZlataN                        0xFFd70000
#define F_StriebornaN                   0xC0C0C000
#define F_CervenaN                      0xFF000000
#define F_RZE                           0x7171FFAA
#define WHITE 0xFFFFFFAA
#define GREY 0xAFAFAFAA
#define RED 0xFF0000AA
#define YELLOW 0xFFFF00AA
#define LIGHTBLUE 0x33CCFFAA
/* FORWARDS */
forward ServerStart();
forward ServerStop();
forward PairWithWeb(playerid, web_name[]);
forward MainTimer();
forward RandomMessages();
forward Kickk(playerid);

forward OnPlayerDataLoaded(playerid, race_check);
forward OnPlayerRegister(playerid);
/* VARS */
enum E_PLAYERS {
	ORM:ORM_ID,
	ID,
	name[MAX_PLAYER_NAME],
	password[129],
	money,
	bool:IsLoggedIn,
	bool:IsRegistered,
	LoginAttempts,
	LoginTimer,
    level,
    xp,
    admin,
    Float:health,
    Float:armour,
    kills,
    deaths,
    time,
    freeze,
    mute,
    chat_spam,
    chat_spam_var,
    last_chat_time,
    last_cmd_time,
    played_time,
	create_time,
	prukaz_zbrojni,
	prukaz_auto,
	prukaz_motorka
}
new Player[MAX_PLAYERS][E_PLAYERS];

enum tInfo {
    sekundy
}
new Timer[tInfo];

enum ServerBillboardyInfo {
	nadrazi_lv1,
	nadrazi_lv2
}
new ServerBillBoard[ServerBillboardyInfo];

new g_SQL = -1;
new g_MysqlRaceCheck[MAX_PLAYERS];

new _string[127];
new _strng[127];

new ServerMessages[][] =
{
	"{949494}[ {66FF66}TIP {949494}] Navštiv náš web {66FF66}rwl.domm98.cz{949494}, dozvíš se zde všechny novinky.",
 	"{949494}[ {66FF66}TIP {949494}] Všechny informace o Premiovém úètu nalezneš po napsání pøíkazu {66FF66}/premium{949494}.",
    "{949494}[ {66FF66}TIP {949494}] Máš nìjaký dotaz a žádný z administrátorù není online? Napiš nám ho do {66FF66}/dotaz{949494} a bude èasem zodpovìzen.",
    "{949494}[ {66FF66}TIP {949494}] Nìjaký z hráèù, porušuje pravidla? Nahlaš ho administrátorùm pomocí pøíkazu {66FF66}/report{949494}.",
    "{949494}[ {66FF66}TIP {949494}] Máš nìjaké pøipomínky k módu? Napiš nám je na naše fórum {66FF66}rwl.domm98.cz/?page=forum{949494}."
};

new Hodnosti[][] =
{
	"",
	"{FFD700}[VIP] ",
	"{FFD700}[MOD] ",
	"{0088FF}[Admin] ",
	"{ff0000}[Admin] ",
	"{00b300}[Majitel] "
};

enum
{
	DIALOG_INVALID,
	DIALOG_UNUSED,

	DIALOG_LOGIN,
	DIALOG_REGISTER,
};


/*new RconAC[2][MAX_PLAYER_NAME] = 
{
    "Domm",
    "Domm2"
};*/

main()
{
    print("+----------------------------------------------+");
    print("|  ***        Real World Life             ***  |");
    print("+----------------------------------------------+");
    printf("  Autor: %s                     		", MOD_AUTOR);
    printf("  Gamemode: %s %s                       ", MOD_MNAME, MOD_VERSION);
    printf("  Server: %s                            ", MOD_SNAME);
    print("+----------------------------------------------+");
    print("|  ***        Real World Life             ***  |");
    print("+----------------------------------------------+");
}

public OnGameModeInit()
{
	ServerStart();
	mysql_log(LOG_ERROR | LOG_WARNING, LOG_TYPE_HTML);
    g_SQL = mysql_connect(SQL_HOST, SQL_USER,SQL_DB, SQL_PASS);
    SetGameModeText("Loading..");
    SRC("hostname "#MOD_SNAME);
    SRC("gamemodetext "#MOD_MNAME);
    SRC("mapname "#MOD_MAP);
    SRC("weburl "#MOD_WEB);

	UsePlayerPedAnims();

    SetTimer("MainTimer", 1000, true);
    SetTimer("RandomMessages", 5*60000, true);

    Timer[sekundy] = 0;
    
    UpdateUserData("DOMMRWLADMIN_YOLOMLG", "status", "0");
    AddPlayerClass(0,1438.6149,2686.9746,35.3852,0.0000,0,0,0,0,0,0); //
    
    AddStaticVehicleEx(405,1374.6000000,2695.1001000,10.8000000,0.0000000,32,32,15); //Sentinel
	AddStaticVehicleEx(431,1393.7000000,2680.1001000,11.1000000,0.0000000,78,104,15); //Bus
	AddStaticVehicleEx(489,1373.3000000,2651.3000000,11.2000000,0.0000000,155,139,15); //Rancher
	AddStaticVehicleEx(404,1357.2000000,2651.0000000,10.7000000,174.0000000,31,37,15); //Perrenial
	AddStaticVehicleEx(543,1363.1000000,2651.0000000,10.8000000,0.0000000,95,10,15); //Sadler
	AddStaticVehicleEx(558,1368.8000000,2648.3999000,10.5000000,0.0000000,100,13,15); //Uranus
	AddStaticVehicleEx(602,1352.0000000,2649.1001000,10.7000000,0.0000000,100,100,15); //Alpha
	AddStaticVehicleEx(401,1346.6000000,2651.6001000,10.7000000,0.0000000,52,26,15); //Bravura
	AddStaticVehicleEx(439,1340.9000000,2651.8000000,10.8000000,356.0000000,39,47,15); //Stallion
	AddStaticVehicleEx(542,1368.7000000,2695.3999000,10.7000000,0.0000000,71,53,15); //Clover
	AddStaticVehicleEx(405,1357.4000000,2695.5000000,10.8000000,168.0000000,98,68,15); //Sentinel
	AddStaticVehicleEx(429,2040.0000000,1004.5000000,10.3999996,179.9999390,135,135,300); //Banshee
    AddStaticVehicleEx(429,2040.0000000,1011.0999756,10.3999996,179.9945068,135,135,300); //Banshee
    AddStaticVehicleEx(429,2040.0000000,1017.5999756,10.3999996,179.9945068,135,135,300); //Banshee
    AddStaticVehicleEx(475,2246.0000000,2038.6999512,10.6999998,90.0000000,129,129,300); //Sabre
    AddStaticVehicleEx(475,2246.0000000,2042.5000000,10.6999998,90.0000000,129,129,300); //Sabre
    AddStaticVehicleEx(475,2246.1999512,2046.4000244,10.6999998,90.0000000,129,129,300); //Sabre
    AddStaticVehicleEx(475,2235.0000000,2046.3000488,10.6999998,270.0000000,129,129,300); //Sabre
    AddStaticVehicleEx(475,2235.0000000,2042.5000000,10.6999998,270.0000000,129,129,300); //Sabre
    AddStaticVehicleEx(475,2235.0000000,2038.6999512,10.6999998,270.0000000,129,129,300); //Sabre
	AddStaticVehicleEx(420,2192.5000000,1822.4000200,10.7000000,0.0000000,194,194,300); //Taxi
	AddStaticVehicleEx(420,2196.1999500,1822.5000000,10.7000000,0.0000000,194,194,300); //Taxi
	AddStaticVehicleEx(420,2199.8000500,1822.5000000,10.7000000,0.0000000,194,194,300); //Taxi
	AddStaticVehicleEx(420,2188.8999000,1822.4000200,10.7000000,0.0000000,194,194,300); //Taxi
	AddStaticVehicleEx(420,2187.1999500,1809.9000200,10.7000000,180.0000000,194,194,300); //Taxi
	AddStaticVehicleEx(420,2191.1999500,1809.9000200,10.7000000,180.0000000,194,194,300); //Taxi
	AddStaticVehicleEx(420,2195.0000000,1809.9000200,10.7000000,180.0000000,194,194,300); //Taxi
	AddStaticVehicleEx(420,2198.8999000,1809.9000200,10.7000000,180.0000000,194,194,300); //Taxi
	AddStaticVehicleEx(559,2169.6001000,1699.5000000,10.6000000,62.0000000,230,230,300); //Jester
	AddStaticVehicleEx(559,2163.6001000,1702.5999800,10.6000000,61.9960000,230,230,300); //Jester
	AddStaticVehicleEx(559,2175.8000500,1696.1999500,10.6000000,61.9960000,230,230,300); //Jester
	AddStaticVehicleEx(559,2158.0000000,1705.5000000,10.6000000,61.9960000,230,230,300); //Jester
	AddStaticVehicleEx(409,2422.6001000,1118.0000000,10.6000000,0.0000000,193,193,300); //Stretch
	AddStaticVehicleEx(409,2422.5000000,1129.5000000,10.6000000,180.0000000,193,193,300); //Stretch
	AddStaticVehicleEx(598,2279.8999000,2418.5000000,10.5000000,90.5000000,149,149,300); //Police Car (LVPD)
	AddStaticVehicleEx(598,2287.3999000,2418.6001000,10.7000000,90.5000000,149,149,300); //Police Car (LVPD)
	AddStaticVehicleEx(598,2294.3999000,2418.6999500,10.7000000,90.5000000,149,149,300); //Police Car (LVPD)
	AddStaticVehicleEx(598,2272.6001000,2418.3999000,10.5000000,90.5000000,149,149,300); //Police Car (LVPD)
	AddStaticVehicleEx(599,2264.8999000,2418.6001000,11.1000000,90.0000000,149,149,300); //Police Ranger
	AddStaticVehicleEx(599,2257.1999500,2418.5000000,11.2000000,90.0000000,149,149,300); //Police Ranger
	AddStaticVehicleEx(445,2765.1999500,1281.5999800,10.7000000,270.0000000,233,233,300); //Admiral
	AddStaticVehicleEx(445,2765.1999500,1278.3000500,10.7000000,270.0000000,233,233,300); //Admiral
	AddStaticVehicleEx(445,2765.1001000,1275.1999500,10.7000000,270.0000000,233,233,300); //Admiral
	AddStaticVehicleEx(445,2765.1999500,1272.0000000,10.7000000,270.0000000,233,233,300); //Admiral
	AddStaticVehicleEx(541,2176.8999000,1670.3000500,10.5000000,0.0000000,48,79,300); //Bullet
	AddStaticVehicleEx(541,2176.8999000,1676.9000200,10.5000000,0.0000000,48,79,300); //Bullet
	AddStaticVehicleEx(541,2176.8999000,1683.3000500,10.5000000,0.0000000,48,79,300); //Bullet
	AddStaticVehicleEx(407,1742.8000500,2066.8000500,11.2000000,254.5000000,181,181,300); //Firetruck
	AddStaticVehicleEx(407,1750.5999800,2077.8999000,11.2000000,180.9980000,181,181,300); //Firetruck
	AddStaticVehicleEx(407,1757.1999500,2077.8000500,11.2000000,180.9940000,181,181,300); //Firetruck
	AddStaticVehicleEx(407,1763.5999800,2077.8999000,11.2000000,180.9940000,181,181,300); //Firetruck
	AddStaticVehicleEx(407,1770.4000200,2077.8999000,11.2000000,180.9940000,181,181,300); //Firetruck
	AddStaticVehicleEx(411,1743.0000000,2071.8999000,10.6000000,236.0000000,181,181,300); //Infernus
	AddStaticVehicleEx(411,1744.9000200,2074.5000000,10.6000000,235.9970000,181,181,300); //Infernus
	AddStaticVehicleEx(565,1625.0000000,1816.6999500,10.5000000,0.0000000,158,158,300); //Flash
	AddStaticVehicleEx(416,1610.6999500,1831.4000200,11.1000000,0.0000000,158,158,300); //Ambulance
	AddStaticVehicleEx(416,1601.5999800,1831.4000200,11.1000000,0.0000000,158,158,300); //Ambulance
	AddStaticVehicleEx(416,1606.0000000,1831.5000000,11.1000000,0.0000000,158,158,300); //Ambulance
	AddStaticVehicleEx(416,1607.4000200,1850.0999800,11.1000000,0.0000000,158,158,300); //Ambulance
	AddStaticVehicleEx(416,1602.8000500,1850.0999800,11.1000000,0.0000000,158,158,300); //Ambulance
	AddStaticVehicleEx(416,1598.6999500,1850.0999800,11.1000000,0.0000000,158,158,300); //Ambulance
	AddStaticVehicleEx(416,1594.5999800,1850.0999800,11.1000000,0.0000000,158,158,300); //Ambulance
	AddStaticVehicleEx(416,1612.0999800,1850.0000000,11.1000000,0.0000000,158,158,300); //Ambulance
	AddStaticVehicleEx(541,2052.5000000,2149.3000500,10.5000000,180.0000000,166,166,300); //Bullet
	AddStaticVehicleEx(541,2055.6001000,2149.3000500,10.5000000,180.0000000,166,166,300); //Bulle
	AddStaticVehicleEx(439,2040.0000000,1438.0000000,10.6999998,182.0000000,-1,-1,300); //Stallion
	AddStaticVehicleEx(419,2040.0999756,1143.6999512,10.6000004,180.0000000,-1,-1,300); //Esperanto
	AddStaticVehicleEx(421,2040.1999512,924.5999756,9.1000004,180.0000000,-1,-1,300); //Washington
	AddStaticVehicleEx(540,2074.8999023,906.0000000,8.1000004,0.0000000,-1,-1,300); //Vincent
	AddStaticVehicleEx(566,2074.8000488,1015.5999756,10.6000004,0.0000000,-1,-1,300); //Tahoma
	AddStaticVehicleEx(467,2074.8999023,1099.8000488,10.5000000,0.0000000,-1,-1,300); //Oceanic
	AddStaticVehicleEx(547,2074.8000488,1267.5000000,10.5000000,0.0000000,-1,-1,300); //Primo
	AddStaticVehicleEx(491,2074.8999023,1393.0000000,10.6000004,0.0000000,-1,-1,300); //Virgo
	AddStaticVehicleEx(533,2074.6000977,1562.8000488,10.5000000,0.0000000,-1,-1,300); //Feltzer
	AddStaticVehicleEx(535,2091.6000977,1736.6999512,10.5000000,332.0000000,-1,-1,300); //Slamvan
	AddStaticVehicleEx(411,2154.8000488,1927.0000000,10.5000000,0.0000000,-1,-1,300); //Infernus
	AddStaticVehicleEx(480,2155.0000000,2171.3000488,10.5000000,0.0000000,-1,-1,300); //Comet
	AddStaticVehicleEx(415,2120.1000977,2190.1000977,10.5000000,180.0000000,-1,-1,300); //Cheetah
	AddStaticVehicleEx(541,2120.1000977,1939.5999756,10.3999996,180.0000000,-1,-1,300); //Bullet
	AddStaticVehicleEx(517,2094.5000000,1812.0999756,10.6000004,153.9999390,-1,-1,300); //Majestic
	AddStaticVehicleEx(589,2040.0000000,1662.0999756,10.3999996,180.0000000,-1,-1,300); //Club
	AddStaticVehicleEx(535,2121.8999000,1053.5999800,11.4000000,306.0000000,61,74,300); //Slamvan
	AddStaticVehicleEx(412,2192.6001000,1216.4000200,10.8000000,0.0000000,101,106,300); //Voodoo
	AddStaticVehicleEx(575,2135.8999000,1397.8000500,10.6000000,0.0000000,156,141,300); //Broadway
	AddStaticVehicleEx(507,2120.0000000,1398.0999800,10.8000000,0.0000000,101,106,300); //Elegant
	AddStaticVehicleEx(551,2116.8000500,1409.0999800,10.7000000,180.0000000,30,46,300); //Merit
	AddStaticVehicleEx(551,2135.6999500,1409.0999800,10.7000000,180.0000000,30,46,300); //Merit
	AddStaticVehicleEx(411,2126.3000500,1425.3000500,10.6000000,270.0000000,16,80,300); //Infernus
	AddStaticVehicleEx(480,2109.8999000,1528.0000000,10.7000000,270.0000000,42,119,300); //Comet
	AddStaticVehicleEx(587,2268.5000000,1528.0000000,10.5000000,270.0000000,95,10,300); //Euros
	AddStaticVehicleEx(534,2302.5000000,1473.0000000,42.6000000,90.0000000,22,34,300); //Remington
	AddStaticVehicleEx(516,2302.6001000,1487.3000500,42.7000000,89.5000000,37,37,300); //Nebula
	AddStaticVehicleEx(506,2352.8000500,1458.5000000,42.6000000,270.2500000,215,142,300); //Super GT
	AddStaticVehicleEx(527,2332.6001000,1650.1999500,10.6000000,0.0000000,52,26,300); //Cadrona
	AddStaticVehicleEx(426,2374.6001000,1708.1999500,10.6000000,270.0000000,156,161,300); //Premier
	AddStaticVehicleEx(547,2402.6999500,1629.8000500,10.7000000,0.0000000,91,93,300); //Primo
	AddStaticVehicleEx(547,2422.3000500,1016.5999800,10.7000000,180.0000000,91,93,300); //Primo
	AddStaticVehicleEx(518,2432.5000000,1230.0000000,10.6000000,0.0000000,115,14,300); //Buccaneer
	AddStaticVehicleEx(426,2479.5000000,1248.0999800,10.5000000,269.2500000,76,117,300); //Premier
	AddStaticVehicleEx(540,2612.1999500,1153.6999500,10.7000000,0.0000000,101,106,300); //Vincent
	AddStaticVehicleEx(585,2636.5000000,1067.4000200,10.5000000,0.0000000,70,89,300); //Emperor
	AddStaticVehicleEx(585,2632.1999500,1067.5000000,10.5000000,0.0000000,70,89,300); //Emperor
	AddStaticVehicleEx(516,2567.3000500,1078.6999500,10.6000000,90.0000000,37,37,300); //Nebula
	AddStaticVehicleEx(541,2403.5000000,1078.3000500,10.4000000,90.0000000,105,30,300); //Bullet
	AddStaticVehicleEx(410,2502.0000000,1008.0999800,10.6000000,270.7500000,63,62,300); //Manana
	AddStaticVehicleEx(518,2632.8000500,1288.5999800,10.6000000,0.0000000,158,164,300); //Buccaneer
	AddStaticVehicleEx(467,2610.6999500,1388.6999500,10.7000000,0.0000000,37,37,300); //Oceanic
	AddStaticVehicleEx(467,2605.8999000,1388.6999500,10.7000000,0.0000000,37,37,300); //Oceanic
	AddStaticVehicleEx(540,2468.8999000,1378.4000200,10.8000000,90.0000000,70,89,300); //Vincent
	AddStaticVehicleEx(540,2278.6999500,1378.4000200,10.8000000,90.0000000,70,89,300); //Vincent
	AddStaticVehicleEx(540,2088.0000000,1378.6999500,10.8000000,90.0000000,70,89,300); //Vincent
	AddStaticVehicleEx(550,1937.5000000,1458.4000200,10.7000000,90.0000000,102,28,300); //Sunrise
	AddStaticVehicleEx(421,1710.9000200,1458.0000000,10.8000000,164.0000000,37,37,300); //Washington
	AddStaticVehicleEx(421,1712.8000500,1464.5999800,10.8000000,164.0000000,37,37,300); //Washington
	AddStaticVehicleEx(529,1731.5000000,1585.1999500,10.3000000,348.0000000,156,161,300); //Willard
	AddStaticVehicleEx(415,1562.1999500,1792.1999500,10.7000000,180.0000000,63,62,300); //Cheetah
	AddStaticVehicleEx(415,1732.1999500,1902.0999800,10.7000000,180.0000000,63,62,300); //Cheetah
	AddStaticVehicleEx(415,1732.0999800,1917.9000200,10.7000000,180.0000000,63,62,300); //Cheetah
	AddStaticVehicleEx(415,1741.0999800,1903.8000500,10.7000000,180.0000000,63,62,300); //Cheetah
	AddStaticVehicleEx(415,1741.4000200,1936.6999500,10.7000000,180.0000000,63,62,300); //Cheetah
	AddStaticVehicleEx(401,1712.6999500,1937.6999500,10.7000000,0.0000000,54,65,300); //Bravura
	AddStaticVehicleEx(526,1712.5000000,2107.8000500,10.7000000,0.0000000,158,164,300); //Fortune
	AddStaticVehicleEx(576,1839.8000500,2168.1001000,10.6000000,270.0000000,32,32,300); //Tornado
	AddStaticVehicleEx(566,1922.4000200,2091.0000000,10.6000000,180.0000000,30,46,300); //Tahoma
	AddStaticVehicleEx(567,2102.6001000,2069.3999000,10.8000000,90.2500000,171,146,300); //Savanna
	AddStaticVehicleEx(567,2102.3000500,2059.6001000,10.8000000,90.2470000,171,146,300); //Savanna
	AddStaticVehicleEx(567,2102.5000000,2046.3000500,10.8000000,90.2470000,171,146,300); //Savanna
	AddStaticVehicleEx(546,2170.5000000,1981.5000000,10.7000000,270.0000000,102,28,300); //Intruder
	AddStaticVehicleEx(546,2170.3999000,1988.9000200,10.7000000,270.0000000,102,28,300); //Intruder
	AddStaticVehicleEx(546,2170.1999500,1996.8000500,10.7000000,270.0000000,102,28,300); //Intruder
	AddStaticVehicleEx(507,2034.3000500,1932.3000500,12.1000000,177.2500000,101,106,300); //Elegant
	AddStaticVehicleEx(507,2033.5999800,1922.1999500,12.1000000,177.2480000,101,106,300); //Elegant
	AddStaticVehicleEx(580,2222.3999000,1887.9000200,10.7000000,270.0000000,106,122,300); //Stafford
	AddStaticVehicleEx(575,2363.1001000,1948.8000500,10.6000000,0.0000000,52,26,300); //Broadway
	AddStaticVehicleEx(540,2340.0000000,2105.5000000,10.7000000,180.0000000,76,117,300); //Vincent
	AddStaticVehicleEx(546,2441.8999000,2048.0000000,10.7000000,271.7500000,132,4,300); //Intruder
	AddStaticVehicleEx(426,2532.3000500,2158.8999000,10.5000000,0.0000000,156,161,300); //Premier
	AddStaticVehicleEx(529,2633.8999000,2253.3000500,10.6000000,0.0000000,76,117,300); //Willard
	AddStaticVehicleEx(546,2529.1999500,2511.5000000,10.7000000,90.7500000,42,119,300); //Intruder
	AddStaticVehicleEx(546,2529.8000500,2515.5000000,10.7000000,90.7470000,42,119,300); //Intruder
	AddStaticVehicleEx(467,2420.8999000,2518.1999500,10.6000000,90.0000000,88,89,300); //Oceanic
	AddStaticVehicleEx(585,2192.0000000,2502.1999500,10.5000000,0.0000000,22,34,300); //Emperor
	AddStaticVehicleEx(547,2134.3999000,2358.1999500,10.5000000,90.0000000,125,98,300); //Primo
	AddStaticVehicleEx(547,2126.3000500,2358.1999500,10.5000000,90.0000000,125,98,300); //Primo
	AddStaticVehicleEx(492,1797.0000000,2123.8999000,10.7000000,30.0000000,61,74,300); //Greenwood
	AddStaticVehicleEx(516,1652.8000500,2178.6999500,10.6000000,88.0000000,38,55,300); //Nebula
	AddStaticVehicleEx(566,1355.0999800,1958.5000000,10.7000000,89.7500000,66,31,300); //Tahoma
	AddStaticVehicleEx(475,1382.3000500,1903.1999500,10.7000000,180.0000000,115,46,300); //Sabre
	AddStaticVehicleEx(575,1048.4000200,1818.5000000,10.6000000,90.0000000,48,79,300); //Broadway
	AddStaticVehicleEx(467,1012.5000000,1979.6999500,10.7000000,0.0000000,88,89,300); //Oceanic
	AddStaticVehicleEx(412,1959.3000500,1708.0000000,10.6000000,270.0000000,63,62,300); //Voodoo
	AddStaticVehicleEx(405,2025.0999800,1351.5999800,10.8000000,270.0000000,183,183,300); //Sentinel
	AddStaticVehicleEx(405,2025.5000000,1334.5999800,10.6000000,270.0000000,183,183,300); //Sentinel
	AddStaticVehicleEx(516,1916.8000500,1278.5000000,10.7000000,89.2500000,94,112,300); //Nebula
	AddStaticVehicleEx(411,1642.0999800,1150.1999500,10.6000000,180.0000000,114,42,300); //Infernus
	AddStaticVehicleEx(559,1520.1999500,1128.0999800,10.6000000,270.0000000,156,156,300); //Jester
	AddStaticVehicleEx(480,1359.5999800,1198.3000500,10.7000000,90.0000000,93,126,300); //Comet
	AddStaticVehicleEx(562,1012.5999800,1298.9000200,10.6000000,0.0000000,34,52,300); //Elegy
	AddStaticVehicleEx(565,2288.8999000,1767.9000200,10.5000000,268.0000000,22,34,300); //Flash
	AddStaticVehicleEx(527,2512.6001000,1750.0000000,10.6000000,0.0000000,32,32,300); //Cadrona
	AddStaticVehicleEx(400,2458.4099,1336.2269,10.9126,0.7541,113,1, 300); //
	AddStaticVehicleEx(404,2452.0225,1357.0425,10.5566,180.7527,109,100, 300); //
	AddStaticVehicleEx(422,2471.1555,1357.5778,10.8106,350.9131,101,25, 300); //
	AddStaticVehicleEx(445,2444.3457,1267.0575,10.6952,181.2193,37,37, 300); //
	AddStaticVehicleEx(445,2453.9819,1275.3585,10.6953,89.7070,37,37, 300); //
	AddStaticVehicleEx(458,2891.6267,2446.7805,10.6986,44.5489,113,1, 300); //
	AddStaticVehicleEx(479,2884.1743,2438.7146,10.6134,225.3759,60,35, 300); //
	AddStaticVehicleEx(492,2857.8152,2413.1841,10.6021,46.3788,81,27, 300); //
	AddStaticVehicleEx(526,2846.0654,2401.3518,10.5870,43.3423,17,1, 300); //
	AddStaticVehicleEx(543,2879.2507,2372.1653,10.6391,269.9351,43,8, 300); //
	AddStaticVehicleEx(529,2891.3967,2360.9595,10.4518,262.5826,10,10, 300); //
	AddStaticVehicleEx(533,2890.5122,2375.6450,10.5294,88.7599,83,1, 300); //
	AddStaticVehicleEx(561,2878.8516,2334.0662,10.6337,89.4507,43,21, 300); //
	AddStaticVehicleEx(565,2890.6189,2327.0920,10.4440,269.2281,62,62, 300); //
	AddStaticVehicleEx(554,2883.8813,2309.7136,10.9006,179.5492,65,32, 300); //
	AddStaticVehicleEx(579,2853.2898,2327.1313,10.7492,92.7878,53,53, 300); //
	AddStaticVehicleEx(589,2845.9082,2309.8196,10.4783,162.1832,7,7, 300); //
	AddStaticVehicleEx(587,2822.3721,2309.5173,10.5493,358.8443,75,1, 300); //
	AddStaticVehicleEx(602,2814.9883,2326.9001,10.6197,92.0059,75,77, 300); //
	AddStaticVehicleEx(418,2814.9028,2341.6758,10.9078,270.1284,81,81, 300); //
	AddStaticVehicleEx(404,2815.0645,2356.8943,10.5521,89.3122,66,25, 300); //
	AddStaticVehicleEx(478,2814.9863,2379.5688,10.8106,269.2732,40,1, 300); //
	AddStaticVehicleEx(480,2840.1211,2379.6287,10.5943,267.6829,53,53, 300); //
	AddStaticVehicleEx(483,2812.5627,2405.7080,10.8136,316.3680,16,0, 300); //
	AddStaticVehicleEx(439,2801.0051,2417.9875,10.7164,135.2677,54,38, 300); //
	AddStaticVehicleEx(426,2783.9456,2434.9590,10.5630,316.7861,10,10, 300); //
	AddStaticVehicleEx(431,2747.8184,2632.2014,10.9228,207.9268,55,83, 300); //
	AddStaticVehicleEx(431,2760.4087,2632.4980,10.9300,206.3631,55,83, 300); //
	AddStaticVehicleEx(431,2772.7742,2633.8728,10.9319,206.5895,55,83, 300); //
	AddStaticVehicleEx(414,2806.5691,2588.7849,10.9141,44.3903,67,1, 300); //
	AddStaticVehicleEx(414,2794.8337,2575.5154,10.9140,44.6466,9,1, 300); //
	AddStaticVehicleEx(401,2537.3506,2769.5681,10.5999,0.1539,87,87, 300); //
	AddStaticVehicleEx(405,2553.9753,2790.8650,10.6952,180.3193,11,1, 300); //
	AddStaticVehicleEx(426,2570.4797,2770.4392,10.5631,358.5030,42,42, 300); //
	AddStaticVehicleEx(456,2368.2246,2753.1719,10.9937,180.3099,102,65, 300); //
	AddStaticVehicleEx(498,2346.4075,2747.5730,10.8899,270.6653,20,117, 300); //
	//=========== BillBoardy serveru - Objekty
	ServerBillBoard[nadrazi_lv1] = CreateObject(4731,1433.5000000,2664.2000000,20.5000000,0.0000000,0.0000000,210.0000000); //object(billbrdlan2_05) (1)
	ServerBillBoard[nadrazi_lv2] = CreateObject(4731,1433.8000000,2644.8000000,20.5000000,0.0000000,0.0000000,30.0000000); //object(billbrdlan2_05) (2)
	//=========== BillBoardy serveru - Text
	SetObjectMaterialText(ServerBillBoard[nadrazi_lv1], "{FFFFFF}Nadrazi\n{0088FF}LV" , 0, OBJECT_MATERIAL_SIZE_256x128,"Arial", 50, 1, 0xFFFFFFFF, 0x00000000, OBJECT_MATERIAL_TEXT_ALIGN_CENTER);
	SetObjectMaterialText(ServerBillBoard[nadrazi_lv2], "{FFFFFF}Nadrazi\n{0088FF}LV" , 0, OBJECT_MATERIAL_SIZE_256x128,"Arial", 50, 1, 0xFFFFFFFF, 0x00000000, OBJECT_MATERIAL_TEXT_ALIGN_CENTER);
    return 1;
}

public OnGameModeExit()
{
    UpdateUserData("DOMMRWLADMIN_YOLOMLG", "status", "0");
	
    mysql_close();
    ServerStop();
    return 1;
}

public MainTimer()
{
    ForPlayers(i)
    {
        if(Player[i][freeze] > 0) Player[i][freeze] --;
        if(Player[i][freeze] == 1)
        {
            TogglePlayerControllable(i, 1);
            SCM(i, -1, "{ff0000}[ ! ]{ffffff} Nyní mùžeš opìt pohybovat.");
            SendUserActivity(PlayerName(i), "UNFREEZE", "NONE");
            SendToLog("UNFREEZE", PlayerName(i));
        }
        if(Player[i][mute] > 0) Player[i][mute] --;
        if(Player[i][mute] == 1)
        {
            SCM(i, -1, "{ff0000}[ ! ]{ffffff} Nyní mùžeš opìt psát do chatu.");
            SendUserActivity(PlayerName(i), "UNMUTE", "NONE");
            SendToLog("UNMUTE", PlayerName(i));
        }
        Timer[sekundy]++;
        if(Timer[sekundy] % 5)
        {
            Player[i][chat_spam] = 0;
            Player[i][chat_spam_var] = 0;
        }
        if(Timer[sekundy] % 10)
        {
            new strr[50];
            format(strr, 50, "%d", gettime());
            UpdateUserData(Player[i][name], "last_play", strr);
        }
    }
    return 1;
}

public RandomMessages()
{
    new randomMsg = random(sizeof(ServerMessages));
    SCMTA(-1, ServerMessages[randomMsg]);
    SendUserActivity("DOMMRWLADMIN_YOLOMLG", "SERVERMESSAGES", ServerMessages[randomMsg]);
    SendToLog("SERVERMESSAGES", ServerMessages[randomMsg]);
    return 1;
}

public Kickk(playerid)
{
    return Kick(playerid);
}

public ServerStart()
{
    SendToLog("MAIN", "Server online.");
    SendUserActivity("DOMMRWLADMIN_YOLOMLG", "CHAT", "Server online.");
    print("RWL WEB API >> Load");
    return 1;
}

public ServerStop()
{
    SendToLog("MAIN", "Server offline.");
    SendUserActivity("DOMMRWLADMIN_YOLOMLG", "CHAT", "Server offline.");
    print("RWL WEB API >> Unload");
    return 1;
}

public PairWithWeb(playerid, web_name[])
{
    new string[256];
    format(string, sizeof(string), "user=%s&web_name=%s", PlayerName(playerid), web_name);
    HTTP(MAX_PLAYERS+1, HTTP_POST, WEB_API_PAIR, string, "WebServerResponse");
    print(string);
    return 1;
}

public OnPlayerDataLoaded(playerid, race_check)
{
	if(race_check != g_MysqlRaceCheck[playerid]) return Kick(playerid);

	orm_setkey(Player[playerid][ORM_ID], "id");

    new string[128];
	switch(orm_errno(Player[playerid][ORM_ID]))
	{
		case ERROR_OK:
		{
			format(string, sizeof(string),"{ffffff}Herní úèet {0088FF}%s{ffffff} je registrovaný. Prosím pøihlašte se, zadáním vašeho hesla:", Player[playerid][name]);
			ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Pøihlášení", string, "Pøihlásit se", "Zrušit");
			Player[playerid][IsRegistered] = true;
		}
		case ERROR_NO_DATA:
		{
			format(string, sizeof(string), "{ffffff}Vítej {0088FF}%s{ffffff}, pøed vstupem do hry se prosím zaregistuj.\nZadej heslo k úètu, pro registraci:", Player[playerid][name]);
			ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Registration", string, "Zaregistrovat", "Zrušit");
			Player[playerid][IsRegistered] = false;
		}
	}
	return 1;
}
public OnPlayerConnect(playerid)
{
    ClearID(playerid);
    new str[120];
    format(str, 120, "%s|%s", PlayerName(playerid), PlayerIP(playerid));
    SendToLog("CONNECT", str);
    SendUserActivity(PlayerName(playerid), "CONNECT", "NONE");
    g_MysqlRaceCheck[playerid]++;
	for(new E_PLAYERS:e; e < E_PLAYERS; ++e) Player[playerid][e] = 0;
	GetPlayerName(playerid, Player[playerid][name], MAX_PLAYER_NAME);
	new ORM:ormid = Player[playerid][ORM_ID] = orm_create("players", g_SQL);
	orm_addvar_int(ormid, Player[playerid][ID], "id");
	orm_addvar_string(ormid, Player[playerid][name], MAX_PLAYER_NAME, "username");
	orm_addvar_string(ormid, Player[playerid][password], 129, "password");
	orm_addvar_int(ormid, Player[playerid][money], "money");
	orm_addvar_int(ormid, Player[playerid][level], "level");
	orm_addvar_int(ormid, Player[playerid][xp], "xp");
	orm_addvar_int(ormid, Player[playerid][admin], "admin");
	orm_addvar_int(ormid, Player[playerid][create_time], "create_time");
	orm_addvar_int(ormid, Player[playerid][played_time], "played_time");
	orm_setkey(ormid, "username");
	orm_load(ormid, "OnPlayerDataLoaded", "dd", playerid, g_MysqlRaceCheck[playerid]);
	
	new str2[256];
	format(str2, 128, "{949494}[ {66FF66}Server {949494}] Hráè {66FF66}%s {949494}[{66FF66}%d{949494}] se pøipojil na server!", PlayerName(playerid), playerid);
	SCMTA(0xFF0000AA, str2);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    new disconnectmsg[3][] =
    {
        "CRASH",
        "QUIT",
        "KICK/BAN"
    };
    new str[120], str2[256];
    format(str, 120, "%s|%s|%s", PlayerName(playerid), PlayerIP(playerid), disconnectmsg[reason]);
    SendToLog("DISCONNECT", str);
    SendUserActivity(PlayerName(playerid), "DISCONNECT", disconnectmsg[reason]);
    format(str2, 128, "{949494}[ {66FF66}Server {949494}] Hráè {66FF66}%s {949494}[{66FF66}%d{949494}] se odpojil ze serveru! {949494}[ {66FF66}Dùvod: {949494}%s{66FF66} {949494}]", PlayerName(playerid), playerid,  disconnectmsg[reason]);
    SCMTA(0xFF0000AA, str2);

    g_MysqlRaceCheck[playerid]++;
	if(Player[playerid][IsLoggedIn] && Player[playerid][ID] > 0) orm_save(Player[playerid][ORM_ID]); //if Player[playerid][ID] has a valid value, orm_save sends an UPDATE query, else an INSERT query
	orm_destroy(Player[playerid][ORM_ID]);
	
	ClearID(playerid);
    return 1;
}

public OnPlayerSpawn(playerid)
{
	ResetPlayerMoney(playerid);
	GivePlayerMoney(playerid, Player[playerid][money]);
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	SetPlayerPos(playerid, 1958.3783, 1343.1572, 15.3746);
    SetPlayerCameraPos(playerid, 2081.6750,1228.4432,61.2992);
    SetPlayerCameraLookAt(playerid, 2168.5728,1119.3196,33.6023);
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    new str[120],str2[120];
    format(str, 120, "%s|%s|%d", PlayerName(killerid), PlayerName(playerid), reason);
    SendToLog("KILL", str);
    format(str2,120, "%s|%d", PlayerName(playerid), reason);
    SendUserActivity(PlayerName(killerid), "KILL", str2);
    SendDeathMessage(killerid, playerid, reason);
    return 1;
}

public OnVehicleSpawn(vehicleid)
{
    return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
    return 1;
}

public OnPlayerText(playerid, text[])
{
    if(Player[playerid][mute] != 0)
    {
        SCMF(playerid, -1, "{ff0000}[ Anti Spam ]{ffffff} Jsi umlèen na {0088FF}%d{ffffff} sekund.",Player[playerid][mute]);
        return 0;
    }
    else
    {
        SCMTAF(F_BILA,"%s{ffffff}%s [ID: %d]: %s",Hodnosti[Player[playerid][admin]], PlayerName(playerid), playerid,text);
        Player[playerid][last_chat_time] = gettime();
        new str[120];
        format(str, 120, "%s|%s", PlayerName(playerid), urlencode(text));
        SendToLog("CHAT", str);
        SendUserActivity(PlayerName(playerid), "CHAT", urlencode(text));
        SetPlayerChatBubble(playerid, text, GetPlayerColor(playerid), 100.0, 10000);
    }
    Player[playerid][chat_spam]++;
    if(Player[playerid][chat_spam] >= 3)
    {
        if(Player[playerid][chat_spam_var] == 0)
        {
            Player[playerid][chat_spam_var] = 1;
            Player[playerid][chat_spam] = 0;
            SCM(playerid, -1, "{ff0000}[ Anti Spam ]{ffffff} Pokud budeš spamovat i nadále, budeš umlèen.");
            SCMTAF(F_BILA,"%s [ID: %d]: %s",PlayerName(playerid),playerid,text);
            
            Player[playerid][last_chat_time] = gettime();
            new str[120];
            format(str, 120, "%s|%s", PlayerName(playerid), urlencode(text));
            SendToLog("CHAT", str);
            SendUserActivity(PlayerName(playerid), "CHAT", urlencode(text));
            SetPlayerChatBubble(playerid, text, GetPlayerColor(playerid), 100.0, 10000);
            return 0;
        }
        Player[playerid][mute] = 30;
        Player[playerid][chat_spam] = 0;
        SCMF(playerid, -1, "{ff0000}[ Anti Spam ]{ffffff} Byl jsi umlèen na {0088FF}%d{ffffff} sekund.",Player[playerid][mute]);
        return 0;
    }
    return 0;
}

CMD:pair(playerid, params[])
{
    new jmeno[50],str[80];
    if(sscanf(params, "s", jmeno)) return SCM(playerid, -1, "{ff0000}[ ! ]{ffffff} Použití: {0088FF}/pair prihlasovaci_jmeno_na_webu");
    format(str, 80, "%s|%s", PlayerName(playerid), jmeno);
    SendToLog("PAIR", str);
    SendUserActivity(PlayerName(playerid), "PAIR", jmeno);
    PairWithWeb(playerid, jmeno);
    SCMF(playerid, -1, "{00fff7}[ Párování Úètu ] Byla odeslána žádost o spárování herního úètu s webovým úètem {ffffff}%s{00fff7}!", jmeno);
    return 1;
}

CMD:mute(playerid, params[])
{
    new a_id, a_duvod[50], a_time;
    if(Player[playerid][admin] > 1) return 0;
    if(sscanf(params,"iiz",a_id,a_time,a_duvod)) return SCM(playerid, -1, "{ff0000}[ ! ] {FFFFFF}Použití: /mute [ ID Hráèe ] [ Délka(s) ] [ Dùvod ]");
    if(!a_duvod[0]) return SCM(playerid, -1,"{ff0000}[ ! ] {FFFFFF}Použití: /mute [ ID Hráèe ] [ Délka(s) ] [ Dùvod ]");
    if(Player[a_id][admin] == 5) return SCM(playerid,-1,"{ff0000}[ ! ] {FFFFFF}Nemùžeš umlèet majitele serveru!");
    if(!IsPlayerConnected(a_id)) return SCM(playerid, -1, "{ff0000}[ ! ] {ffffff}Toto ID neni pøipojeno!");
    if(a_time < 0 || a_time > 1001) return SCM(playerid, -1, "{ff0000}[ ! ] {ffffff}Rozmezí minut je 2 - 999.");

    new string[127];
    if(a_time == 1000) format(string, 127,"{ff0000}Administrátor %s umlèel hráèe %s! [ Dùvod: %s ]",PlayerName(playerid), PlayerName(a_id), a_duvod);
    else if(a_time == 0) format(string, 127,"{ff0000}Administrátor %s odmlèel hráèe %s! [ Dùvod: %s ]",PlayerName(playerid), PlayerName(a_id), a_duvod);
    else if(a_time > 0 && a_time < 1000) format(string, 127,"{ff0000}Administrátor %s umlèel hráèe %s na %d sekund! [ Dùvod: %s ]",PlayerName(playerid), PlayerName(a_id), a_time, a_duvod);

    SCMTA(0x00AA00FF, string);
    new str[120],str2[120],str3[120];
    new timestr[10];
    format(timestr, 10, "%d", a_time);
    format(str, 120, "%s|%s|%d|%s", PlayerName(playerid), PlayerName(a_id), a_time, a_duvod);
    format(str2, 127, "%s|%s|%d", PlayerName(a_id), a_duvod, a_time);
    format(str3, 127, "%s|%s|%d", PlayerName(playerid), a_duvod, a_time);
    SendToLog("ADMIN:MUTE", str);
    SendUserActivity(PlayerName(playerid), "ADMIN:MUTE", str2);
    SendUserActivity(PlayerName(a_id), "MUTE", str3);
    Player[a_id][mute] = a_time;
    return 1;
}

CMD:freeze(playerid, params[])
{
    new a_id, a_duvod[50], a_time;
    if(Player[playerid][admin] > 1) return 0;
    if(sscanf(params,"iiz",a_id,a_time,a_duvod)) return SCM(playerid, -1, "{ff0000}[ ! ] {FFFFFF}Použití: /freeze [ ID Hráèe ] [ Délka(s) ] [ Dùvod ]");
    if(!a_duvod[0]) return SCM(playerid, -1,"{ff0000}[ ! ] {FFFFFF}Použití: /freeze [ ID Hráèe ] [ Délka(s) ] [ Dùvod ]");
    if(Player[a_id][admin] == 5) return SCM(playerid,-1,"{ff0000}[ ! ] {FFFFFF}Nemùžeš zmrazit majitele serveru!");
    if(!IsPlayerConnected(a_id)) return SCM(playerid, -1, "{ff0000}[ ! ] {ffffff}Toto ID neni pøipojeno!");
    if(a_time < 0 || a_time > 1001) return SCM(playerid, -1, "{ff0000}[ ! ] {ffffff}Rozmezí minut je 2 - 999.");

    new string[127];
    if(a_time == 1000)
    {
        format(string, 127,"{ff0000}Administrátor %s zmrazil hráèe %s! [ Dùvod: %s ]",PlayerName(playerid), PlayerName(a_id), a_duvod);
        TogglePlayerControllable(a_id,0);
    }
    else if(a_time == 0)
    {
        format(string, 127,"{ff0000}Administrátor %s odmrazil hráèe %s! [ Dùvod: %s ]",PlayerName(playerid), PlayerName(a_id), a_duvod);
        TogglePlayerControllable(a_id,1);
    }
    else if(a_time > 0 && a_time < 1000)
    {
        format(string, 127,"{ff0000}Administrátor %s zmrazil hráèe %s na %d sekund! [ Dùvod: %s ]",PlayerName(playerid), PlayerName(a_id), a_time, a_duvod);
        TogglePlayerControllable(a_id,0);
    }
    
    SCMTA(0x00AA00FF, string);
    new str[120],str2[120],str3[120];
    new timestr[10];
    format(timestr, 10, "%d", a_time);
    format(str, 120, "%s|%s|%d|%s", PlayerName(playerid), PlayerName(a_id), a_time, a_duvod);
    format(str2, 127, "%s|%s|%d", PlayerName(a_id), a_duvod, a_time);
    format(str3, 127, "%s|%s|%d", PlayerName(playerid), a_duvod, a_time);
    SendToLog("ADMIN:FREEZE", str);
    SendUserActivity(PlayerName(playerid), "ADMIN:FREEZE", str2);
    SendUserActivity(PlayerName(a_id), "FREEZE", str3);
    Player[a_id][freeze] = a_time;
    return 1;
}

CMD:say(playerid, params[])
{
    if(Player[playerid][admin] > 1) return 0;
    new str[127],string[127],text2[127];
    format(string, 127, "{ff0000}Administrátor %s: %s", PlayerName(playerid), params);
    SCMTA(-1, string);
    format(text2, 127, "%s", params);
    format(str, 120, "%s|%s", PlayerName(playerid), params);
    SendToLog("ADMIN:SAY", str);
    SendUserActivity(PlayerName(playerid), "ADMIN:SAY", text2);
    return 1;
}

CMD:kill(playerid, params[])
{
    SetPlayerHealth(playerid, 0);
    new string[127];
    format(string, 127, "{949494}[ {66FF66}Server {949494}] Hráè {66FF66}%s {949494}[{66FF66}%d{949494}] spáchal sebevraždu!", PlayerName(playerid), playerid);
    SendToLog("KILLME", PlayerName(playerid));
    SendUserActivity(PlayerName(playerid), "KILLME", PlayerName(playerid));
    return 1;
}

CMD:kick(playerid, params[])
{
	new a_id, a_duvod[50],string[127];
    if(Player[playerid][admin] > 3) return 0;
    if(sscanf(params,"iz",a_id,a_duvod)) return SCM(playerid,-1, "[ ! ] {FFFFFF}Použití: /kick [ ID Hráèe ] [ Dùvod ]");
    if(!a_duvod[0]) return SCM(playerid,-1,"[ ! ] {FFFFFF}Použití: /kick [ ID Hráèe ] [ Dùvod ]");
    if(Player[a_id][admin] == 5) return SCM(playerid,-1,"[ ! ] {FFFFFF}Nemùžeš vyhodit majitele serveru!");
    if(!IsPlayerConnected(a_id)) return SCM(playerid,-1, "[ ! ] {ffffff}Toto ID neni pøipojeno!");
    
    format(string, 127,"{ff0000}Administrátor %s vyhodil hráèe %s! [ Dùvod: %s ]",PlayerName(playerid), PlayerName(a_id), a_duvod);
	SCMTA(-1, string);
	
    new str[127],str2[127],str3[127];
    format(str, 127, "%s|%s|%s", PlayerName(playerid), PlayerName(a_id), a_duvod);
    format(str2, 127, "%s|%s", PlayerName(a_id), a_duvod);
    format(str3, 127, "%s|%s", PlayerName(playerid), a_duvod);
    SendToLog("ADMIN:KICK", str);
    SendUserActivity(PlayerName(playerid), "ADMIN:KICK", str2);
    SendUserActivity(PlayerName(a_id), "KICK", str3);
    Kick2(a_id);
    return 1;
}

CMD:setadmin(playerid, params[])
{
    new a_id, a_level;
    //if(Player[playerid][admin] != 5) return 0;
    if(sscanf(params,"ii",a_id,a_level)) return SCM(playerid,-1, "[ ! ] {FFFFFF}Použití: /setadmin [ ID Hráèe ] [ Level ]");
    //if(a_level > 4) return SCM(playerid,-1, "[ ! ] {FFFFFF}Použití: /setadmin [ ID Hráèe ] [ Level ]");
    //if(Player[a_id][admin] == 5) return SCM(playerid,-1,"[ ! ] {FFFFFF}Nemùžeš nastavit level majiteli serveru!");
    if(!IsPlayerConnected(a_id)) return SCM(playerid,-1, "[ ! ] {ffffff}Toto ID neni pøipojeno!");

	Player[a_id][admin]= a_level;
 	new query[256];
    format(query, sizeof(query), "UPDATE `players` SET `admin`= '%d' WHERE `username` = '%s'", a_level, Player[playerid][name]);
	mysql_query(g_SQL, query);
	return 1;
}

CMD:admin(playerid, params[])
{
	new str[50];
	format(str, 50, "{ffffff}Admin: %d", Player[playerid][admin]);
	SCM(playerid,-1, str);
	return 1;
}

public OnPlayerCommandReceived(playerid, cmdtext[])
{
    if(Player[playerid][last_cmd_time] != 0 && Player[playerid][last_cmd_time] - gettime() > 2)
    {
        SCM(playerid, -1, "{FF0000}[ ! ]{ffffff} Jeden pøíkaz za 2 sekundy!");
        return 0;
    }
    return 1;
}


public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
    Player[playerid][last_cmd_time] = gettime();
    /* CMD Log */
    new str[128];
    format(str, sizeof(str), "%s|%s|%d",PlayerName(playerid), cmdtext, success);
    SendToLog("COMMANDS", str);
    for(new i = 0;i < MAX_PLAYERS;i++)
    {
        if(Player[i][admin] > 0 && Player[playerid][admin] == 0)
        {
            new cmd[128];
            format(cmd, sizeof(cmd), "{551a8b}[CMD] {ffffff}%s{551a8b} (ID: {ffffff}%d{551a8b}): {ffffff}%s", PlayerName(playerid), playerid, cmdtext);
            SCM(i, 0x00FFAAFF, cmd);
        }
    }
    printf("[CMD] %s: %s", PlayerName(playerid), cmdtext);
    /* Error Message */
    if(success == 0)
    {
      CMD_E;
      return 1;
    }
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_INVALID || dialogid == DIALOG_UNUSED)
		return 1;


	switch(dialogid)
	{
	    case DIALOG_LOGIN:
	    {
	        if(!response)
	            return Kick(playerid);

			if(strlen(inputtext) <= 5)
				return ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Pøihlášení",
			 	"{ff0000}Tvé heslo musí obsahovat více než 5 znakù!\n{ffffff}Prosím napište vaše heslo:",
					"Pøihlásit se", "Zrušit");

			new hashed_pass[129];
			WP_Hash(hashed_pass, sizeof(hashed_pass), inputtext);

			if(strcmp(hashed_pass, Player[playerid][password]) == 0)
			{
				//correct password, spawn the player
				ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "Pøihlášení", "Byl jsi úspìšnì pøihlášen.", "OK", "");
				Player[playerid][IsLoggedIn] = true;

				SetSpawnInfo(playerid, 0, 0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 0, 0);
				SpawnPlayer(playerid);
			}
			else
			{
				Player[playerid][LoginAttempts]++;
				if(Player[playerid][LoginAttempts] >= 3)
				{
					ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "Pøihlášení","{ff0000}Zadal jsi 3x špatné heslo. Z bezpeènostních dùvodù jsi byl odpojen.", "OK", "");
					Kick2(playerid);
				}
				else ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Pøihlášení", "{ff0000}Špatné heslo!\n{ffffff}Prosím napište vaše heslo:", "Pøihlásit", "Zrušit");
			}
	    }

	    case DIALOG_REGISTER:
	    {
	        if(!response)
	            return Kick2(playerid);

            if(strlen(inputtext) <= 5)
				return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Registrace",
				 "{ff0000}Tvé heslo musí obsahovat více než 5 znakù!\n{ffffff}Prosím napište vaše heslo:",
					"Registrovat", "Zrušit");

			WP_Hash(Player[playerid][password], 129, inputtext);
			orm_save(Player[playerid][ORM_ID], "OnPlayerRegister", "d", playerid);
	    }

	    default:
			return 0;
	}
	return 1;
}

public OnPlayerRegister(playerid)
{
    new query[256];
    format(query, sizeof(query), "UPDATE `players` SET `create_time`= '%d' WHERE `username` = '%s' LIMIT 1", gettime(), Player[playerid][name]);
	mysql_query(g_SQL, query);
	
	ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "Registrace", "Herní úèet byl úspìšnì vytvoøen, byl jsi automaticky pøihlášen.", "OK", "");
	Player[playerid][IsLoggedIn] = true;
	Player[playerid][IsRegistered] = true;

	SetSpawnInfo(playerid, 0, 0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 0, 0);
	SpawnPlayer(playerid);
	return 1;
}

stock Kick2(playerid)
{
        return SetTimerEx("Kickk",10,false,"i",playerid);
}

stock PlayerName(playerid)
{
    new name2[255];
    GetPlayerName(playerid, name2, 255);
    return name2;
}

stock PlayerIP(playerid)
{
    new p_ip[255];
    GetPlayerIp(playerid, p_ip, 255);
    return p_ip;
}

stock ClearID(playerid)
{
    //Player[playerid][ORM:ORM_ID] 	= 0;
    Player[playerid][ID] 			= 0;
    //Player[playerid][name] 			= "";
    //Player[playerid][password] 		= "";
    Player[playerid][money] 		= 0;
    Player[playerid][IsLoggedIn] 	= false;
    Player[playerid][IsRegistered] 	= false;
    Player[playerid][LoginAttempts] = 0;
    Player[playerid][LoginTimer] 	= 0;
    Player[playerid][level] 		= 0;
    Player[playerid][xp] 			= 0;
    Player[playerid][admin]         = 0;
    Player[playerid][health]        = 0.0;
    Player[playerid][armour]        = 0.0;
    Player[playerid][kills]         = 0;
    Player[playerid][time]          = 0;
    Player[playerid][freeze]        = 0;
    Player[playerid][mute]          = 0;
    Player[playerid][chat_spam]     = 0;
    Player[playerid][chat_spam_var] = 0;
    Player[playerid][last_chat_time]= 0;
    Player[playerid][last_cmd_time] = 0;
	Player[playerid][played_time]   = 0;
    Player[playerid][create_time]   = 0;
    Player[playerid][prukaz_zbrojni]= 0;
    Player[playerid][prukaz_auto]   = 0;
    Player[playerid][prukaz_motorka]= 0;
    return 1;
}

stock SendToLog(log_type[], log[])
{
    new string[256];
    format(string, sizeof(string), "log_type=%s&log=%s", log_type, log);
    HTTP(MAX_PLAYERS+1, HTTP_POST, WEB_API, string, "WebServerResponse");
    print(string);
    return 1;
}

stock SendMessageToAdmins(message[])
{
	new str[256];
	format(str, 256, "{9B30FF}%s", message);
	ForPlayers(i) if(IsPlayerConnected(playerid)) if(Player[i][admin] > 2) SendClientMessage(i, -1, str);
}

stock SendUserActivity(user[], activity[], data[])
{
    new string[256];
    format(string, sizeof(string), "user=%s&action=%s&data=%s", user, activity, data);
    HTTP(MAX_PLAYERS+1, HTTP_POST, WEB_API, string, "WebServerResponse");
    print(string);
    return 1;
}

stock UpdateUserData(user[], updating[], data[])
{
    new string[256];
    format(string, sizeof(string), "user=%s&update_data=%s&data=%s", user, updating, data);
    HTTP(MAX_PLAYERS+1, HTTP_POST, WEB_API, string, "WebServerResponse");
    print(string);
	return 1;
}

stock urlencode(string[])
{
    new ret[300];
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

stock sscanf(string[], format[], {Float,_}:...)
{
        #if defined isnull
                if (isnull(string))
        #else
                if (string[0] == 0 || (string[0] == 1 && string[1] == 0))
        #endif
                {
                        return format[0];
                }
        #pragma tabsize 4
        new
                formatPos = 0,
                stringPos = 0,
                paramPos = 2,
                paramCount = numargs(),
                delim = ' ';
        while (string[stringPos] && string[stringPos] <= ' ')
        {
                stringPos++;
        }
        while (paramPos < paramCount && string[stringPos])
        {
                switch (format[formatPos++])
                {
                        case '\0':
                        {
                                return 0;
                        }
                        case 'i', 'd':
                        {
                                new
                                        neg = 1,
                                        num = 0,
                                        ch = string[stringPos];
                                if (ch == '-')
                                {
                                        neg = -1;
                                        ch = string[++stringPos];
                                }
                                do
                                {
                                        stringPos++;
                                        if ('0' <= ch <= '9')
                                        {
                                                num = (num * 10) + (ch - '0');
                                        }
                                        else
                                        {
                                                return -1;
                                        }
                                }
                                while ((ch = string[stringPos]) > ' ' && ch != delim);
                                setarg(paramPos, 0, num * neg);
                        }
                        case 'h', 'x':
                        {
                                new
                                        num = 0,
                                        ch = string[stringPos];
                                do
                                {
                                        stringPos++;
                                        switch (ch)
                                        {
                                                case 'x', 'X':
                                                {
                                                        num = 0;
                                                        continue;
                                                }
                                                case '0' .. '9':
                                                {
                                                        num = (num << 4) | (ch - '0');
                                                }
                                                case 'a' .. 'f':
                                                {
                                                        num = (num << 4) | (ch - ('a' - 10));
                                                }
                                                case 'A' .. 'F':
                                                {
                                                        num = (num << 4) | (ch - ('A' - 10));
                                                }
                                                default:
                                                {
                                                        return -1;
                                                }
                                        }
                                }
                                while ((ch = string[stringPos]) > ' ' && ch != delim);
                                setarg(paramPos, 0, num);
                        }
                        case 'c':
                        {
                                setarg(paramPos, 0, string[stringPos++]);
                        }
                        case 'f':
                        {

                                new changestr[16], changepos = 0, strpos = stringPos;
                                while(changepos < 16 && string[strpos] && string[strpos] != delim)
                                {
                                        changestr[changepos++] = string[strpos++];
                                }
                                changestr[changepos] = '\0';
                                setarg(paramPos,0,_:floatstr(changestr));
                        }
                        case 'p':
                        {
                                delim = format[formatPos++];
                                continue;
                        }
                        case '\'':
                        {
                                new
                                        end = formatPos - 1,
                                        ch;
                                while ((ch = format[++end]) && ch != '\'') {}
                                if (!ch)
                                {
                                        return -1;
                                }
                                format[end] = '\0';
                                if ((ch = strfind(string, format[formatPos], false, stringPos)) == -1)
                                {
                                        if (format[end + 1])
                                        {
                                                return -1;
                                        }
                                        return 0;
                                }
                                format[end] = '\'';
                                stringPos = ch + (end - formatPos);
                                formatPos = end + 1;
                        }
                        case 'u':
                        {
                                new
                                        end = stringPos - 1,
                                        id = 0,
                                        bool:num = true,
                                        ch;
                                while ((ch = string[++end]) && ch != delim)
                                {
                                        if (num)
                                        {
                                                if ('0' <= ch <= '9')
                                                {
                                                        id = (id * 10) + (ch - '0');
                                                }
                                                else
                                                {
                                                        num = false;
                                                }
                                        }
                                }
                                if (num && IsPlayerConnected(id))
                                {
                                        setarg(paramPos, 0, id);
                                }
                                else
                                {
                                        #if !defined foreach
                                                #define foreach(%1,%2) for (new %2 = 0; %2 < MAX_PLAYERS; %2++) if (IsPlayerConnected(%2))
                                                #define __SSCANF_FOREACH__
                                        #endif
                                        string[end] = '\0';
                                        num = false;
                                        new
                                                name2[MAX_PLAYER_NAME];
                                        id = end - stringPos;
                                        ForPlayers(playerid)
                                        {
                                                GetPlayerName(playerid, name2, sizeof (name2));
                                                if (!strcmp(name2, string[stringPos], true, id))
                                                {
                                                        setarg(paramPos, 0, playerid);
                                                        num = true;
                                                        break;
                                                }
                                        }
                                        if (!num)
                                        {
                                                setarg(paramPos, 0, INVALID_PLAYER_ID);
                                        }
                                        string[end] = ch;
                                        #if defined __SSCANF_FOREACH__
                                                #undef foreach
                                                #undef __SSCANF_FOREACH__
                                        #endif
                                }
                                stringPos = end;
                        }
                        case 's', 'z':
                        {
                                new
                                        i = 0,
                                        ch;
                                if (format[formatPos])
                                {
                                        while ((ch = string[stringPos++]) && ch != delim)
                                        {
                                                setarg(paramPos, i++, ch);
                                        }
                                        if (!i)
                                        {
                                                return -1;
                                        }
                                }
                                else
                                {
                                        while ((ch = string[stringPos++]))
                                        {
                                                setarg(paramPos, i++, ch);
                                        }
                                }
                                stringPos--;
                                setarg(paramPos, i, '\0');
                        }
                        default:
                        {
                                continue;
                        }
                }
                while (string[stringPos] && string[stringPos] != delim && string[stringPos] > ' ')
                {
                        stringPos++;
                }
                while (string[stringPos] && (string[stringPos] == delim || string[stringPos] <= ' '))
                {
                        stringPos++;
                }
                paramPos++;
        }
        do
        {
                if ((delim = format[formatPos++]) > ' ')
                {
                        if (delim == '\'')
                        {
                                while ((delim = format[formatPos++]) && delim != '\'') {}
                        }
                        else if (delim != 'z')
                        {
                                return delim;
                        }
                }
        }
        while (delim > ' ');
        return 0;
}

stock FIX_valstr(dest[], value, bool:pack = false)
{
    // format can't handle cellmin properly
    static const cellmin_value[] = !"-2147483648";

    if (value == cellmin)
        pack && strpack(dest, cellmin_value, 12) || strunpack(dest, cellmin_value, 12);
    else
        format(dest, 12, "%d", value), pack && strpack(dest, dest, 12);
}
#define valstr FIX_valstr
