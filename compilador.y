
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
%token INTEIRO BOOLEANO

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

///////////// DECLARACAO DE VARIAVEIS
var         :   { num_vars = 0; offset = 0;}
                VAR declara_vars
                {
                    sprintf(str_aux, "AMEM %i", num_vars);
                    
                    geraCodigo (NULL, str_aux);
                }
;

declara_vars: declara_vars declara_var | declara_var;

declara_var :   {}
                lista_id_var DOIS_PONTOS
                tipo
                {
                    
                    // ir ate a tabela de simbolos e atualizar o tipo delas
                    update_types(token);
                }
                PONTO_E_VIRGULA
;
/////////////



//

tipo        : INTEIRO | BOOLEANO
;

lista_id_var:   lista_id_var VIRGULA IDENT
                { 
                    push_symbol(cate_vs);
                    
                    num_vars += 1;
                    offset += 1;
                }
                | IDENT
                {
                    push_symbol(cate_vs);

                    num_vars += 1;
                    offset += 1;
                }
;

lista_idents:
    lista_idents VIRGULA IDENT |
    IDENT
;

comando_composto: T_BEGIN comandos T_END

comandos: ;


atribuicao: variavel ATRIBUICAO expressao
;

variavel:
;

expressao: 
    expressao relacao expressao_simples |
    expressao_simples;
;

relacao: 
;

expressao_simples:
    // expressao_simples [+ - or] termo |
    // [+ - or] termo
;

termo:
;




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
