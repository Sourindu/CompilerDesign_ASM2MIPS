/* Scanner for assembler to MIF file converter */ 

%{
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <errno.h>
#include <stdlib.h>
#include <time.h>
#include <ctype.h>
#define DEBUG 0
int state=0; /* end of line prints out IW */
int   icount =0; /* number of instructions */
int   vcount =0, printcount =0; /* number of variables */
int   pp =1; /** preprocessor flag **/
int   vvflag = 0; /** variable flag for second run**/
int varflag = 0; /** variable flag for first run **/
int valflag = 0;
int magcount = 0;
int ccflag = 0;
int iflag = 0;
int hexflag = 0;
int loop = 0;
char buf[256];
char  opis[6],lblis[4],immis[24], varname[20][10], temp[10], temphex[1];
struct inst {int adr; int imm; char *txt; char *opc;} iw;
struct init  {char *name; char *code;} op_table[20] =
{
"ADD"    , "00",
"SUBT"   , "05",
"AND"    , "08",
"OR"     , "07",
"STORE"  , "01",
"ADDI"   , "0B",
"SUBI"   , "0C",
"XOR"    , "06",
"JUMP"	 , "03",
"JNEG"   , "04",
"JPOS"   , "09",
"JZERO"  , "0A",
"LOAD"   , "02",
"0"      , "0"
};
FILE      *fid;
int add_symbol(int value, char *symbol);
int lookup_symbol(char *symbol);
void list_symbols();
void conv2hex(int value, int Width);
char* addi2hex(int value, int Width);
char* lookup_opc(char *opc);

%}
DIGIT           "-"?[0-9]+ 
VAR             [a-zA-Z][a-z0-9_]*
COLON           [ \t]*":"[ \t]*
LABEL           [Ll][0-9]+[:]
COMMENT         "--"*
HEX 			("0x"|"0X")[ABCDEF0-9]{1,4}

%%

[\r\n]+|"\r\n"+	{if (pp) printf( "\n");
					else{ if ((state==2) && (pp==0)) /* print out an instruction at end of line */
							{if(iflag){iflag = 0;if(hexflag){hexflag = 0;conv2hex(iw.adr,8);printf("  : %s%s",iw.opc,temp);fprintf(fid,"  : %s%s",iw.opc,temp);
								printf(";  -- %s  %s\n",opis,immis);fprintf(fid,";  -- %s  %s\n",opis,immis);}
								else{conv2hex(iw.adr,8);printf("  : %s%s",iw.opc,addi2hex(iw.imm,8));fprintf(fid,"  : %s%s",iw.opc,addi2hex(iw.imm,8));
								printf(";  -- %s  %s\n",opis,immis);fprintf(fid,";  -- %s  %s\n",opis,immis);}}
							
							else { conv2hex(iw.adr,8);printf("  : %s",iw.opc);fprintf(fid,"  : %s",iw.opc); conv2hex(iw.imm,8);
								printf(";  -- %s  %s\n",opis,immis);fprintf(fid,";  -- %s  %s\n",opis,immis);
							}}
							state=0;iw.imm=0;
					}}
					

{COMMENT}			{printf("\nFound Comment");}/*Buffer the Comment*/

(?i:variable)		{if (pp) {printf("\nThe Variable "); varflag = 1;}}

{VAR}				{ if (pp) {if(varflag){varflag = 0;valflag = 1; strcpy(varname[magcount++], yytext); printf(" %s",yytext);} 
								else{ printf(" %s", yytext); add_symbol(vcount+30, yytext);}}
						else {if(vvflag){vvflag = 0;state=2;iw.imm=lookup_symbol(yytext);strcpy(immis,yytext);}
								else if(ccflag){ccflag = 0;state=2;strcpy(immis,yytext);iw.imm=lookup_symbol(strcat(strcpy(temp,yytext),":"));}}
					}
					

{HEX}				{if (pp){if(valflag){valflag =0; printf( " := %s (Hexadecimal Value)\n",yytext); 
									strncpy(varname[magcount++],yytext+2,4);}}
								else{if(iflag == 1){hexflag = 1;state =2;strcat(strcpy(immis, yytext)," (Hexadecimal Value)");strncpy(strcpy(temp,""),yytext+2,3);}}
					}
					

{DIGIT} 			{ if (pp){if(valflag){valflag =0; printf( " := %s (Decimal Value)\n",yytext); strcpy(varname[magcount++],addi2hex(atoi(yytext),16));}}
								else { if(iflag == 1){state =2;strcat(strcpy(immis, yytext)," (Deciaml Value)"); iw.imm = atoi(yytext);}}
					}
					
ADDI|SUBI			  { 
						if (pp){printf( "%d) Instruction : %s",printcount++, yytext );} 
						else { state=1;iw.adr=icount++;iw.opc=lookup_opc(yytext); iflag = 1;}
					}

STORE|ADD|LOAD|XOR|OR|SUBT {
 
						if (pp){printf( "%d) Instruction : %s",printcount++, yytext );} 
						else { state=1;iw.adr=icount++;iw.opc=lookup_opc(yytext); vvflag = 1;}
					}

JUMP|JPOS|JZERO|JNEG  { 
						if (pp){printf( "%d) Instruction : %s",printcount++, yytext );} 
						else { state=1;iw.adr=icount++;iw.opc=lookup_opc(yytext); ccflag = 1;}
					}
					

{LABEL}         	{ if (pp) {printf( "A label: %s lenth=%d Icount=%d\n", yytext , yyleng, printcount);
					add_symbol(printcount, yytext);}
					}
				
{COLON}				/*do nothing*/

[" "\t]+			{/* eat up whitespace printf("\nSpace Found");*/}

.     				{printf("\nUnknown Charecter : %s", yytext);}


				
%%
int yywrap(void) { return 1; };

void main( argc, argv ) 
int argc; 
char **argv; 
{
	
  ++argv, --argc; /* skip over program name */ 
  if ( argc > 0 ) 
    yyin = fopen( argv[0], "r" ); 
  else 
    yyin = stdin;

  fid = fopen("Scompout.txt", "w+");
	
  printf("\n--This Program Converts SCOMP Microprocessor Assembly File to Machine Instruction File *.MIF--\n");
  printf("\n--Developed By : Sourindu Chatterjee--");
  printf("\n--Organisation : Florida State University--");
  printf("\n--Reference From T-RISC Program by Dr. Uwe Meyer-Baese--");
  fprintf(fid,"\n--This Program Converts SCOMP Microprocessor Assembly File to Machine Instruction File *.MIF--\n");
  fprintf(fid,"\n--Developed By : Sourindu Chatterjee--");
  fprintf(fid,"\n--Organisation : Florida State University--");
  fprintf(fid,"\n--Reference From T-RISC Program by Dr. Uwe Meyer-Baese--");
		
  yylex();
  printf("\nSuccessfull First Parsing");
  if (yyin != NULL) fclose(yyin);
  
  pp=0;
  
  printf("\nDEPTH = 256;                    %% Memory depth and width are required      %%");
  printf("\nWIDTH = 16;                     %% Enter a decimal number                   %%");
  printf("\nADDRESS_RADIX = HEX;            %% Address and value radixes are optional   %%");
  printf("\nDATA_RADIX = HEX;               %% Enter BIN, DEC, HEX, or OCT; unless      %%");
  printf("\n                                %% otherwise specified, radixes = HEX       %%");
  printf("\n       -- Specify values for addresses, which can be single address or range");
  printf("\nCONTENT");
  printf("\n  BEGIN");
  printf("\n");
  printf("\n[00..FF] : 0000;   %% Range--Every address from 00 to FF = 0000 (Default) %%\n");
  fprintf(fid,"\nDEPTH = 256;                    %% Memory depth and width are required      %%");
  fprintf(fid,"\nWIDTH = 16;                     %% Enter a decimal number                   %%");
  fprintf(fid,"\nADDRESS_RADIX = HEX;            %% Address and value radixes are optional   %%");
  fprintf(fid,"\nDATA_RADIX = HEX;               %% Enter BIN, DEC, HEX, or OCT; unless      %%");
  fprintf(fid,"\n                                %% otherwise specified, radixes = HEX       %%");
  fprintf(fid,"\n       -- Specify values for addresses, which can be single address or range");
  fprintf(fid,"\nCONTENT");
  fprintf(fid,"\n  BEGIN");
  fprintf(fid,"\n");
  fprintf(fid,"\n[00..FF] : 0000;   %% Range--Every address from 00 to FF = 0000 (Default) %%\n");
  
  yyin = fopen( argv[0], "r" ); 
  yylex();
  if ((state==2) && (pp==0)) /* print out an instruction at end of line */
	{conv2hex(iw.adr,8);printf("  : %s",iw.opc);fprintf(fid,"  : %s",iw.opc); conv2hex(iw.imm,8);
		printf(";  -- %s  %s\n",opis,immis);fprintf(fid,";  -- %s  %s\n",opis,immis);
	}
	state=0;iw.imm=0;
	
  printf("-------------------------------------------------------------------\n");
  fprintf(fid,"-------------------------------------------------------------------\n");
  conv2hex(icount,8);printf("  : %s","03");fprintf(fid,"  : %s","03"); conv2hex(icount,8);printf(";  -- %s  %s","JUMP","Infinitely");fprintf(fid,";  -- %s  %s","JUMP","Infinitely");
  printf("\n-------------------------------------------------------------------\n");
  fprintf(fid,"\n-------------------------------------------------------------------\n");
  
  for(loop = 0; loop < magcount-1; loop =loop+2)
  {
	conv2hex(lookup_symbol(varname[loop]),8);printf("  : %s",varname[loop+1]);fprintf(fid,"  : %s",varname[loop+1]);
	printf(";  -- Data value of %s - %s\n",varname[loop],varname[loop+1]);
	fprintf(fid,";  -- Data value of %s - %s\n",varname[loop],varname[loop+1]);
  }
    
  printf("\nSuccessfull Second Parsing\n");
  if (yyin != NULL) fclose(yyin);
  if (fid != NULL) fclose(fid);
} 

/* define a linked list of symbols */
struct symbol {
	char *symbol_name;
	int symbol_value;
	struct symbol *next;
};

struct symbol *symbol_list; /* first element in symbol list */



extern void *malloc();

int add_symbol(int value, char *symbol)
{
	struct symbol *wp;	

	if(lookup_symbol(symbol) >= 0 ) {
		printf("--- Warning: symbol %s already defined \n", symbol);
		return 0;
	}
	wp = (struct symbol *) malloc(sizeof(struct symbol));
	wp->next = symbol_list;
	wp->symbol_name = (char *) malloc(strlen(symbol)+1);
	strcpy(wp->symbol_name, symbol);
        if (symbol[0]!='L') vcount++;
	wp->symbol_value = value;
	symbol_list = wp;
	return 1;	/* it worked */
}

int lookup_symbol(char *symbol)
{     int found = -1;
	struct symbol *wp = symbol_list;
	for(; wp; wp = wp->next) {
		if(strcmp(wp->symbol_name, symbol) == 0)
        {if (DEBUG) printf("-- Found symbol %s value is: %d\n",symbol, wp->symbol_value);
			return wp->symbol_value;}
	}
        if (DEBUG) printf("-- Symbol %s not found!!\n",symbol);
	return -1;	/* not found */
}

char* lookup_opc(char *opc)
{
   int k;
    strcpy(opis,opc);
    for (k=0;op_table[k].name !=0;k++)
     if (strcmp(opc,op_table[k].name)==0) return (op_table[k].code);

printf("******* Ups, no opcode : %s --> exit \n",opc);exit(1);
}

void list_symbols()
{
	struct symbol *wp = symbol_list;
      printf("--- Print the Symbol list: ---\n");
	for(; wp; wp = wp->next) 
      if (wp->symbol_name[0]=='L') {
	printf("-- Label    : %s  line = %d\n",wp->symbol_name, wp->symbol_value);
      } else {
	printf("-- Variable : %s  memory @ %d\n",wp->symbol_name, wp->symbol_value);
	}

}

/************* CONV_STD_LOGIC_VECTOR(value, bits) ***********/
void conv2hex(int value, int Width)
{

	int             k, t;
	int             W;
	extern FILE    *fid;

	t = value;
	for (k = Width - 4; k >= 0; k-=4) {
		W = (t >> k) % 16;
		if(pp == 0)
		{fprintf(fid, "%1x", W);}
		printf( "%1x", W);
	}
}

/*This Is Conversion To Hex With Signed Magnitude For Addi*/
char* addi2hex(int value, int Width)
{

	int             k, t;
	int             W;
	extern FILE    *fid;
	strcpy(temp,"");
	t = value;
	if(t < 0)
	{
		if(t > -127)
		{
		
			t = t & 0xFF;
			for (k = Width - 4; k >= 0; k-=4) {
				W = (t >> k) % 16;
				sprintf(temphex,"%1X", W);
				strcat(temp,temphex);
			}
		}
		return temp;
		
	}
	else if(t >= 0 && t <= 32767)
	{
		for (k = Width - 4; k >= 0; k-=4) {
			W = (t >> k) % 16;
			sprintf(temphex,"%1X", W);
			strcat(temp,temphex);
		}
		return temp;
	}
	else
	{
		return "FFFFFFFF";
	}
	
}
