
// Testar se funciona corretamente o empilhamento de parï¿½metros
// passados por valor ou por referï¿½ncia.


%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#include "compilador.h"
#include "stack.h"

int num_vars_declaradas, nivel_lexico = -1, offset;
char str_aux[100];
extern Stack * Tabela_Simbolos;
extern Stack * Pilha_Tipos;


%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO
%token INTEIRO NUMERO
%token MAIS MENOS MULTIPLICACAO DIVISAO 

%%

programa:
    {geraCodigo (NULL, "INPP");}
    PROGRAM IDENT
    ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
    bloco PONTO
    {
        geraCodigo (NULL, "PARA");
        destroy(&Tabela_Simbolos, entry_destroy);
    }
;


bloco:
    {nivel_lexico += 1;}
    var
    comando_composto
    {
        nivel_lexico -= 1;
        sprintf(str_aux, "DMEM %i", num_vars_declaradas);
        
        geraCodigo (NULL, str_aux);
    }
;


///////////// DECLARACAO DE VARIAVEIS
var:   
    { 
        num_vars_declaradas = 0;
        offset = 0;
    }
    VAR declara_vars
    {
        sprintf(str_aux, "AMEM %i", num_vars_declaradas);
        geraCodigo (NULL, str_aux);
    }
;


declara_vars:
    declara_vars declara_var |
    declara_var
;


declara_var:
    lista_id_var DOIS_PONTOS
    tipo
    {
        // ir ate a tabela de simbolos e atualizar o tipo das variaveis recem alocadas
        update_types(token);
    }
    PONTO_E_VIRGULA
;
/////////////


tipo:
    INTEIRO
;

lista_id_var:   
    lista_id_var VIRGULA IDENT
    { 
        push_symbol(cate_vs);
        
        num_vars_declaradas += 1;
        offset += 1;
    } |
    IDENT
    {
        push_symbol(cate_vs);

        num_vars_declaradas += 1;
        offset += 1;
    }
;

lista_idents:
    lista_idents VIRGULA IDENT |
    IDENT
;

comando_composto: 
    T_BEGIN comandos T_END
;

comandos:
    comando PONTO_E_VIRGULA comandos |
    comando PONTO_E_VIRGULA
;

comando: 
    atribuicao
;

atribuicao:
    variavel ATRIBUICAO expressao
    {
        // armazenar valor da expressao que foi calculado
    }
;

expressao: 
    expressao relacao expressao_simples |
    expressao_simples;
;

relacao: 
;

expressao_simples:
    fator MAIS expressao_simples
        {
            if ($1 != $3) {
                trigger_error("type mismatch");
            }

            geraCodigo(NULL, "SOMA");
        } |
    fator MENOS expressao_simples
        {   
            if ($1 != $3) {
                trigger_error("type mismatch");
            }
            geraCodigo(NULL, "SUBT");
        } |
    fator MULTIPLICACAO expressao_simples
        {
            if ($1 != $3) {
                trigger_error("type mismatch");
            }
            geraCodigo(NULL, "MULT");
        } |
    fator DIVISAO expressao_simples
        {
            if ($1 != $3) {
                trigger_error("type mismatch");
            }
            geraCodigo(NULL, "DIVI");
        } |
    MAIS fator { /* carrega */} |
    MENOS fator 
        {
            if ($2 != tipo_inteiro) {
                trigger_error("invalid operation");
            }
            geraCodigo(NULL, "CRCT -1");
            geraCodigo(NULL, "MULT");
        } |
    fator { /* carrega */}
;

fator:
    variavel
        {
            // procurar o simbolo na tabela e empilhar o valor
            Entry * en = get_entry(token);

            if (!en) {
                trigger_error("invalid identifier");
            }

            if (en->category == cate_vs) {
                VariavelSimples * vs = en->element;

                $$ = vs->type;
                sprintf(str_aux, "CRVL %d, %d", vs->address.nl, vs->address.offset);
            
                geraCodigo(NULL, str_aux);
            }
            else if (en->category == cate_pf) {
                // do nothing
            }
            else if (en->category == cate_proc) {
                // do nothing
            }
        } |
    NUMERO 
        {
            $$ = tipo_inteiro;
            sprintf(str_aux, "CRCT %s", token);
            
            geraCodigo(NULL, str_aux);
        } |
    ABRE_PARENTESES expressao FECHA_PARENTESES
;

chamada_funcao:
;

variavel: IDENT
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

    yyin=fp;
    yyparse();

    return 0;
}
