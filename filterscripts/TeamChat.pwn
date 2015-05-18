#include <a_samp>

#define ForPlayers(%0) for(new %0; %0 <= MAX_PLAYERS;%0++) if(IsPlayerConnected(%0))
#define SCM SendClientMessage

new TEAM[MAX_PLAYERS];

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" Blank Filterscript by your name here");
	print("--------------------------------------\n");
	return 1;
}

public OnPlayerText(playerid, text[])
{
	new str[128];
	if(text[0] == '!')
	{
 		ForPlayers(i)
 		{
   			if(TEAM[i] == TEAM[playerid])
			{
				format(str, sizeof(str), "{751975}[ {751975}TeamChat {751975}] {751975}%s: {751975}%s",PlayerName(playerid), text[1]);
	  			SCM(i,0xFFFFAAAA, str);
			}
		}
  		return 0;
	}
	return 1;
}

stock PlayerName(playerid)
{
	new str[MAX_PLAYER_NAME];
	GetPlayerName(playerid,str,sizeof(str));
	return str;
}
