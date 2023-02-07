
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
int trigger = 1, trigger2 = 1;
Stack * DMEM_Stack = NULL;


int param_index = -1;
Procedimento * curr_proc = NULL;

%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO
%token INTEIRO BOOLEANO NUMERO 
%token MAIS MENOS MULTIPLICACAO DIVISAO 
%token IF THEN ELSE WHILE DO
%token MENOR MAIOR IGUAL DIFERENTE AND OR NOT
%token MENOR_IGUAL MAIOR_IGUAL
%token TRUE FALSE
%token PROCEDURE

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

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
    parte_declara_vars
    parte_declara_subrotinas
    {
        if (trigger) {
            trigger = 0;
            generate_code(0, "NADA");
        }
    }
    comando_composto
    {
        sprintf(str_aux, "DMEM %i", *((int*) pop(&DMEM_Stack)));

        destroy_block_entries(nivel_lexico);

        nivel_lexico -= 1;
        generate_code(-1, str_aux);
    }
;

tipo:
    INTEIRO | BOOLEANO
;

///////////// DECLARACAO DE VARIAVEIS
parte_declara_vars:   
    parte_declara_vars declara_vars
    |
    {
        num_vars_declaradas = 0;
        offset = 0;
    }
    VAR declara_vars
    {
        sprintf(str_aux, "AMEM %i", num_vars_declaradas);
        generate_code(-1, str_aux);

    	int * n = malloc(sizeof(int));
        must_alloc(n, "parte_declara_vars");
        *n = num_vars_declaradas;

        push(&DMEM_Stack, n);
    } |
;

declara_vars:
    lista_id_var DOIS_PONTOS tipo
    {
        // ir ate a tabela de simbolos e atualizar o tipo das variaveis recem alocadas
        update_types(cate_vs, 0, Token);
    }
    PONTO_E_VIRGULA
;
/////////////

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

parte_declara_subrotinas:
    parte_declara_subrotinas declara_proced PONTO_E_VIRGULA {trigger = 1;} |
;

declara_proced:
    PROCEDURE IDENT
        {
            trigger = 0;
            if (trigger2) {
                trigger2 = 0;
                generate_code(-1, "DSVS R0");
            }

            sprintf(str_aux, "ENPR %d", nivel_lexico + 1);

            int rot = create_label();
            generate_code(rot, str_aux);

            push_symbol(cate_proc);
        }
    declara_proc_complemento
;

declara_proc_complemento:
    param_formais PONTO_E_VIRGULA bloco 
        {
            Procedimento * p = get_top_procedure();
            if (!p)
                trigger_error("no procedure on top");

            sprintf(str_aux, "RTPR %d, %d", nivel_lexico + 1, p->n_params);

            generate_code(-1, str_aux);
        } |
    PONTO_E_VIRGULA bloco
        {
            sprintf(str_aux, "RTPR %d, %d", nivel_lexico + 1, 0);

            generate_code(-1, str_aux);
        }
;


param_formais: 
    ABRE_PARENTESES parte_param_formais FECHA_PARENTESES
    {
        update_proc_params();
    }
;

parte_param_formais:
    parte_param_formais PONTO_E_VIRGULA sec_param_formais |
    sec_param_formais |
;

sec_param_formais:
    VAR lista_ident_params DOIS_PONTOS tipo
        {
            update_types(cate_pf, 1, Token);
        } |
    lista_ident_params DOIS_PONTOS tipo
        {
            update_types(cate_pf, 0, Token);
        }
;

lista_ident_params :
    lista_ident_params VIRGULA IDENT
        {
            Procedimento * p = get_top_procedure();
            if (!p)
                trigger_error("no procedure");

            p->n_params += 1;

            push_symbol(cate_pf);
        } |
    IDENT
        {
            Procedimento * p = get_top_procedure();
            if (!p)
                trigger_error("no procedure");

            p->n_params += 1;

            push_symbol(cate_pf);
        }
;


//! ISTO ESTA ERRADO ? -> ou transformamos o interno em outra regra msm?
comando_composto: 
    T_BEGIN lista_comando T_END
;

lista_comando:
    comando PONTO_E_VIRGULA lista_comando |
    comando
;

comando: 
    linha_comando |
    comando_composto |
    comando_condicional |
    comando_repetitivo
;

linha_comando:
    IDENT {strcpy(atrib_aux, Token);} complemento_linha 
;

complemento_linha:
    ATRIBUICAO expressao
        {
            // armazenar valor da expressao que foi calculada
            Entry * en = get_entry(atrib_aux);

            if (!en) {
                trigger_error("unknown variable");
            }

            if (en->category == cate_vs) {
                VariavelSimples * vs = en->element;

                if (vs->type != $2) {
                    trigger_error("type mismatch");
                }

                sprintf(str_aux, "ARMZ %d, %d", en->addr.nl, en->addr.offset);
            
                generate_code(-1, str_aux);
            }
            else if (en->category == cate_pf) {
                // do something
                ParametroFormal * pf = (ParametroFormal *) en->element;

                if (pf->type != $2) {
                    trigger_error("type mismatch");
                }

                // mudar esse baraio
                sprintf(str_aux, "ARMZ %d, %d", en->addr.nl, en->addr.offset);
            
                generate_code(-1, str_aux);
            }
            else {
                trigger_error("you can only assign values to variables");
            }
        } |
    // chamada de procedimentos com parametros
        {
            Entry * en = get_entry(atrib_aux);
            
            if (!en)
                trigger_error("unknown procedure");

            curr_proc = (Procedimento *) en->element;

            param_index = 0;

            sprintf(str_aux, "CHPR R%d, %d", curr_proc->n_rotulo, nivel_lexico);
            generate_code(-1, str_aux);
        }
    ABRE_PARENTESES lista_express_proc FECHA_PARENTESES
        {
            //
            curr_proc = NULL;
        } |
        // chamada de procedimento sem parametros
        {
            Entry * en = get_entry(atrib_aux);
            
            if (!en)
                trigger_error("unknown procedure");

            Procedimento * proc = (Procedimento *) en->element;

            sprintf(str_aux, "CHPR R%d, %d", proc->n_rotulo, nivel_lexico);
            generate_code(-1, str_aux);
        }
;


lista_express_proc:
    lista_express_proc VIRGULA expressao {param_index++;} |
    expressao {param_index++;} |
;


comando_condicional: 
    if_then cond_else
;

if_then: 
    IF expressao 
    {
        if ($2 != tipo_booleano)
            trigger_error("invalid expression on if evaluation");

        int rot = create_label();

        sprintf(str_aux, "DSVF R%d", rot);
        generate_code(-1, str_aux);
    }
    THEN comando
;

cond_else:
    ELSE 
        {
            int rot1 = create_label();
            sprintf(str_aux, "DSVS R%d", rot1);
            generate_code(-1, str_aux);

            Stack * rot = get_top_label();
            int * value = (int*) rot->prev->v;
            generate_code(*value, "NADA");
        }
    comando
        {
            Stack * rot = get_top_label();
            int * value = (int*) rot->v;
            generate_code(*value, "NADA");

            destroy_labels(2);
        } | 
    %prec LOWER_THAN_ELSE
        {
            Stack * rot = get_top_label();
            int * value = (int*) rot->v;
            generate_code(*value, "NADA");

            destroy_labels(1);
        }
;

comando_repetitivo:
    WHILE
        {
            generate_code(create_label(), "NADA");
        }
    expressao
        {
            int rot = create_label();
            sprintf(str_aux, "DSVF R%d", rot);
            generate_code(-1, str_aux);
        }
    DO
    comando
        {
            Stack * rot1 = get_top_label();
            Stack * rot2 = rot1->prev;

            sprintf(str_aux, "DSVS R%d", *((int*)rot2->v));
            generate_code(-1, str_aux);

            generate_code(*((int*) rot1->v), "NADA");

            destroy_labels(2);
        }
;


expressao:
    expressao_simples relacao expressao_simples
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
    expressao_simples {$$ = $1;}
;

relacao:
    IGUAL           {$$ = 5;}  |
    DIFERENTE       {$$ = 6;}  |
    MENOR           {$$ = 7;}  |
    MAIOR           {$$ = 8;}  |
    MENOR_IGUAL     {$$ = 9;}  |
    MAIOR_IGUAL     {$$ = 10;}       
;

expressao_simples:
    expressao_simples OR termo 
        {
            if ($1 != $3)
                trigger_error("type mismatch");

            if ($1 != tipo_booleano || $3 != tipo_booleano)
                trigger_error("invalid operation");

            $$ = tipo_booleano;
            generate_code(-1, "DISJ");
        } |
    expressao_simples MENOS termo
        {
            if ($1 != $3)
                trigger_error("type mismatch");

            if ($1 != tipo_inteiro || $3 != tipo_inteiro)
                trigger_error("invalid operation");

            $$ = tipo_inteiro;
            generate_code(-1, "SUBT");
        }|
    expressao_simples MAIS termo
        {
            if ($1 != $3)
                trigger_error("type mismatch");

            if ($1 != tipo_inteiro || $3 != tipo_inteiro)
                trigger_error("invalid operation");

            $$ = tipo_inteiro;
            generate_code(-1, "SOMA");
        }  |
    MAIS termo
        {
            if ($2 != tipo_inteiro)
                trigger_error("invalid operation");

            $$ = tipo_inteiro;
        } |
    MENOS termo
        {
            if ($2 != tipo_inteiro)
                trigger_error("invalid operation");

            $$ = tipo_inteiro;
            generate_code(-1, "INVR");
        } |
    termo {$$ = $1;}
;

termo:
    termo MULTIPLICACAO fator
        {
            if ($1 != $3)
                trigger_error("type mismatch");

            if ($1 != tipo_inteiro || $3 != tipo_inteiro)
                trigger_error("invalid operation");

            $$ = tipo_inteiro;
            generate_code(-1, "MULT");
        } |
    termo DIVISAO fator 
        {
            if ($1 != $3)
                trigger_error("type mismatch");

            if ($1 != tipo_inteiro || $3 != tipo_inteiro)
                trigger_error("invalid operation");

            $$ = tipo_inteiro;
            generate_code(-1, "DIVI");
        } |
    termo AND fator
        {
            if ($1 != $3)
                trigger_error("type mismatch");

            if ($1 != tipo_booleano || $3 != tipo_booleano)
                trigger_error("invalid operation");

            $$ = tipo_booleano;
            generate_code(-1, "CONJ");
        } |
    fator {$$ = $1;}
;

fator:
    IDENT
        {
            // procurar o simbolo na tabela e empilhar o valor
            Entry * en = get_entry(Token);

            if (!en)
                trigger_error("unknown variable");

            if (curr_proc) {                
                if (en->category == cate_vs) {
                    VariavelSimples * vs = (VariavelSimples*) en->element;

                    if (vs->type != curr_proc->params[param_index].type)
                        trigger_error("invalid param given to procedure");

                    $$ = vs->type;
                    const char * to_write = generate_mepa_param(en, &(curr_proc->params[param_index]));
                    sprintf(str_aux, "%s %d, %d", to_write, en->addr.nl, en->addr.offset);
                
                    generate_code(-1, str_aux);
                }
                else if (en->category == cate_pf) {
                    
                    // ISSO AQUI AINDA TEM QUE MUDAR
                    ParametroFormal * pf = (ParametroFormal*) en->element;

                    if (pf->type != curr_proc->params[param_index].type)
                        trigger_error("invalid param given to procedure");

                    $$ = pf->type;

                    const char * to_write = generate_mepa_param(en, &(curr_proc->params[param_index]));
                    sprintf(str_aux, "%s %d, %d", to_write, en->addr.nl, en->addr.offset);
                
                    generate_code(-1, str_aux);
                }
            }
            else {
                if (en->category == cate_vs) {
                    VariavelSimples * vs = (VariavelSimples*) en->element;

                    $$ = vs->type;
                    sprintf(str_aux, "CRVL %d, %d", en->addr.nl, en->addr.offset);
                
                    generate_code(-1, str_aux);
                }
                else if (en->category == cate_pf) {
                    // ISSO AQUI AINDA TEM QUE MUDAR
                    ParametroFormal * pf = (ParametroFormal*) en->element;

                    $$ = pf->type;

                    if (pf->ref)
                        sprintf(str_aux, "CRVI %d, %d", en->addr.nl, en->addr.offset);
                    else
                        sprintf(str_aux, "CRVL %d, %d", en->addr.nl, en->addr.offset);
                
                    generate_code(-1, str_aux);
                }
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
    ABRE_PARENTESES expressao FECHA_PARENTESES {$$ = $2;} |
    NOT fator 
        {
            if ($2 != tipo_booleano)
                trigger_error("invalid operation");

            $$ = tipo_booleano;
            generate_code(-1, "NEGA");
        }
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
