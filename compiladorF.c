#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "compilador.h"
#include "stack.h"


/* -------------------------------------------------------------------
 *  variáveis globais
 * ------------------------------------------------------------------- */

int Line_Counter = 1;
Simbolos simbolo;

char aux[100];

char Token[TAM_TOKEN];

// tabela de simbolos
Stack * Symbol_Table = NULL;

// controle de rotulos
int Label_Counter = 0;
Stack * Labels = NULL;

FILE* fp = NULL;

void generate_code(int rot, char* comando)
{
    if (fp == NULL)
        fp = fopen ("MEPA", "w");

    if (rot == -1) {
        fprintf(fp, "    %s\n", comando); fflush(fp);
    }
    else {
        fprintf(fp, "R%.2d:%s \n", rot, comando); fflush(fp);
    }
}


void trigger_error (char* erro)
{
    fprintf (stderr, "Error at line %d - %s\n", Line_Counter, erro);
    exit(-1);
}


void must_alloc(const void * ptr, const char * msg)
{
    if (!ptr) {
        perror(msg);
        exit(-1);
    }
}


void print_tabela_simbolos()
{
    Stack * el = Symbol_Table;
    while(el != NULL) {
        Entry * en = (Entry *) el->v;
        
        if (en->category == cate_vs) {
            VariavelSimples * vs = (VariavelSimples *) en->element;
            printf("VS %s tipo %d %d %d\n", en->identifier, vs->type, en->addr.nl, en->addr.offset);
        }
        else if (en->category == cate_subr) {
            Subrotina * subr = (Subrotina *) en->element;
            if (subr->has_ret)
                printf("F %s %d ret %d\n", en->identifier, en->addr.nl, subr->ret_type);
            else
                printf("P %s %d\n", en->identifier, en->addr.nl);
        }
        else if (en->category == cate_pf) {
            ParametroFormal * pf = (ParametroFormal *) en->element;
            printf("PF %s tipo %d nl %d off %d\n", en->identifier, pf->type, en->addr.nl, en->addr.offset);
        }
        el = el->prev;
    }
}


void push_symbol(int category)
{
    Entry * ne = malloc(sizeof(Entry));
    must_alloc(ne, "malloc");

    ne->identifier = malloc(strlen(Token));
    must_alloc(ne->identifier, "malloc");
    strcpy(ne->identifier, Token);

    ne->addr.nl = nivel_lexico;
    ne->addr.offset = offset;

    ne->category = category;

    Stack * el = Symbol_Table;
    while(el != NULL){
        Entry* entry = (Entry*) el->v;

        if(entry->addr.nl != nivel_lexico)
            break;

        if(strcmp(entry->identifier, ne->identifier) == 0)
            trigger_error("identificador ja declarado");
        
        el = el->prev;
    }

    if (category == cate_vs) {
        VariavelSimples * vs = malloc(sizeof(VariavelSimples));
        must_alloc(vs, __func__);

        vs->type = tipo_indefinido;

        ne->element = (void*) vs;
    }
    else if (category == cate_subr) {
        Subrotina * subr = malloc(sizeof(Subrotina));
        must_alloc(subr, __func__);

        subr->has_ret = 0;
        subr->ret_type = tipo_indefinido;
        subr->n_params = 0;
        subr->n_rotulo = *((int*) get_top_label()->v);

        ne->addr.offset = -99;

        ne->element = (void*) subr;
    }
    else if (category == cate_pf) {
        ParametroFormal * pf = malloc(sizeof(ParametroFormal));
        must_alloc(pf, __func__);

        pf->type = tipo_indefinido;
        ne->element = (void*) pf;
    }

    push(&Symbol_Table, ne);
}


void entry_destroy(void * ptr)
{
    Entry * ent = (Entry *) ptr;
    if(ent->category == cate_vs) {
        free(ent->element);
    }
    else if (ent->category == cate_pf) {
        free(ent->element);
    }
    else if (ent->category == cate_subr) {
        Subrotina * subr = (Subrotina*) ent->element;
        free(subr->params);
        free(subr);
    }

    free(ent->identifier);
    free(ent);
}


int get_type_enum(char * type)
{
    if (!strcmp(type, "integer")) return tipo_inteiro;

    if (!strcmp(type, "boolean")) return tipo_booleano;

    trigger_error("tipo inexistente");

    return tipo_indefinido;
}


// retorna um registro da tabela de simbolos correspondente ao identificador
Entry * get_entry(char * identifier)
{
    Stack * el = Symbol_Table;
    Entry * en = (Entry*) el->v;

    while (el && en) {
        if (strcmp(identifier, en->identifier) == 0)
            return en;

        el = el->prev;
        if (el)
            en = (Entry*) el->v;
    }

    return NULL;
}


// atualiza os tipos das variaveis simples recem declaradas
void update_types(int cate, int ref, int type)
{
    Stack * el = Symbol_Table;
    Entry * en = (Entry *) el->v;
    VariavelSimples * vs = NULL;
 
    while(el && en && (en->category == cate)) {
        vs = (VariavelSimples*) en->element;

        if (nivel_lexico != en->addr.nl || vs->type != tipo_indefinido)
            return;

        vs->type = type;

        if (cate == cate_pf) {
            ParametroFormal * pf = (ParametroFormal *) en->element;
            pf->ref = ref;
        }

        el = el->prev;
        if (el)
            en = (Entry *) el->v;
    }
}


// gera o codigo mepa correspondente ao codigo do operando
void print_operation_code(int operand){
    switch(operand) {
        case 1:
            generate_code(-1, "SOMA");
            break;
        case 2:
            generate_code(-1, "SUBT");
            break;
        case 3:
            generate_code(-1, "MULT");
            break;
        case 4:
            generate_code(-1, "DIVI");
            break;
        case 5:
            generate_code(-1, "CMIG");
            break;
        case 6:
            generate_code(-1, "CMDG");
            break;
        case 7:
            generate_code(-1, "CMME");
            break;
        case 8:
            generate_code(-1, "CMMA");
            break;
        case 9:
            generate_code(-1, "CMEG");
            break;
        case 10:
            generate_code(-1, "CMAG");
            break;
        case 11:
            generate_code(-1, "CONJ");
            break;
        case 12:
            generate_code(-1, "DISJ");
            break;
        default:
            trigger_error("unknown op code");
    }
}


int check_valid_int_operation(int operand)
{
    if (1 <= operand  && operand <= 11)
        return 1;
    return 0;
}


int check_valid_bool_operation(int operand)
{
    if (12 <= operand && operand <= 13 || 5 <= operand  && operand <= 6)
        return 1;
    return 0;
}


int resolve_operation_return(int op1, int op2, int operand)
{
    if (5 <= operand && operand <= 10 && op1 == tipo_inteiro && op2 == tipo_inteiro)
        return tipo_booleano;

    if (1 <= operand && operand <= 4 && op1 == tipo_inteiro && op2 == tipo_inteiro)
        return tipo_inteiro;

    if(op1 == tipo_booleano && op2 == tipo_booleano)
        return tipo_booleano;

    trigger_error("invalid operation");

    return tipo_indefinido;
}


int create_label()
{
    int * rot = malloc(sizeof(int));
    must_alloc(rot, __func__);

    *rot = Label_Counter++;

    push(&Labels, (void*) rot);
    
    return *rot;
}


Stack * get_top_label()
{
    return top(Labels);
}


// destroy n rotulos da pilha
void destroy_labels(unsigned int n)
{
    pop_n(&Labels, n);
}


void destroy_block_entries(int nl)
{
    if (!Symbol_Table)
        return;

    Entry * en = (Entry *) Symbol_Table->v;
    while (en && en->addr.nl == nl) {
        entry_destroy(pop(&Symbol_Table));

        if (Symbol_Table)
            en = (Entry *) Symbol_Table->v;
        else
            return;
    }
}


Entry * get_top_subroutine()
{
    Stack * el = Symbol_Table;
    if (!el)
        return NULL;

    Entry * en = (Entry *) el->v;
    while (el && en && en->category != cate_subr) {
        en = (Entry *) el->v;
        el = el->prev;
    }

    return en;
}


Entry * get_top_function()
{
    Stack * el = Symbol_Table;
    if (!el)
        return NULL;

    Entry * en = (Entry *) el->v;
    while(el && en) {
        if (en->category == cate_subr) {
            Subrotina * subr = (Subrotina *) en->element;
            if (subr->has_ret)
                return en;
        }

        en = (Entry *) el->v;
        el = el->prev;
    }

    return NULL;
}


Entry * get_top_procedure()
{
    Stack * el = Symbol_Table;
    if (!el)
        return NULL;

    Entry * en = (Entry *) el->v;
    while(el && en) {
        if (en->category == cate_subr) {
            Subrotina * subr = (Subrotina *) en->element;
            if (!subr->has_ret)
                return en;
        }

        en = (Entry *) el->v;
        el = el->prev;
    }

    return NULL;
}


Entry * get_subroutine(char * ident)
{
    Entry * en = get_entry(ident);
    if (en && en->category == cate_subr)
        return en;
    return NULL;
}


Entry * get_procedure(char * ident)
{
    Entry * en = get_subroutine(ident);
    if (en) {
        Subrotina * subr = (Subrotina *) en->element;
        if (!subr->has_ret)
            return en;
    }
    return NULL;
}


Entry * get_function(char * ident)
{
    Entry * en = get_subroutine(ident);
    if (en) {
        Subrotina * subr = (Subrotina *) en->element;
        if (subr->has_ret)
            return en;
    }
    return NULL;
}


void update_subr_params()
{
    Entry * en = get_top_subroutine();
    if (!en)
        trigger_error("no procedure to update");

    Subrotina * subr = (Subrotina *) en->element;
    subr->params = malloc(sizeof(ParametroFormal) * subr->n_params);
    must_alloc(subr->params, __func__);

    Stack * el = Symbol_Table;
    en = (Entry *) el->v;

    int i = subr->n_params;
    int offs_c = -4;
    while(el && en && i--) {
        ParametroFormal * pf = (ParametroFormal *) en->element;
        if (!pf)
            trigger_error("unknwon param");
        
        memcpy(&(subr->params[i]), pf, sizeof(ParametroFormal));

        en->addr.offset = offs_c--;
        el = el->prev;
        if (el)
            en = (Entry *) el->v;
    }

    if (i != -1)
        trigger_error("unable to fill all params of subroutine");
}


const char * generate_mepa_param(Entry * en1, ParametroFormal * pf2)
{
    if (!en1 || !pf2)
        return NULL;

    if (en1->category == cate_vs) {
        if (pf2->ref)
            return "CREN";
        else
            return "CRVL";
    }
    else if (en1->category == cate_pf) {
        ParametroFormal * pf1 = (ParametroFormal *) en1->element;
        if (!pf1)
            return NULL;

        if (pf1->ref) {
            if (pf2->ref)
                return "CRVL";
            else
                return "CRVI";
        }
        else {
            if (pf2->ref)
                return "CREN";
            else
                return "CRVL";    
        }
    }

    return NULL;
}


void chpr_subroutine(Subrotina * subr)
{
    sprintf(aux, "CHPR R%.2d,%d", subr->n_rotulo, nivel_lexico);
    generate_code(-1, aux);
}


void rtpr_subroutine(Subrotina * subr)
{
    sprintf(aux, "RTPR %d,%d", nivel_lexico, subr->n_params);
    generate_code(-1, aux);
}