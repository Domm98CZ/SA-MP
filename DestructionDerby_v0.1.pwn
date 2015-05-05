#include <a_samp>
#include <dini>

#define dcmd(%1,%2,%3)    if((strcmp((%3)[1], #%1, true, (%2)) == 0) && ((((%3)[(%2) + 1] == 0) && (dcmd_%1(playerid, ""))) || (((%3)[(%2) + 1] == 32) && (dcmd_%1(playerid, (%3)[(%2) + 2]))))) return true

#define SCMF(%0,%1,%2,%3) new _string[300]; format(_string,sizeof(_string),%2,%3); SendClientMessage(%0,%1,_string)
#define SCMTAF(%0,%1,%2) new _tring[300]; format(_tring,sizeof(_tring),%1,%2); SendClientMessageToAll(%0,_tring)
#define SCM SendClientMessage
#define SCMTA SendClientMessageToAll
#define SRC SendRconCommand
#define MAX_PLAYERS_EX 100

#define IP_CZ 						 1
#define IP_SK 						 2
#define IP_LOC                       3

new Rocket[MAX_PLAYERS];
new RocketFiring[MAX_PLAYERS];
new IsInInfernus[MAX_PLAYERS];
new Infernus[MAX_PLAYERS];
new CarJumping[MAX_PLAYERS];

new Params[4][8];
new FileData[7][128];

new GMSTART;
new GMSTARTERROR;

/* Pickupy */
new repair1, repair2; //Mapa 1 

/*
AddStaticVehicle(411,1475.5817,1781.4698,10.5396,180.1113,80,1); // 1
AddStaticVehicle(411,1330.2092,1735.8363,10.5474,270.5813,80,1); // 1
AddStaticVehicle(411,1328.2848,1787.6996,10.5474,247.5044,80,1); // 1
AddStaticVehicle(411,1291.1270,1562.8436,10.5474,268.0532,80,1); // 1
AddStaticVehicle(411,1327.3705,1327.6477,10.5474,275.6764,80,1); // 1
AddStaticVehicle(411,1526.3527,1217.4362,10.5396,44.0836,80,1); // 1
AddStaticVehicle(411,1535.4297,1382.6708,10.5923,88.8979,80,1); // 1
AddStaticVehicle(411,1522.4840,1536.7954,10.5668,74.9460,80,1); // 1
AddStaticVehicle(411,1545.2882,1648.7311,10.5474,152.1432,80,1); // 1

*/

new Float:Spawns[][] =
{
    {1475.5817, 1781.4698, 10.5396, 180.1113},
    {1330.2092, 1735.8363, 10.5474, 270.5813},
    {1328.2848, 1787.6996, 10.5474, 247.5044},
    {1291.1270, 1562.8436, 10.5474, 268.0532},
    {1327.3705, 1327.6477, 10.5474, 275.6764},
    {1526.3527, 1217.4362, 10.5396, 44.0836},
    {1535.4297, 1382.6708, 10.5923, 88.8979},
    {1522.4840, 1536.7954, 10.5668, 74.9460},
    {1545.2882, 1648.7311, 10.5474, 152.1432}
};

forward Kontrola(playerid);
forward Boom(playerid);
forward Jump(playerid);
forward p_repair1();
forward p_repair2();
forward FIRST();

#define MAX_ZONES 100

enum gzinfo
{
  Float:gmaxX,
  Float:gmaxY,
  Float:gminY,
  Float:gminX,
  id,
};

new Zone[MAX_ZONES][gzinfo];
new LastZone = 0;

stock chrfind(n,h[],s=0)
{
	new l=strlen(h);
	while(s<l)
	{
		if(h[s]==n) return s;s++;
	}
	return -1;
}

stock GangZoneCreate2(Float:minx, Float:miny, Float:maxx, Float:maxy)
{
  GangZoneCreate(minx,miny,maxx,maxy);
  Zone[LastZone][gminX]=minx;
  Zone[LastZone][gminY]=miny;
  Zone[LastZone][gmaxX]=maxx;
  Zone[LastZone][gmaxY]=maxy;
  Zone[LastZone][id]=LastZone;
  printf("Gangzone ID: %d | Created",LastZone);
  LastZone++;
  return 1;
}

stock IsPlayerInAnyGangZone(playerid,gangzoneid)
{
  new Float:Pos[3];
  GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);
  if(Pos[0] <= Zone[gangzoneid][gminX] &&
	 Pos[0] >= Zone[gangzoneid][gmaxX] &&
	 Pos[1] <= Zone[gangzoneid][gminY] &&
	 Pos[1] >= Zone[gangzoneid][gmaxY]) return 1;
  else return 0;
}

stock GetPlayerZone(playerid)
{
    for( new g=0; g<MAX_ZONES; g++)
    {
        if( IsPlayerInGangZone(playerid, g) )
        {
            return Zone[g][id]; /*error*/
        }
    }

    return g;
}

stock PlayerToPoint(Float:radi, playerid, Float:x, Float:y, Float:z)
{
        new Float:oldposx, Float:oldposy, Float:oldposz;
        new Float:tempposx, Float:tempposy, Float:tempposz;
        GetPlayerPos(playerid, oldposx, oldposy, oldposz);
        tempposx = (oldposx -x);
        tempposy = (oldposy -y);
        tempposz = (oldposz -z);
        if (((tempposx < radi) && (tempposx > -radi)) && ((tempposy < radi) && (tempposy > -radi)) && ((tempposz < radi) && (tempposz > -radi)))
        {
                return 1;
        }
        return 0;
}

stock Float:GetXYInFrontOfPlayer(playerid, &Float:x, &Float:y, Float:distance)
{
    new Float:a;
    GetPlayerPos(playerid, x, y, a);
    if (IsPlayerInAnyVehicle(playerid))
        GetVehicleZAngle(GetPlayerVehicleID(playerid), a);
    else
        GetPlayerFacingAngle(playerid, a);
    x += (distance * floatsin(-a, degrees));
    y += (distance * floatcos(-a, degrees));
    return a;
}

stock Jmeno(playerid)
{
	new n[MAX_PLAYER_NAME];
	GetPlayerName(playerid,n,MAX_PLAYER_NAME);
	return n;
}

stock SendToLog(text[])
{
		new str[120];
		new Hour, Minute, Second, Year, Month, Day;
		gettime(Hour, Minute, Second);
		getdate(Year, Month, Day);
		format(str, 120, "[%d:%d:%d - %d/%d/%d] %s\r\n", Hour, Minute, Second, Day, Month, Year, text);
		new File:log = fopen("DD/log.txt", io_append);
		fwrite(log, str);
		printf("Domm: %s",text);
		fclose(log);
}

stock GetPlayerIP(playerid)
{
    new plrIP[16];
    GetPlayerIp(playerid, plrIP, sizeof(plrIP));
    if(strcmp(plrIP, "127.0.0.1"))
    {
        format(plrIP, sizeof(plrIP), "%s","Localhost");
    }
    else if(!strcmp(plrIP, "127.0.0.1"))
    {
    	GetPlayerIp(playerid, plrIP, sizeof(plrIP));
	}
	return plrIP;
}

public FIRST()
{
	if(GMSTART < 10)
	{
	    print("\r\n");
	    GMSTART++;
	}
	else if(GMSTART == 10)
	{
	    SRC("gmx");
	}
	return 1;
}

public Boom(playerid)
{
	new Float:X, Float:Y, Float:Z;
	GetObjectPos(Rocket[playerid], X, Y, Z);
	DestroyObject(Rocket[playerid]);
	CreateExplosion(X, Y, Z, 6, 10.0);
	RocketFiring[playerid] = 0;
	return 1;
}

public Jump(playerid)
{
	CarJumping[playerid] =0;
	return 1;
}

public Kontrola(playerid)
{
	new Float:pX,Float:pY,Float:pZ;
	GetPlayerPos(playerid,pX,pY,pZ);
	if(pX <= Zone[0][gminX] && pY <= Zone[0][gminY] && pX >= Zone[0][gmaxX] && pY >= Zone[0][gmaxY])
	{
	    //Ok
		if(GetVehicleModel(GetPlayerVehicleID(playerid)) == 411)
		{
			//OK
		}
		else if(GetVehicleModel(GetPlayerVehicleID(playerid)) != 411)
		{
			IsInInfernus[playerid] = 0;
			RocketFiring[playerid] = 0;
			SetPlayerHealth(playerid, 0);
		}
	}
	else
	{
		IsInInfernus[playerid] = 0;
		RocketFiring[playerid] = 0;
		SetPlayerHealth(playerid, 0);
	}
	
	return 1;
}

public p_repair1()
{
	repair1 = CreatePickup(3096, 14, 1426.2197, 1463.4635, 10.5474, -1); //Repair 1
	return 1;
}

public p_repair2()
{
	repair2 = CreatePickup(3096, 14, 1440.3478, 1462.8029, 10.5474, -1); //Repair 2
	return 1;
}

public OnGameModeInit()
{
	SetGameModeText("Destruction Derby v1.0");
	CreateObject(8148,1557.7998000,1622.2998000,12.9000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1557.7998000,1460.1992200,12.9000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (2)
	CreateObject(8148,1553.3000500,1303.0000000,12.9000000,0.0000000,0.0000000,176.9950000); //object(vgsselecfence02) (3)
	CreateObject(8150,1520.2998000,1203.0000000,13.0000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(7033,1433.0000000,1463.9000200,14.4000000,0.0000000,0.0000000,0.0000000); //object(vgnhsegate02) (1)
	CreateObject(744,1444.6999500,1499.5999800,8.4000000,0.0000000,0.0000000,0.0000000); //object(sm_scrub_rock4) (1)
	CreateObject(744,1427.5000000,1518.4000200,9.4000000,0.0000000,0.0000000,0.0000000); //object(sm_scrub_rock4) (2)
	CreateObject(744,1425.5999800,1504.8000500,9.4000000,0.0000000,0.0000000,0.0000000); //object(sm_scrub_rock4) (3)
	CreateObject(744,1442.5999800,1515.0000000,6.1000000,0.0000000,0.0000000,0.0000000); //object(sm_scrub_rock4) (4)
	CreateObject(744,1411.3000500,1534.5999800,9.1000000,0.0000000,0.0000000,0.0000000); //object(sm_scrub_rock4) (5)
	CreateObject(744,1433.6999500,1544.3000500,9.6000000,0.0000000,0.0000000,0.0000000); //object(sm_scrub_rock4) (6)
	CreateObject(744,1444.9000200,1556.0000000,9.6000000,0.0000000,0.0000000,0.0000000); //object(sm_scrub_rock4) (7)
	CreateObject(744,1453.0000000,1534.1999500,9.6000000,0.0000000,0.0000000,0.0000000); //object(sm_scrub_rock4) (8)
	CreateObject(744,1447.0999800,1565.6999500,9.6000000,0.0000000,0.0000000,6.0000000); //object(sm_scrub_rock4) (9)
	CreateObject(744,1431.0999800,1577.3000500,9.6000000,0.0000000,0.0000000,17.9990000); //object(sm_scrub_rock4) (10)
	CreateObject(744,1425.5999800,1562.0999800,9.6000000,0.0000000,0.0000000,61.9960000); //object(sm_scrub_rock4) (11)
	CreateObject(744,1446.9000200,1583.6999500,5.9000000,0.0000000,0.0000000,61.9900000); //object(sm_scrub_rock4) (12)
	CreateObject(744,1439.8000500,1598.8000500,8.4000000,0.0000000,0.0000000,329.9900000); //object(sm_scrub_rock4) (13)
	CreateObject(744,1426.3000500,1612.4000200,8.4000000,0.0000000,0.0000000,329.9850000); //object(sm_scrub_rock4) (14)
	CreateObject(744,1421.0000000,1600.6999500,8.4000000,0.0000000,0.0000000,329.9850000); //object(sm_scrub_rock4) (15)
	CreateObject(744,1442.3000500,1627.3000500,10.4000000,0.0000000,0.0000000,329.9850000); //object(sm_scrub_rock4) (16)
	CreateObject(744,1431.1999500,1641.0000000,9.1000000,0.0000000,358.0000000,329.9850000); //object(sm_scrub_rock4) (17)
	CreateObject(744,1420.6999500,1647.5000000,9.6000000,0.0000000,357.9950000,329.9850000); //object(sm_scrub_rock4) (18)
	CreateObject(744,1428.4000200,1662.0000000,6.1000000,0.0000000,357.9950000,329.9850000); //object(sm_scrub_rock4) (19)
	CreateObject(744,1437.0000000,1675.3000500,8.6000000,0.0000000,357.9950000,329.9850000); //object(sm_scrub_rock4) (20)
	CreateObject(744,1446.4000200,1666.0999800,8.6000000,0.0000000,357.9950000,329.9850000); //object(sm_scrub_rock4) (21)
	CreateObject(744,1424.0999800,1679.4000200,8.6000000,0.0000000,1.9950000,333.9850000); //object(sm_scrub_rock4) (22)
	CreateObject(744,1429.1999500,1689.9000200,8.6000000,0.0000000,359.9940000,353.9840000); //object(sm_scrub_rock4) (23)
	CreateObject(744,1441.0999800,1697.0000000,8.6000000,0.0000000,355.9890000,355.9790000); //object(sm_scrub_rock4) (24)
	CreateObject(744,1450.0000000,1684.0000000,8.6000000,0.0000000,349.9840000,353.9790000); //object(sm_scrub_rock4) (25)
	CreateObject(744,1450.3000500,1680.3000500,8.6000000,0.0000000,349.9800000,349.9740000); //object(sm_scrub_rock4) (26)
	CreateObject(672,1450.0999800,1385.4000200,5.1000000,0.0000000,0.0000000,0.0000000); //object(sm_veg_tree5) (1)
	CreateObject(672,1439.5999800,1393.3000500,9.1000000,0.0000000,0.7500000,317.5000000); //object(sm_veg_tree5) (2)
	CreateObject(689,1418.0999800,1430.5999800,-0.4000000,0.0000000,0.0000000,331.7500000); //object(sm_fir_copse1) (1)
	CreateObject(689,1439.3000500,1428.0000000,8.0000000,0.0000000,0.0000000,0.0000000); //object(sm_fir_copse1) (2)
	CreateObject(706,1423.0000000,1398.6999500,5.3000000,0.0000000,0.0000000,0.0000000); //object(sm_vegvbbig) (1)
	CreateObject(706,1415.5000000,1374.1999500,8.1000000,0.0000000,4.2500000,60.0000000); //object(sm_vegvbbig) (2)
	CreateObject(745,1439.0999800,1351.3000500,9.8000000,0.0000000,0.0000000,0.0000000); //object(sm_scrub_rock5) (1)
	CreateObject(745,1423.0000000,1343.3000500,8.3000000,0.0000000,0.0000000,0.0000000); //object(sm_scrub_rock5) (2)
	CreateObject(745,1436.0000000,1344.1999500,8.3000000,0.0000000,0.0000000,0.0000000); //object(sm_scrub_rock5) (3)
	CreateObject(745,1430.8000500,1371.0000000,8.3000000,0.0000000,0.0000000,0.0000000); //object(sm_scrub_rock5) (4)
	CreateObject(745,1439.0999800,1376.0999800,10.1000000,0.0000000,0.0000000,0.0000000); //object(sm_scrub_rock5) (5)
	CreateObject(745,1450.8000500,1363.1999500,10.1000000,0.0000000,0.0000000,0.0000000); //object(sm_scrub_rock5) (6)
	CreateObject(745,1439.6999500,1416.6999500,10.1000000,0.0000000,0.0000000,120.0000000); //object(sm_scrub_rock5) (7)
	CreateObject(745,1448.5999800,1409.9000200,10.1000000,0.0000000,0.0000000,199.9980000); //object(sm_scrub_rock5) (8)
	CreateObject(745,1431.9000200,1404.8000500,10.1000000,0.0000000,0.0000000,259.9950000); //object(sm_scrub_rock5) (9)
	CreateObject(745,1419.1999500,1353.3000500,10.1000000,0.0000000,0.0000000,259.9910000); //object(sm_scrub_rock5) (10)
	CreateObject(745,1439.4000200,1332.9000200,8.4000000,0.0000000,0.0000000,259.9910000); //object(sm_scrub_rock5) (11)
	CreateObject(744,1443.1999500,1300.5999800,9.8000000,0.0000000,0.0000000,0.0000000); //object(sm_scrub_rock4) (27)
	CreateObject(744,1421.5999800,1320.1999500,7.6000000,0.0000000,0.0000000,254.0000000); //object(sm_scrub_rock4) (28)
	CreateObject(744,1430.8000500,1309.5000000,7.6000000,0.0000000,0.0000000,253.9980000); //object(sm_scrub_rock4) (29)
	CreateObject(744,1443.1999500,1313.4000200,5.9000000,0.0000000,0.0000000,253.9980000); //object(sm_scrub_rock4) (30)
	CreateObject(744,1431.5000000,1287.0000000,7.2000000,0.0000000,0.0000000,253.9980000); //object(sm_scrub_rock4) (31)
	CreateObject(744,1444.0000000,1286.8000500,7.2000000,0.0000000,0.0000000,253.9980000); //object(sm_scrub_rock4) (32)
	CreateObject(744,1418.6999500,1296.4000200,8.5000000,0.0000000,24.0000000,25.9980000); //object(sm_scrub_rock4) (33)
	CreateObject(744,1448.5999800,1322.9000200,8.5000000,0.0000000,330.0000000,25.9940000); //object(sm_scrub_rock4) (34)
	CreateObject(703,1431.5999800,1325.0999800,9.1000000,0.0000000,0.0000000,0.0000000); //object(sm_veg_tree7_big) (1)
	CreateObject(703,1422.0000000,1304.0999800,7.1000000,0.0000000,0.0000000,0.0000000); //object(sm_veg_tree7_big) (2)
	CreateObject(703,1438.0999800,1296.0999800,-2.4000000,0.0000000,6.0000000,102.0000000); //object(sm_veg_tree7_big) (3)
	CreateObject(703,1450.6999500,1308.6999500,10.1000000,0.0000000,3.9990000,101.9970000); //object(sm_veg_tree7_big) (4)
	CreateObject(703,1450.3000500,1338.8000500,9.1000000,0.0000000,3.9940000,101.9970000); //object(sm_veg_tree7_big) (5)
	CreateObject(703,1440.3000500,1361.9000200,9.1000000,0.0000000,5.9940000,101.9970000); //object(sm_veg_tree7_big) (6)
	CreateObject(703,1429.3000500,1348.9000200,7.9000000,0.0000000,5.9930000,101.9970000); //object(sm_veg_tree7_big) (7)
	CreateObject(13005,1524.8000500,1530.5999800,12.2000000,0.0000000,2.2500000,75.5000000); //object(sw_logs6) (1)
	CreateObject(17016,1524.8000500,1656.5000000,13.9000000,0.0000000,270.0000000,248.0010000); //object(cutnwplant09) (1)
	CreateObject(17016,1522.5000000,1682.0000000,13.9000000,0.0000000,270.0000000,248.0000000); //object(cutnwplant09) (2)
	CreateObject(17021,1528.5996100,1833.2998000,18.5000000,0.0000000,0.0000000,233.9980000); //object(cuntplant06) (1)
	CreateObject(13607,1379.0000000,1821.1999500,22.2000000,0.0000000,146.7500000,318.7500000); //object(ringwalls) (1)
	CreateObject(9958,1426.4000200,1784.9000200,12.5000000,40.2810000,294.4150000,56.9270000); //object(submarr_sfe) (1)
	CreateObject(1391,1538.5000000,1753.0000000,41.8000000,0.0000000,0.0000000,0.0000000); //object(twrcrane_s_03) (1)
	CreateObject(1391,1539.1999500,1791.0000000,41.8000000,0.0000000,0.0000000,0.0000000); //object(twrcrane_s_03) (2)
	CreateObject(1391,1525.4000200,1756.4000200,26.6000000,54.0000000,0.0000000,30.0000000); //object(twrcrane_s_03) (3)
	CreateObject(1391,1527.8000500,1752.4000200,29.6000000,0.0000000,44.0000000,0.0000000); //object(twrcrane_s_03) (4)
	CreateObject(8493,1323.5000000,1617.0999800,15.2000000,0.0000000,86.0000000,0.0000000); //object(pirtshp01_lvs) (1)
	CreateObject(8493,1348.6999500,1615.3000500,27.5000000,10.7500000,0.0000000,0.0000000); //object(pirtshp01_lvs) (2)
	CreateObject(8842,1316.8000500,1437.3000500,31.7000000,0.0000000,0.0000000,274.0000000); //object(vgse24hr_lvs) (1)
	CreateObject(16054,1524.0000000,1223.8000500,13.0000000,0.0000000,0.0000000,316.0000000); //object(des_westrn9_01) (1)
	CreateObject(7102,1328.8000500,1373.4000200,13.2000000,0.0000000,0.0000000,220.0000000); //object(plantbox12) (1)
	CreateObject(7102,1337.9000200,1308.9000200,13.2000000,0.0000000,0.0000000,65.9960000); //object(plantbox12) (2)
	CreateObject(7040,1348.5000000,1314.3000500,13.0000000,0.0000000,0.0000000,336.0000000); //object(vgnplcehldbox01) (1)
	CreateObject(7040,1314.3000500,1365.8000500,13.0000000,0.0000000,0.0000000,53.9990000); //object(vgnplcehldbox01) (2)
	CreateObject(7040,1352.1999500,1322.6999500,13.0000000,0.0000000,0.0000000,335.9950000); //object(vgnplcehldbox01) (3)
	CreateObject(7040,1355.3000500,1329.9000200,13.0000000,0.0000000,0.0000000,337.9950000); //object(vgnplcehldbox01) (4)
	CreateObject(7317,1277.0000000,1390.4000200,13.6000000,0.0000000,0.0000000,90.0000000); //object(plantbox17) (1)
	CreateObject(7102,1309.5999800,1281.6999500,13.2000000,0.0000000,1.0000000,91.2450000); //object(plantbox12) (3)
	CreateObject(10757,1293.0000000,1580.0999800,52.5000000,0.0000000,0.0000000,84.0000000); //object(airport_04_sfse) (1)
	CreateObject(14553,1476.0999800,1229.5999800,18.2000000,0.0000000,0.0000000,0.0000000); //object(androm_des_obj) (1)
	CreateObject(1309,1292.5000000,1636.0000000,31.5000000,0.0000000,0.0000000,335.9950000); //object(bigbillbrd) (1)
	CreateObject(1309,1290.8000500,1607.1999500,31.5000000,0.0000000,0.0000000,19.9950000); //object(bigbillbrd) (2)
	CreateObject(4735,1290.6999500,1606.3000500,40.3000000,0.0000000,0.0000000,200.0000000); //object(billbrdlan2_09) (1)
	CreateObject(4735,1292.1999500,1636.3000500,40.3000000,0.0000000,0.0000000,155.9950000); //object(billbrdlan2_09) (2)
	CreateObject(14553,1387.5000000,1561.5999800,20.7000000,29.9800000,357.6910000,1.1540000); //object(androm_des_obj) (2)
	CreateObject(4113,1338.0000000,1504.1992200,28.5000000,0.0000000,327.9970000,301.9980000); //object(lanofficeblok1) (1)
	CreateObject(4113,1285.5000000,1540.8994100,31.0000000,354.1280000,347.9320000,188.7450000); //object(lanofficeblok1) (2)
	CreateObject(9919,1463.6999500,1835.6999500,15.1000000,336.2420000,327.7330000,133.4790000); //object(grnwhite_sfe) (1)
	CreateObject(9958,1467.6999500,1744.0000000,1.8000000,40.2760000,294.4120000,350.9250000); //object(submarr_sfe) (2)
	CreateObject(3620,1322.3000500,1618.0999800,22.8000000,0.2500000,0.0000000,335.2500000); //object(redockrane_las) (1)
	CreateObject(3620,1364.5996100,1249.3994100,22.9000000,0.2470000,0.0000000,0.0000000); //object(redockrane_las) (2)
	CreateObject(10230,1363.5000000,1216.5000000,18.4000000,24.0000000,0.0000000,2.0000000); //object(freighter_sfe) (1)
	CreateObject(4602,1535.3000500,1423.9000200,31.3000000,22.0000000,0.0000000,0.0000000); //object(laskyscrap4_lan) (1)
	CreateObject(4602,1533.5999800,1349.3000500,31.3000000,21.9810000,2.1570000,178.9420000); //object(laskyscrap4_lan) (2)
	CreateObject(14553,1455.8000500,1385.8000500,68.8000000,20.0000000,0.0000000,90.0000000); //object(androm_des_obj) (3)
	CreateObject(8148,1553.3000500,1303.0000000,18.4000000,0.0000000,0.0000000,176.9950000); //object(vgsselecfence02) (3)
	CreateObject(8148,1553.3000500,1303.0000000,23.4000000,0.0000000,0.0000000,176.9950000); //object(vgsselecfence02) (3)
	CreateObject(8148,1553.3000500,1303.0000000,28.7000000,0.0000000,0.0000000,176.9950000); //object(vgsselecfence02) (3)
	CreateObject(8148,1553.2998000,1303.0000000,28.7000000,0.0000000,0.0000000,176.9950000); //object(vgsselecfence02) (3)
	CreateObject(8148,1557.8000500,1460.1999500,18.7000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (2)
	CreateObject(8148,1557.8000500,1460.1999500,23.7000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (2)
	CreateObject(8148,1557.8000500,1460.1999500,29.0000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (2)
	CreateObject(8148,1557.7998000,1460.1992200,29.0000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (2)
	CreateObject(8148,1557.8000500,1622.3000500,19.2000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1557.8000500,1622.3000500,25.0000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1557.8000500,1622.3000500,29.0000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1557.7998000,1622.2998000,29.0000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8150,1520.3000500,1203.0000000,18.5000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8150,1276.3000500,1803.4000200,19.3000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8150,1520.3000500,1203.0000000,27.0000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8150,1520.2998000,1203.0000000,27.0000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8148,1337.6999500,1883.6999500,19.2000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1557.8000500,1784.0999800,23.0000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1557.8000500,1784.0999800,26.8000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1557.8000500,1784.0999800,29.1000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1557.7998000,1784.0996100,29.1000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1477.0000000,1863.3000500,18.1000000,0.0000000,0.0000000,90.0000000); //object(vgsselecfence02) (1)
	CreateObject(8148,1477.0000000,1863.2998000,18.1000000,0.0000000,0.0000000,90.0000000); //object(vgsselecfence02) (1)
	CreateObject(8148,1477.0000000,1863.3000500,22.6000000,0.0000000,0.0000000,90.0000000); //object(vgsselecfence02) (1)
	CreateObject(8148,1477.0000000,1863.3000500,28.1000000,0.0000000,0.0000000,90.0000000); //object(vgsselecfence02) (1)
	CreateObject(8148,1477.0000000,1863.3000500,28.6000000,0.0000000,0.0000000,90.0000000); //object(vgsselecfence02) (1)
	CreateObject(8148,1417.5000000,1863.3000500,18.1000000,0.0000000,0.0000000,90.0000000); //object(vgsselecfence02) (1)
	CreateObject(8148,1417.5000000,1863.3000500,24.4000000,0.0000000,0.0000000,90.0000000); //object(vgsselecfence02) (1)
	CreateObject(8148,1417.5000000,1863.3000500,30.2000000,0.0000000,0.0000000,90.0000000); //object(vgsselecfence02) (1)
	CreateObject(8148,1337.6999500,1883.6999500,24.2000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1337.6999500,1883.6999500,30.0000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1313.3000500,1749.8000500,19.5000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8150,1276.2998000,1803.3994100,19.3000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8150,1276.3000500,1803.4000200,25.0000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8150,1276.3000500,1803.4000200,30.0000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8150,1250.4000200,1669.3000500,18.3000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8150,1250.4000200,1669.3000500,23.3000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8150,1250.4000200,1669.3000500,29.3000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8150,1250.4000200,1669.3000500,29.8000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8148,1313.3000500,1749.8000500,25.8000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1313.3000500,1749.8000500,30.1000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1257.6999500,1587.9000200,19.5000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1257.6999500,1587.9000200,26.0000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1257.6999500,1587.9000200,30.3000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1257.5000000,1429.8000500,19.5000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1257.5000000,1429.8000500,26.0000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1257.5000000,1429.8000500,30.3000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1257.9000200,1271.3000500,19.5000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1257.9000200,1271.3000500,13.0000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1257.9000200,1271.3000500,24.8000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1257.8994100,1271.2998000,24.8000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8148,1257.9000200,1271.3000500,30.3000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	CreateObject(8150,1520.3000500,1203.0000000,22.0000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8150,1396.5999800,1203.1999500,19.5000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8150,1396.5999800,1203.1999500,23.0000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8150,1396.5999800,1203.1999500,27.0000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8150,1318.4000200,1203.0999800,27.0000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8150,1318.4000200,1203.0999800,20.8000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8150,1318.4000200,1203.0999800,15.3000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8150,1318.4000200,1203.0999800,11.3000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(8150,1318.3994100,1203.0996100,11.3000000,0.0000000,0.0000000,0.0000000); //object(vgsselecfence04) (1)
	CreateObject(987,1286.3000500,1210.1999500,16.8000000,80.0000000,0.0000000,0.0000000); //object(elecfence_bar) (1)
	CreateObject(987,1286.4000200,1207.1999500,17.3000000,79.9970000,0.0000000,0.0000000); //object(elecfence_bar) (2)
	CreateObject(987,1277.0999800,1208.3000500,17.3000000,79.9970000,0.0000000,0.0000000); //object(elecfence_bar) (3)
	CreateObject(987,1268.0999800,1208.1999500,17.3000000,79.9970000,0.0000000,0.0000000); //object(elecfence_bar) (4)
	CreateObject(987,1258.9000200,1207.9000200,17.3000000,79.9970000,0.0000000,2.0000000); //object(elecfence_bar) (5)
	CreateObject(987,1256.0999800,1207.9000200,17.3000000,79.9910000,0.0000000,2.0000000); //object(elecfence_bar) (6)
	CreateObject(987,1255.8000500,1210.5999800,17.3000000,79.9910000,0.0000000,2.0000000); //object(elecfence_bar) (7)
	CreateObject(987,1265.0000000,1210.5999800,17.3000000,79.9910000,0.0000000,2.0000000); //object(elecfence_bar) (8)
	CreateObject(987,1271.0000000,1210.5999800,17.3000000,79.9910000,0.0000000,2.0000000); //object(elecfence_bar) (9)
	CreateObject(987,1277.0000000,1210.5999800,17.3000000,79.9910000,0.0000000,2.0000000); //object(elecfence_bar) (10)
	CreateObject(8148,1557.8000500,1784.0999800,17.5000000,0.0000000,0.0000000,179.9950000); //object(vgsselecfence02) (1)
	repair1 = CreatePickup(3096, 14, 1426.2197, 1463.4635, 10.5474, -1); //Repair 1
	repair2 = CreatePickup(3096, 14, 1440.3478, 1462.8029, 10.5474, -1); //Repair 2
	GMSTARTERROR = 0;
	print("    	   ___");
	print("	  (o o)");
	print("+--o00-----(_)-----------+");
	GangZoneCreate2(1559.9268, 1865.2538, 1254.3372, 1200.3475);
	if(dini_Exists("DD/info.txt") && dini_Exists("DD/modt.txt") && dini_Exists("DD/rules.txt") && dini_Exists("DD/log.txt"))
	{
	    print("Soubory modu: OK");
	}
	if(!dini_Exists("DD/info.txt"))
	{
	    print("Soubory modu: ERROR [1]");
	    print("- Opravuji");
	    dini_Create("DD/info.txt");
	    new File:info = fopen("DD/info.txt", io_append);
	    if(info)
	    {
	        fwrite(info, "Server info\r\n");
	        fclose(info);
	    }
	    GMSTARTERROR ++;

	}
	if(!dini_Exists("DD/modt.txt"))
	{
	    print("Soubory modu: ERROR [2]");
	    print("- Opravuji");
	    dini_Create("DD/modt.txt");
	    new File:modt = fopen("DD/modt.txt", io_append);
	    if(modt)
	    {
	        fwrite(modt, "--------------------------------------\r\nDestruction Derby v1.0\r\n--------------------------------------\r\n");
	        fclose(modt);
	    }
	    GMSTARTERROR ++;
	}
	if(!dini_Exists("DD/rules.txt"))
	{
	    print("Soubory modu: ERROR [3]");
	    print("- Opravuji");
	    dini_Create("DD/rules.txt");
	    new File:rules = fopen("DD/rules.txt", io_append);
	    if(rules)
	    {
	        fwrite(rules, "1. Pravidlo\r\n");
	        fwrite(rules, "2. Pravidlo\r\n");
	        fwrite(rules, "3. Pravidlo\r\n");
	        fwrite(rules, "4. Pravidlo\r\n");
	        fwrite(rules, "5. Pravidlo\r\n");
	        fclose(rules);
	    }
	    GMSTARTERROR ++;
	}
	if(!dini_Exists("DD/log.txt"))
	{
	    print("Soubory modu: ERROR [4]");
	    print("- Opravuji");
	    dini_Create("DD/log.txt");
	    GMSTARTERROR ++;
     	GMSTARTERROR = 4;
	}
	if(!dini_Exists("DD/User/test.txt"))
	{
	    dini_Create("DD/User/test.txt");
	    new File:user = fopen("DD/User/test.txt", io_append);
	    if(user)
	    {
			fwrite(user, "heslo=84S8F84SDG88A [Heslo v HASHy]\r\n");
	        fwrite(user, "money=0 [Pocet penez]\r\n");
            fwrite(user, "ip=127.0.0.1 [IP Adresa]\r\n");
	        fclose(user);
	    }
	}
	if(!dini_Exists("DD/Ban/test.txt"))
	{
	    dini_Create("DD/Ban/test.txt");
	    new File:ban = fopen("DD/Ban/test.txt", io_append);
	    if(ban)
	    {
			fwrite(ban, "kdy=16.11 2013 [Kdy byl zabanovan]\r\n");
	        fwrite(ban, "kdo=test [Kdo byl zabanovan]\r\n");
            fwrite(ban, "ip=127.0.0.1 [IP zabanovaneho]\r\n");
            fwrite(ban, "admin=test [Ban daroval]\r\n");
            fwrite(ban, "duvod=test [Duvod banu]\r\n");
	        fclose(ban);
	    }
	}
	if(!dini_Exists("DD/Admin/test.txt"))
	{
	    dini_Create("DD/Admin/test.txt");
	    new File:admin = fopen("DD/Admin/test.txt", io_append);
	    if(admin)
	    {
			fwrite(admin, "heslo=84S8F84SDG88A [Heslo v HASHy]\r\n");
	        fwrite(admin, "nick=test [Nick Admina]\r\n");
            fwrite(admin, "ip=127.0.0.1 [IP Admina]\r\n");
            fwrite(admin, "admin=5 [Admin Level]\r\n");
	        fclose(admin);
	    }
	}
	if(!dini_Exists("DD/VIP-CODES/test.txt"))
	{
	    dini_Create("DD/VIP-CODES/dd_11aa11b.txt");
	    new File:vipc = fopen("DD/VIP-CODES/dd_11aa11b.txt", io_append);
	    if(vipc)
	    {
	        fwrite(vipc, "nick=test [nick = test - Pouze pro hrace test / nick = ddallviplvl1domm - pro vsechny]\r\n");
            fwrite(vipc, "vip=1 [VIP Level]\r\n");
	        fclose(vipc);
	    }
	}
	if(!dini_Exists("DD/VIP/test.txt"))
	{
	    dini_Create("DD/VIP/test.txt");
	    new File:vip = fopen("DD/VIP/test.txt", io_append);
	    if(vip)
	    {
			fwrite(vip, "heslo=84S8F84SDG88A [Heslo v HASHy]\r\n");
	        fwrite(vip, "nick=test [Nick VIP]\r\n");
            fwrite(vip, "ip=127.0.0.1 [IP VIP]\r\n");
	        fclose(vip);
	    }
	}
	if(GMSTARTERROR == 4)
	{
        SetTimer("FIRST",500, true);
	}
	print("+----------------o00-----+");
	print("	|_||_|");
	print("	 || ||");
	print(" 	oo0 0oo");
	return 1;
}

public OnGameModeExit()
{
	if(GMSTARTERROR == 4)
	{
	    SendToLog("Pripravuji mod k prvnimu spusteni!");
	    print("\r\n");
	}
	else
	{
    	SendToLog("Server byl vypnut!");
    	print("\r\n");
    	SRC("exit");
	}
	return 1;
}


main()
{
    new string[500];
    new File:modt = fopen("DD/modt.txt", io_read);
    while(fread(modt,string)) print(string);
    fclose(modt);
    SendToLog("Mod uspesne spusten!");
    if(GMSTARTERROR == 4)
    {
        print("\r\n");
 		SendToLog("Probehl restart serveru! [Duvod: Bezpecnost]");
 		SendToLog("Mod vytvari dulezite soubory!");
		print("\r\n");
    }
}

public OnPlayerConnect(playerid)
{
	RocketFiring[playerid] = 0;
	IsInInfernus[playerid] = 0;
	Infernus[playerid] = 0;
	CarJumping[playerid] =0;
	new str5[120];
	new Country[256];
 	GetPlayerCountry(playerid,Country);
	format(str5, 120, "Hrac %s [IP: %s] se pripojil na server! [%s]", Jmeno(playerid), GetPlayerIP(playerid),Country);
	SCMTAF(0xFFFFFFFF,"{949494}[ {66FF66}Server {949494}] Hráè {66FF66}%s {949494}[{66FF66}%d{949494}] se pøipojil na server! [{66FF66}%s{949494}]!",Jmeno(playerid),playerid,Country);
	SendToLog(str5);
	GangZoneShowForPlayer(playerid, Zone[1][id], 0xFF0000CA);
	SetTimerEx("Kontrola",1000,true,"i",playerid);
	SCMF(playerid, 0xFFFFFFFF,"{949494}[ {66FF66}Server {949494}] Vítej na serveru {66FF66}%s{949494}!",Jmeno(playerid));
	new string[1000];
 	new File:rules = fopen("DD/rules.txt", io_read);
    while(fread(rules,string))
	ShowPlayerDialog(playerid, 1, DIALOG_STYLE_MSGBOX, "{FF0000}P{ffffff}ravidla", string,"Souhlasím","Nesouhlasím");
 	fclose(rules);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	RocketFiring[playerid] = 0;
	IsInInfernus[playerid] = 0;
	Infernus[playerid] = 0;
	CarJumping[playerid] =0;
	DestroyVehicle(Infernus[playerid]);
	new str5[120];
	switch(reason)
	{
		case 0:
		{
		    format(str5, 120, "Hrac %s [IP: %s] odešel ze serveru - Pad Hry!", Jmeno(playerid), GetPlayerIP(playerid));
			SCMTAF(0xFFFFFFFF,"{949494}[ {66FF66}Server {949494}] Hráè {66FF66}%s {949494}[{66FF66}%d{949494}] odešel ze hry [{66FF66}Pád hry{949494}]!",Jmeno(playerid),playerid);
		}
		case 1:
		{
		    format(str5, 120, "Hrac %s [IP: %s] odešel ze serveru!", Jmeno(playerid), GetPlayerIP(playerid));
			SCMTAF(0xFFFFFFFF,"{949494}[ {66FF66}Server {949494}] Hráè {66FF66}%s {949494}[{66FF66}%d{949494}] odešel ze hry!",Jmeno(playerid),playerid);
		}
		case 2:
		{
		    format(str5, 120, "Hrac %s [IP: %s] byl vyhozen ze serveru!", Jmeno(playerid), GetPlayerIP(playerid));
	 		SCMTAF(0xFFFFFFFF,"{949494}[ {66FF66}Server {949494}] Hráè {66FF66}%s {949494}[{66FF66}%d{949494}] byl vyhozen ze serveru [{66FF66}Kick{949494}/{66FF66}Ban{949494}]!",Jmeno(playerid),playerid);
		}
	}
	SendToLog(str5);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    SendDeathMessage(killerid, playerid, reason);
    DestroyVehicle(Infernus[playerid]);
    Infernus[playerid] = 0;
	RocketFiring[playerid] = 0;
	IsInInfernus[playerid] = 0;
	CarJumping[playerid] =0;
	return 1;
}

public OnPlayerSpawn(playerid)
{
	new Random = random(sizeof(Spawns));
	SetPlayerPos(playerid, Spawns[Random][0], Spawns[Random][1], Spawns[Random][2]);
    Infernus[playerid] = CreateVehicle(411, Spawns[Random][0], Spawns[Random][1], Spawns[Random][2], Spawns[Random][3], -1, -1,-1);
	PutPlayerInVehicle(playerid, Infernus[playerid], 0);
    IsInInfernus[playerid] = 1;
    CarJumping[playerid] =0;
    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	SetPlayerCameraPos(playerid, 1495.1479,1461.8633,30.5474);
	SetPlayerCameraLookAt(playerid, 1365.4211,1641.9021,10.5474);
	SetPlayerPos(playerid, 1495.1479,1461.8633,10.5474);
	return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	dcmd(reset, 5, cmdtext);
    return 0;
}

dcmd_reset(playerid, params[])
{
	#pragma unused params
    for(new h=0;h<MAX_PLAYERS+1;h++)
    {
        IsInInfernus[h] = 0;
        RocketFiring[h] = 0;
        CarJumping[h] =0;
        DestroyObject(Rocket[h]);
    }
    SCM(playerid, 0xFFFFFFFF, "Reset promnìných probìhl úspìšnì!");
	return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid)
{
    if(GetVehicleModel(vehicleid) == 411)
    {
            IsInInfernus[playerid] = 1;
            RocketFiring[playerid] = 0;
    }
    return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
    if(GetVehicleModel(vehicleid) == 411)
    {
            IsInInfernus[playerid] = 0;
            RocketFiring[playerid] = 0;
            SetPlayerHealth(playerid, 0);
    }
    return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if (newkeys & KEY_FIRE)
    {
        if(RocketFiring[playerid] == 0)
        {
                        if(IsInInfernus[playerid] == 1)
                        {
                                new Float:X, Float:Y, Float:Z, Float:Angle, Float:X2, Float:Y2, vehicleid;
                                vehicleid = GetPlayerVehicleID(playerid);
                                GetPlayerPos(playerid, X, Y, Z);
                                GetVehicleZAngle(vehicleid, Angle);
                                DestroyObject(Rocket[playerid]);
                                Rocket[playerid] = CreateObject(3790, X+2, Y, Z+2, 0, 0, Angle+270);
                                GetXYInFrontOfPlayer(playerid, X2, Y2, 100.0);
                                MoveObject(Rocket[playerid], X2, Y2, Z, 100.0);
                                RocketFiring[playerid] = 1;
                                SetTimerEx("Boom",1000,0,"i",playerid);
                        }
		}
		return 1;
    }
    if (newkeys & KEY_CROUCH)
    {
		if(CarJumping[playerid] == 0)
		{
			if(IsInInfernus[playerid] == 1)
			{
	  			new Float:X, Float:Y, Float:Z;
	  		 	GetVehicleVelocity(GetPlayerVehicleID(playerid), X, Y, Z);
	       		SetVehicleVelocity(GetPlayerVehicleID(playerid), X, Y, Z+0.3);
	       		CarJumping[playerid] = 1;
	         	SetTimerEx("Jump",1000,0,"i",playerid);
	      	}
      	}
	}
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
    if(pickupid == repair1)
    {
    	RepairVehicle(GetPlayerVehicleID(playerid));
    	SetVehicleHealth(GetPlayerVehicleID(playerid), 1000.0);
    	DestroyPickup(repair1);
    	SetTimer("p_repair1",5000,false);
    }
    else if(pickupid == repair2)
    {
    	RepairVehicle(GetPlayerVehicleID(playerid));
    	SetVehicleHealth(GetPlayerVehicleID(playerid), 1000.0);
		DestroyPickup(repair2);
		SetTimer("p_repair2",5000,false);
    }
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{

    return 0; 
}

GetParams(Source[]){
        new Destination[256];
        new SLen=strlen(Source);
        new at;
		new pos=0;
		new tp=0;
        new tempo[256];
        format(Params[0],sizeof(Params),"");
        format(Params[1],sizeof(Params),"");
        format(Params[2],sizeof(Params),"");
        format(Params[3],sizeof(Params),"");

        /////////////////////////////////////////////

        for(at=pos;at<=SLen;at++){
                strmid(tempo,Source,at,at+1,sizeof(tempo));
                if(!strcmp(tempo,".",true)){
                        if(tp<=10){
                                strmid(Destination,Source,pos,at,sizeof(Destination));
                                format(Params[tp][0],256,"%s",Destination);
                                tp=tp+1;
                        }
                        pos=at+1;
                }
        }
        return 1;
}


GetFileData(Source[]){
        new Destination[256];
        new SLen=strlen(Source);
        new at,pos=0,tp=0;
        new tempo[256];

        ////////////// Clearing DATA /////////////////    FOR LOOP WAS NOT WORKING FOR THIS PURPOSE
        format(FileData[0],sizeof(FileData),"");
        format(FileData[1],sizeof(FileData),"");
        format(FileData[2],sizeof(FileData),"");
        format(FileData[3],sizeof(FileData),"");
        format(FileData[4],sizeof(FileData),"");
        format(FileData[5],sizeof(FileData),"");
        format(FileData[6],sizeof(FileData),"");
        /////////////////////////////////////////////

        for(at=pos;at<=SLen;at++){
                strmid(tempo,Source,at,at+1,sizeof(tempo));
                if(!strcmp(tempo,",",true)){
                        if(tp<=10){
                                strmid(Destination,Source,pos,at,sizeof(Destination));
                                format(FileData[tp][0],256,"%s",Destination);
                                tp=tp+1;
                        }
                        pos=at+1;
                }
        }
        return 1;
}

GetPlayerCountry(playerid,Country[256]){
        new IPAddress[256];
        new a,b,c,d,ipf;
        new File:IPFile;
        new Text[256],start,end;
        GetPlayerIp(playerid,IPAddress,sizeof(IPAddress));
        GetParams(IPAddress);
        a=strval(Params[0]);
        b=strval(Params[1]);
        c=strval(Params[2]);
        d=strval(Params[3]);
        if(a==127 && b==0 && c==0 && d==1){
                format(Country,sizeof(Country),"Localhost");
                return 1;
        }
        ipf = (16777216*a) + (65536*b) + (256*c) + d;
        if(!fexist("DD/IPLIST.csv")) SendToLog("Nenalezen soubor s IP!");
        IPFile=fopen("DD/IPLIST.csv",io_read);
        fread(IPFile,Text,sizeof(Text),false);
        while(strlen(Text)>0){
            GetFileData(Text);
            start=strval(FileData[0]);
            end=strval(FileData[1]);
            if(ipf>=start && ipf<=end){
                        format(Country,sizeof(Country),"%s| %s",FileData[6],FileData[5]);
                        fclose(IPFile);
                        return 1;
            }
            fread(IPFile,Text,sizeof(Text),false);
        }
        fclose(IPFile);
        return 1;
}

