
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
char str_aux[100], atrib_aux[100];
extern Stack * Symbol_Table;


%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO
%token INTEIRO BOOLEANO NUMERO 
%token MAIS MENOS MULTIPLICACAO DIVISAO 
%token IF THEN ELSE
%token MENOR MAIOR IGUAL DIFERENTE AND OR NOT
%token MENOR_IGUAL MAIOR_IGUAL
%token TRUE FALSE

%%

programa:
    {generate_code(-1, "INPP");}
    PROGRAM IDENT
    ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
    bloco PONTO
    {generate_code(-1, "PARA");}
;


bloco:
    {nivel_lexico += 1;}
    var
    comando_composto
    {
        nivel_lexico -= 1;
        sprintf(str_aux, "DMEM %i", num_vars_declaradas);

        print_tabela_simbolos();
        
        generate_code(-1, str_aux);
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
        generate_code(-1, str_aux);
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
        update_types(Token);
    }
    PONTO_E_VIRGULA
;
/////////////


tipo:
    INTEIRO | BOOLEANO
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
    atribuicao |
    comando_condicional
;

atribuicao:
    variavel {strcpy(atrib_aux, Token);} ATRIBUICAO expressao
    {
        // armazenar valor da expressao que foi calculada
        Entry * en = get_entry(atrib_aux);

        if (!en) {
            trigger_error("unknown variable");
        }

        if (en->category == cate_vs) {
            VariavelSimples * vs = en->element;

            if (vs->type != $4) {
                trigger_error("type mismatch");
            }

            sprintf(str_aux, "ARMZ %d, %d", en->addr.nl, en->addr.offset);
        
            generate_code(-1, str_aux);
        }
        else if (en->category == cate_pf) {
            // do something
        }
    }
;

comando_condicional:
    IF ABRE_PARENTESES expressao FECHA_PARENTESES
        {
            int rot = create_label();
    
            sprintf(str_aux, "DSVF R%d", rot);
            generate_code(-1, str_aux);
        }
    THEN T_BEGIN comandos T_END
        {
            int rot1 = create_label();
            sprintf(str_aux, "DSVS R%d", rot1);
            generate_code(-1, str_aux);

            Stack* rot2 = get_top_label();
            int * value = (int*) rot2->prev->v;
            generate_code(*value, "NADA");
        }
    ELSE T_BEGIN comandos T_END
        {
            if ($3 != tipo_booleano) {
                trigger_error("invalid type for if");
            }

            Stack* rot = get_top_label();
            int* value = (int*) rot->v;
            generate_code(*value, "NADA");

            destroy_labels(2);
        } |
        
    IF ABRE_PARENTESES expressao FECHA_PARENTESES
        {
            int rot = create_label();
            
            sprintf(str_aux, "DSVF R%d", rot);
            generate_code(-1, str_aux);
        } 
    THEN T_BEGIN comandos T_END
        {
            if ($3 != tipo_booleano)
                trigger_error("invalid type for if");

            Stack * rot = get_top_label();
            int * value = (int*) rot->v;
            generate_code(*value, "NADA");

            destroy_labels(2);
        }
;

expressao: 
    expressao relacao expressao_simples |
    expressao_simples {$$ = $1;}
;

relacao: 
;

expressao_simples:
    fator operador expressao_simples
        {
            if ($1 != $3)
                trigger_error("type mismatch");

            if ($1 == tipo_inteiro && !check_valid_int_operation($2))
                trigger_error("invalid operation for int");

            if($1 == tipo_booleano && !check_valid_bool_operation($2))
                trigger_error("invalid operation for bool");

            $$ = resolve_operation_return($1, $3, $2);
            print_operation_code($2);
        } |
    MAIS fator 
        {
            if ($2 != tipo_inteiro)
                trigger_error("invalid operation");

            $$ = tipo_inteiro;
        } |
    MENOS fator 
        {
            if ($2 != tipo_inteiro)
                trigger_error("invalid operation");

            $$ = tipo_inteiro;
            generate_code(-1, "INVR");
        } |
    NOT fator 
        {
            if ($2 != tipo_booleano)
                trigger_error("invalid operation");

            $$ = tipo_booleano;
            generate_code(-1, "NEGA");
        } |
    fator {$$ = $1;}
;

operador:
    MAIS {$$ = 1;}           |
    MENOS {$$ = 2;}          |
    MULTIPLICACAO {$$ = 3;}  |
    DIVISAO {$$ = 4;}        |
    IGUAL {$$ = 5;}          |
    DIFERENTE {$$ = 6;}      |
    MENOR {$$ = 7;}          |
    MAIOR {$$ = 8;}          |
    MENOR_IGUAL {$$ = 9;}    |
    MAIOR_IGUAL {$$ = 10;}   |
    AND {$$ = 11;}           |
    OR {$$ = 13;}            
;

fator:
    variavel
        {
            // procurar o simbolo na tabela e empilhar o valor
            Entry * en = get_entry(Token);

            if (!en)
                trigger_error("unknown variable");

            if (en->category == cate_vs) {
                VariavelSimples * vs = en->element;

                $$ = vs->type;
                sprintf(str_aux, "CRVL %d, %d", en->addr.nl, en->addr.offset);
            
                generate_code(-1, str_aux);
            }
            else if (en->category == cate_pf) {
                // do something
            }
            else if (en->category == cate_proc) {
                // do nothing (yet)
            }
        } |
    NUMERO 
        {
            $$ = tipo_inteiro;
            sprintf(str_aux, "CRCT %s", Token);
            generate_code(-1, str_aux);
        } |
    TRUE 
        {
            $$ = tipo_booleano;
            sprintf(str_aux, "CRCT 1");
            generate_code(-1, str_aux);
        } |
    FALSE 
        {
            $$ = tipo_booleano;
            sprintf(str_aux, "CRCT 0");
            generate_code(-1, str_aux);
        } |
    ABRE_PARENTESES expressao FECHA_PARENTESES
;


variavel:
    IDENT
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

    destroy(&Symbol_Table, entry_destroy);

    return 0;
}
