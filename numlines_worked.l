%{
/* need this for the call to atof() below */
#include <math.h>
#include <stdio.h>
#include <ctype.h>

int num_lines = 0, num_chars = 0;

int yylex(void);
int yyerror(char *s);

%}


%%

[ \t]+ 			/* eat up whitespace */

\n	    		++num_lines; ++num_chars;

.     			++num_chars;
					
%%

int yywrap(void){return 1;}

void main( argc, argv ) 
int argc; 
char **argv; 
{ 
  ++argv, --argc; /* skip over program name */ 
  if ( argc > 0 ) 
    yyin = fopen( argv[0], "r" ); 
  else 
    yyin = stdin; 
  yylex();
  printf("The Number Of Lines is %d", num_lines); printf("\nThe number of Characters is %d\n", num_chars-1); num_lines = 0; num_chars =0;
} 
