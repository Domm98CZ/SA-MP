#include <a_samp>

#pragma tabsize 0

#define MAX_ENTRY 500
#define MAX_LEN 500

static CENZURA[MAX_ENTRY][MAX_LEN];

#define CENSOREDFILE "cenzura.ini"

public OnFilterScriptInit()
{
	if(!fexist(CENSOREDFILE))
	{
	fcreate(CENSOREDFILE);
	}
	if(fexist(CENSOREDFILE))
	{
		new File:myFile,
			line[MAX_LEN],
			index=0;

		myFile=fopen(CENSOREDFILE,filemode:io_read);

		while(fread(myFile,line,sizeof line) && (index != MAX_ENTRY))
		{
			if(strlen(line)>MAX_LEN) continue;
			StripNewLine(line);
			strmid(CENZURA[index],line,0,strlen(line),sizeof line);
			index++;
		}
	}
	return 1;
}

public OnPlayerText(playerid, text[])
{
	for(new i=0; i<MAX_ENTRY; i++)
	{
		if(!CENZURA[i][0]) continue;
		CENUROVAT(text,CENZURA[i]);
	}
	return 1;
}

stock CENUROVAT(string[],word[],destch='*')
{
	new start_index=(-1),
	    end_index=(-1);

	start_index=strfind(string,word,true);
	if(start_index==(-1)) return false;
	end_index=(start_index+strlen(word));

	for( ; start_index<end_index; start_index++)
		string[start_index]=destch;

	return true;
}

stock StripNewLine(string[])
{
	new len = strlen(string);
	if (string[0]==0) return ;
	if ((string[len - 1] == '\n') || (string[len - 1] == '\r')) {
		string[len - 1] = 0;
		if (string[0]==0) return ;
		if ((string[len - 2] == '\n') || (string[len - 2] == '\r')) string[len - 2] = 0;
	}
}

stock fcreate(file[])
{
	if(fexist(file)) return false;
	new File:cFile = fopen(file,io_write);
	return fclose(cFile);
}
