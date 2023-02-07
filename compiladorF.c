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

char Token[TAM_TOKEN];

// tabela de simbolos
Stack * Symbol_Table = NULL;

// controle de rotulos
int Label_Counter = 1;
Stack * Labels = NULL;

FILE* fp = NULL;

void generate_code(int rot, char* comando)
{
    if (fp == NULL)
        fp = fopen ("MEPA", "w");

    if (rot == -1) {
        fprintf(fp, "     %s\n", comando); fflush(fp);
    }
    else {
        fprintf(fp, "R%d: %s \n", rot, comando); fflush(fp);
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
        else if (en->category == cate_proc) {
            Procedimento * p = (Procedimento *) en->element;
            printf("P %s %d\n", en->identifier, en->addr.nl);
        }
        else if (en->category == cate_pf) {
            ParametroFormal * pf = (ParametroFormal *) en->element;
            printf("PF %s tipo %d\n", en->identifier, pf->type);
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

    Stack* el = Symbol_Table;
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
    else if (category == cate_proc) {
        Procedimento * p = malloc(sizeof(Procedimento));
        must_alloc(p, __func__);

        p->n_rotulo = *((int*) get_top_label()->v);

        ne->addr.offset = -1;

        ne->element = (void*) p;
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
void update_types(int cate, int ref, char * type)
{
    Stack * el = Symbol_Table;
    Entry * en = (Entry *) el->v;
    VariavelSimples * vs = NULL;
 
    while(el && en && (en->category == cate)) {
        vs = (VariavelSimples*) en->element;

        if (nivel_lexico != en->addr.nl || vs->type != tipo_indefinido)
            return;

        vs->type = get_type_enum(type);

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
        pop(&Symbol_Table);
        if (Symbol_Table)
            en = (Entry *) Symbol_Table->v;
        else
            return;
    }
}


Procedimento * get_top_procedure()
{
    Stack * el = Symbol_Table;
    if (!el)
        return NULL;

    Entry * en = (Entry *) el->v;
    while(el && en && en->category != cate_proc) {
        en = (Entry *) el->v;
        el = el->prev;
    }

    if (en)
        return (Procedimento *) en->element;

    return NULL;
}


void update_proc_params()
{
    Procedimento * p = get_top_procedure();
    if (!p)
        trigger_error("no procedure to update");

    p->params = malloc(sizeof(ParametroFormal) * p->n_params);
    must_alloc(p->params, __func__);

    Stack * el = Symbol_Table;
    Entry * en = (Entry *) el->v;
    ParametroFormal * pf = NULL;

    int i = p->n_params;
    while(en && i--) {
        pf = (ParametroFormal *) en->element;
        if (!pf)
            trigger_error("unknwon param");
        
        memcpy(&(p->params[i]), pf, sizeof(ParametroFormal));

        en = (Entry *) el->prev;
    }

    if (i != -1)
        trigger_error("unable to fill all params of procedure");
}