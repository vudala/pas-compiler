
// Testar se funciona corretamente o empilhamento de parï¿½metros
// passados por valor ou por referï¿½ncia.


%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#include "compilador.h"
#include "stack.h"

int num_vars, nivel_lexico = -1, offset;
char str_aux[100];
extern Stack * Tabela_Simbolos;

%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO
%token INTEIRO

%%

programa    :   {geraCodigo (NULL, "INPP");}
                PROGRAM IDENT
                ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
                bloco PONTO
                {
                    geraCodigo (NULL, "PARA");
                    destroy(&Tabela_Simbolos, entry_destroy);
                }
;

bloco       : {nivel_lexico += 1;}
              var
              comando_composto
              {nivel_lexico -= 1;}
;


var         : { } VAR declara_vars;

declara_vars: declara_vars declara_var | declara_var;

declara_var :   { num_vars = 0; offset = 0;}
                lista_id_var DOIS_PONTOS
                tipo
                {
                    sprintf(str_aux, "AMEM %i", num_vars);
                    geraCodigo (NULL, str_aux);
                    // ir ate a tabela de simbolos e atualizar o tipo delas
                }
                PONTO_E_VIRGULA
;

tipo        : INTEIRO
;

lista_id_var:   lista_id_var VIRGULA IDENT
                { 
                    push_symbol(nivel_lexico, offset);
                    
                    num_vars += 1;
                    offset += 1;
                }
                | IDENT
                {
                    push_symbol(nivel_lexico, offset);

                    num_vars += 1;
                    offset += 1;
                }
;

lista_idents: lista_idents VIRGULA IDENT
            | IDENT
;

comando_composto: T_BEGIN comandos T_END

comandos: ;


%%

int main (int argc, char** argv) {
   FILE* fp;
   extern FILE* yyin;

   if (argc<2 || argc>2) {
         printf("usage compilador <arq>a %d\n", argc);
         return(-1);
      }

   fp=fopen (argv[1], "r");
   if (fp == NULL) {
      printf("usage compilador <arq>b\n");
      return(-1);
   }


/* -------------------------------------------------------------------
 *  Inicia a Tabela de Símbolos
 * ------------------------------------------------------------------- */

   yyin=fp;
   yyparse();

   return 0;
}
