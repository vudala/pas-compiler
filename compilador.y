%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#include "compilador.h"
#include "stack.h"

int num_vars_declaradas, nivel_lexico = 0, offset;
int write_trigger = 0, read_trigger = 0;
char str_aux[100], ident_aux[100], atrib_aux[100];
extern Stack * Symbol_Table;
Stack * DMEM_Stack = NULL;
Stack * SUBR_Stack = NULL;
Stack * PARAM_Stack = NULL;

char * curr_subr_ident = NULL;
Subrotina * curr_subr = NULL;

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
%token PROCEDURE FUNCTION

%nonassoc LOWER_THAN_ELSE
%nonassoc TOK
%nonassoc ELSE

%%

programa:
    {generate_code(-1, "INPP");}
    PROGRAM IDENT
    main_params PONTO_E_VIRGULA
    bloco
    PONTO
    {generate_code(-1, "PARA");}
;

main_params:
    ABRE_PARENTESES lista_idents FECHA_PARENTESES |
;

lista_idents:
    lista_idents VIRGULA IDENT |
    IDENT
;


bloco:
    parte_declara_vars
    parte_declara_subrotinas
    comando_composto
    {
        destroy_block_entries(nivel_lexico);

        if (size(DMEM_Stack) == nivel_lexico + 1) {
            int * n = (int*) pop(&DMEM_Stack);
            sprintf(str_aux, "DMEM %i", *n);
            generate_code(-1, str_aux);
            free(n);
        }
    }
;

///////////// DECLARACAO DE VARIAVEIS
parte_declara_vars:   
    {
        num_vars_declaradas = 0;
        offset = 0;
    }
    VAR declara_vars
    {
        if (num_vars_declaradas > 0) {
            sprintf(str_aux, "AMEM %i", num_vars_declaradas);
            generate_code(-1, str_aux);

            int * n = malloc(sizeof(int));
            must_alloc(n, "parte_declara_vars");
            *n = num_vars_declaradas;

            push(&DMEM_Stack, n);
        }
    } |
;

declara_vars:
    declara_vars lista_id_var DOIS_PONTOS tipo
    {
        // ir ate a tabela de simbolos e atualizar o tipo das variaveis recem alocadas
        update_types(cate_vs, 0, $4);
    }
    PONTO_E_VIRGULA |
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

parte_declara_subrotinas:
    parte_declara_subrotinas
    {
        sprintf(str_aux, "DSVS R%.2d", create_label());
        generate_code(-1, str_aux);
    }
    declara_proced
    {   
        int * rot = (int*) get_top_label()->v;
        generate_code(*rot, "NADA");

        destroy_labels(1);
        nivel_lexico -= 1;
    }
    PONTO_E_VIRGULA |
    parte_declara_subrotinas
    {
        sprintf(str_aux, "DSVS R%.2d", create_label());
        generate_code(-1, str_aux);
    }
    declara_func
    {   
        int * rot = (int*) get_top_label()->v;
        generate_code(*rot, "NADA");

        destroy_labels(1);
        nivel_lexico -= 1;
    }
    PONTO_E_VIRGULA |
;

declara_proced:
    PROCEDURE IDENT
        {
            sprintf(str_aux, "ENPR %d", nivel_lexico + 1);

            generate_code(create_label(), str_aux);

            push_symbol(cate_subr);

            nivel_lexico += 1;
        }
    param_formais PONTO_E_VIRGULA
    bloco
    {
        Entry * en = get_top_procedure();
        if (!en)
            trigger_error("no procedure on top");

        rtpr_subroutine((Subrotina *) en->element);

        destroy_labels(1);
    }
;

declara_func:
    FUNCTION IDENT
    {
        sprintf(str_aux, "ENPR %d", nivel_lexico + 1);

        generate_code(create_label(), str_aux);

        push_symbol(cate_subr);

        nivel_lexico += 1;

        // salva o nome do procedimento que está sendo declarado para checar atribuicao de retorno
        curr_subr_ident = malloc(strlen(Token));
        must_alloc(curr_subr_ident, "declara func");

        strcpy(curr_subr_ident, Token);
    }
    param_formais DOIS_PONTOS
    tipo
    {
        // atualizar o tipo de retorno da funcao recem declarada
        Entry * en = get_top_subroutine();
        if (!en)
            trigger_error("no function on top");

        Subrotina * subr = (Subrotina *) en->element;

        subr->has_ret = 1;
        subr->ret_type = $6;
    } 
    PONTO_E_VIRGULA
    bloco
    {
        Entry * en = get_top_function();
        if (!en)
            trigger_error("no function on top");

        rtpr_subroutine((Subrotina *) en->element);

        destroy_labels(1);

        free(curr_subr_ident);
        curr_subr_ident = NULL;
    }
;

param_formais: 
    ABRE_PARENTESES parte_param_formais FECHA_PARENTESES
    {update_subr_params();} |
;

parte_param_formais:
    parte_param_formais PONTO_E_VIRGULA sec_param_formais |
    sec_param_formais |
;

sec_param_formais:
    VAR lista_ident_params DOIS_PONTOS tipo
        {
            update_types(cate_pf, 1, $4);
        } |
    lista_ident_params DOIS_PONTOS tipo
        {
            update_types(cate_pf, 0, $3);
        }
;

lista_ident_params :
    lista_ident_params VIRGULA IDENT
        {
            Entry * en = get_top_subroutine();
            if (!en)
                trigger_error("no subroutine to update");

            Subrotina * subr = (Subrotina *) en->element;

            subr->n_params += 1;

            push_symbol(cate_pf);
        } |
    IDENT
        {
            Entry * en = get_top_subroutine();
            
            if (!en)
                trigger_error("no subroutine to update");

            Subrotina * subr = (Subrotina *) en->element;

            subr->n_params += 1;

            push_symbol(cate_pf);
        }
;

tipo:
    INTEIRO {$$ = tipo_inteiro;} | BOOLEANO {$$ = tipo_booleano;}
;

comando_composto: 
    T_BEGIN lista_comando T_END
;

lista_comando:
    comando PONTO_E_VIRGULA lista_comando |
    comando PONTO_E_VIRGULA |
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
    // atribuicao
    ATRIBUICAO expressao
    {
        // armazenar valor da expressao que foi calculada
        Entry * en = get_entry(atrib_aux);

        if (!en)
            trigger_error("unknown symbol");

        if (en->category == cate_vs) {
            VariavelSimples * vs = en->element;

            if (vs->type != $2)
                trigger_error("type mismatch");

            sprintf(str_aux, "ARMZ %d,%d", en->addr.nl, en->addr.offset);
        
            generate_code(-1, str_aux);
        }
        else if (en->category == cate_pf) {
            ParametroFormal * pf = (ParametroFormal *) en->element;

            if (pf->type != $2)
                trigger_error("type mismatch");

            if (pf->ref)
                sprintf(str_aux, "ARMI %d,%d", en->addr.nl, en->addr.offset);
            else
                sprintf(str_aux, "ARMZ %d,%d", en->addr.nl, en->addr.offset);
        
            generate_code(-1, str_aux);
        }
        else if (en->category == cate_subr) {
            Subrotina * subr = en->element;
            if (subr->has_ret && !strcmp(atrib_aux, curr_subr_ident)) {
                sprintf(str_aux, "ARMZ %d,%d", nivel_lexico, -4 - subr->n_params);
                generate_code(-1, str_aux);
            }
            else {
                trigger_error("you can only assign values to variables");                
            }
        }
        else {
            trigger_error("you can only assign values to variables");
        }
    } |
    // chamada de procedimentos com parametros
    {
        if (strcmp("write", atrib_aux) == 0) {
            write_trigger = 1;
        }
        else if (strcmp("read", atrib_aux) == 0) {
            read_trigger = 1;
        }
        else {
            Entry * en = get_procedure(atrib_aux);
        
            if (!en)
                trigger_error("unknown procedure");

            curr_subr = (Subrotina *) en->element;
            push(&SUBR_Stack, curr_subr);

            int * par = malloc(sizeof(int));
            must_alloc(par, "chamada func");
            *par = 0;
            push(&PARAM_Stack, par);
        }
    }
    ABRE_PARENTESES lista_express_subr FECHA_PARENTESES
    {
        if (write_trigger || read_trigger) {
            write_trigger = 0;
            read_trigger = 0;
        }
        else {
            int param_index = *((int*) PARAM_Stack->v);
            if (param_index > curr_subr->n_params)
                trigger_error("too many arguments");    

            if (param_index < curr_subr->n_params)
                trigger_error("too few arguments");
            
            chpr_subroutine(curr_subr);

            pop(&SUBR_Stack);
            if (SUBR_Stack)
                curr_subr = SUBR_Stack->v;
            else
                curr_subr = NULL;

            pop(&PARAM_Stack);
        }
    } |
    // chamada de procedimento sem parametros
    {
        Entry * en = get_procedure(atrib_aux);
        
        if (!en)
            trigger_error("unknown procedure");

        Subrotina * proc = (Subrotina *) en->element;

        chpr_subroutine(proc);
    }
;


lista_express_subr:
    lista_express_subr VIRGULA
    {
        if (read_trigger)
            generate_code(-1, "LEIT");

        if (curr_subr) {
            int * par_ind = (int*) PARAM_Stack->v;
        
            if (*par_ind + 1 > curr_subr->n_params)
                trigger_error("too many arguments");
        }
    }
    expressao
    {
        if (write_trigger)
            generate_code(-1, "IMPR");
        else {
            int * par_ind = (int*) PARAM_Stack->v;
            (*par_ind)++;
        }
    } |
    {
        if (read_trigger)
            generate_code(-1, "LEIT");
        
        if (curr_subr) {
            int * par_ind = (int*) PARAM_Stack->v;
        
            if (*par_ind + 1 > curr_subr->n_params)
                trigger_error("too many arguments");
        }
    }
    expressao
    {
        if (write_trigger)
            generate_code(-1, "IMPR");
        else {
            int * par_ind = (int*) PARAM_Stack->v;
            (*par_ind)++;
        }
    } |
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

        sprintf(str_aux, "DSVF R%.2d", rot);
        generate_code(-1, str_aux);
    }
    THEN comando
;

cond_else:
    ELSE 
        {
            int rot1 = create_label();
            sprintf(str_aux, "DSVS R%.2d", rot1);
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
            sprintf(str_aux, "DSVF R%.2d", rot);
            generate_code(-1, str_aux);
        }
    DO
    comando
        {
            Stack * rot1 = get_top_label();
            Stack * rot2 = rot1->prev;

            sprintf(str_aux, "DSVS R%.2d", *((int*)rot2->v));
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
        } |
    expressao_simples MAIS termo
        {
            if ($1 != $3)
                trigger_error("type mismatch");

            if ($1 != tipo_inteiro || $3 != tipo_inteiro)
                trigger_error("invalid operation");

            $$ = tipo_inteiro;
            generate_code(-1, "SOMA");
        } |
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
    IDENT {strcpy(ident_aux, Token);} ident_complemento {$$ = $3;} |
    NUMERO 
        {
            if (curr_subr) {
                int param_index = *((int*) PARAM_Stack->v);

                if (tipo_inteiro != curr_subr->params[param_index].type)
                    trigger_error("invalid arg type");

                if (curr_subr->params[param_index].ref)
                    trigger_error("const cant be passed by reference");
            }

            if (read_trigger)
                trigger_error("invalid param for read");

            $$ = tipo_inteiro;
            sprintf(str_aux, "CRCT %s", Token);
            generate_code(-1, str_aux);
        } |
    TRUE 
        {
            if (curr_subr) {
                int param_index = *((int*) PARAM_Stack->v);
                
                if (tipo_booleano != curr_subr->params[param_index].type)
                    trigger_error("invalid arg type");

                if (curr_subr->params[param_index].ref)
                    trigger_error("const cant be passed by reference");
            }

            if (read_trigger)
                trigger_error("invalid param for read");

            $$ = tipo_booleano;
            sprintf(str_aux, "CRCT 1");
            generate_code(-1, str_aux);
        } |
    FALSE 
        {
            if (curr_subr) {
                int param_index = *((int*) PARAM_Stack->v);

                if (tipo_booleano != curr_subr->params[param_index].type)
                    trigger_error("invalid arg type");

                if (curr_subr->params[param_index].ref)
                    trigger_error("const cant be passed by reference");
            }

            if (read_trigger)
                trigger_error("invalid param for read");

            $$ = tipo_booleano;
            sprintf(str_aux, "CRCT 0");
            generate_code(-1, str_aux);
        } |
    ABRE_PARENTESES expressao FECHA_PARENTESES
        {
            if (curr_subr) {
                int param_index = *((int*) PARAM_Stack->v);

                if ($2 != curr_subr->params[param_index].type)
                    trigger_error("invalid arg type");

                if (curr_subr->params[param_index].ref)
                    trigger_error("const cant be passed by reference");
            }

            if (read_trigger)
                    trigger_error("invalid param for read");

            $$ = $2;
        } |
    NOT fator 
        {
            if ($2 != tipo_booleano)
                trigger_error("invalid operation");

            if (curr_subr) {
                int param_index = *((int*) PARAM_Stack->v);

                if (tipo_booleano != curr_subr->params[param_index].type)
                    trigger_error("invalid arg type");

                if (curr_subr->params[param_index].ref)
                    trigger_error("const cant be passed by reference");
            }

            if (read_trigger)
                trigger_error("invalid param for read");

            $$ = tipo_booleano;
            generate_code(-1, "NEGA");
        }
;


ident_complemento:
    chamada_func {$$ = $1;} | variavel {$$ = $1;}
;


variavel:
    {
        // procurar o simbolo na tabela e empilhar o valor
        Entry * en = get_entry(ident_aux);

        if (!en)
            trigger_error("unknown variable");

        if (curr_subr) {
            int param_index = *((int*) PARAM_Stack->v);

            if (en->category == cate_vs) {
                VariavelSimples * vs = (VariavelSimples*) en->element;

                if (vs->type != curr_subr->params[param_index].type)
                    trigger_error("invalid param given to procedure");

                $$ = vs->type;
                
                const char * to_write = generate_mepa_param(en, &(curr_subr->params[param_index]));
                sprintf(str_aux, "%s %d,%d", to_write, en->addr.nl, en->addr.offset);
            
                generate_code(-1, str_aux);
            }
            else if (en->category == cate_pf) {
                ParametroFormal * pf = (ParametroFormal*) en->element;

                if (pf->type != curr_subr->params[param_index].type)
                    trigger_error("invalid param given to procedure");

                $$ = pf->type;

                const char * to_write = generate_mepa_param(en, &(curr_subr->params[param_index]));
                sprintf(str_aux, "%s %d,%d", to_write, en->addr.nl, en->addr.offset);
            
                generate_code(-1, str_aux);
            }
            else if (en->category == cate_subr) {
                Subrotina * subr = en->element;
                if (subr->has_ret) {
                    if (subr->n_params != 0)
                        trigger_error("too few arguments");

                    if (subr->ret_type != curr_subr->params[param_index].type || curr_subr->params[param_index].ref)
                        trigger_error("invalid param given to procedure");

                    generate_code(-1, "AMEM 1");

                    chpr_subroutine(subr);
                }
                else
                    trigger_error("cant use procedures on expressions");
            }
        }
        else {
            if (en->category == cate_vs) {
                VariavelSimples * vs = (VariavelSimples*) en->element;

                $$ = vs->type;
                if (read_trigger) {
                    sprintf(str_aux, "ARMZ %d,%d", en->addr.nl, en->addr.offset);
                }
                else {
                    sprintf(str_aux, "CRVL %d,%d", en->addr.nl, en->addr.offset);
                }
            
                generate_code(-1, str_aux);
            }
            else if (en->category == cate_pf) {
                ParametroFormal * pf = (ParametroFormal*) en->element;

                $$ = pf->type;

                if (read_trigger) {
                    if (pf->ref)
                        sprintf(str_aux, "ARMI %d,%d", en->addr.nl, en->addr.offset);
                    else
                        sprintf(str_aux, "ARMZ %d,%d", en->addr.nl, en->addr.offset);
                }
                else {
                    if (pf->ref)
                        sprintf(str_aux, "CRVI %d,%d", en->addr.nl, en->addr.offset);
                    else
                        sprintf(str_aux, "CRVL %d,%d", en->addr.nl, en->addr.offset);
                }
            
                generate_code(-1, str_aux);
            }
            else if (en->category == cate_subr) {
                Subrotina * subr = en->element;
                if (subr->has_ret) {
                    if (subr->n_params != 0)
                        trigger_error("too few arguments");

                    generate_code(-1, "AMEM 1");

                    chpr_subroutine(subr);
                }
                else
                    trigger_error("cant use procedures on expressions");
            }
        }
    }
;


chamada_func:
    {        
        Entry * en = get_function(ident_aux);
        
        if (!en)
            trigger_error("unknown function");

        curr_subr = (Subrotina *) en->element;
        push(&SUBR_Stack, curr_subr);

        int * par = malloc(sizeof(int));
        must_alloc(par, "chamada func");
        *par = 0;
        push(&PARAM_Stack, par);

        generate_code(-1, "AMEM 1");
    }
    ABRE_PARENTESES lista_express_subr FECHA_PARENTESES
    {
        int param_index = *((int*) PARAM_Stack->v);  

        if (param_index < curr_subr->n_params)
            trigger_error("too few arguments");
        
        chpr_subroutine(curr_subr);
        
        $$ = curr_subr->ret_type;

        pop(&SUBR_Stack);
        if (SUBR_Stack)
            curr_subr = SUBR_Stack->v;
        else
            curr_subr = NULL;

        pop(&PARAM_Stack);
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
