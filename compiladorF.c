#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "compilador.h"
#include "stack.h"


/* -------------------------------------------------------------------
 *  variáveis globais
 * ------------------------------------------------------------------- */

int lc = 1;
Simbolos simbolo;
char token[TAM_TOKEN];
Stack * Tabela_Simbolos = NULL;
int Rotulo = 1;

Stack * Rotulos = NULL;

FILE* fp=NULL;

void geraCodigo (char* rot, char* comando)
{
    if (fp == NULL)
        fp = fopen ("MEPA", "w");

    if ( rot == NULL ) {
        fprintf(fp, "     %s\n", comando); fflush(fp);
    }
    else {
        fprintf(fp, "%s: %s \n", rot, comando); fflush(fp);
    }
}


void trigger_error (char* erro)
{
    fprintf (stderr, "Erro na linha %d - %s\n", lc, erro);
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
    Stack * el = Tabela_Simbolos;
    while(el != NULL) {
        Entry * en = (Entry *) el->v;
        
        if (en->category == cate_vs) {
            VariavelSimples * vs = (VariavelSimples *) en->element;
            printf("VS %s tipo %d %d %d\n", en->identifier, vs->type, en->addr.nl, en->addr.offset);
        }   
        el = el->prev;
    }
}


void push_symbol(int category)
{
    Entry * ne = malloc(sizeof(Entry));
    must_alloc(ne, "malloc");

    ne->identifier = malloc(strlen(token));
    must_alloc(ne->identifier, "malloc");
    strcpy(ne->identifier, token);
    ne->addr.nl = nivel_lexico;
    ne->addr.offset = offset;

    ne->category = category;

    Stack* el = Tabela_Simbolos;
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
        must_alloc(vs, "malloc");

        vs->type = tipo_indefinido;

        ne->element = (void*) vs;
    }
    else if (category == cate_proc) {
        void;
    }
    else if (category == cate_pf) {
        void;
    }

    push(&Tabela_Simbolos, ne);
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

    trigger_error("tipo inexistente\n");

    return tipo_indefinido;
}


Entry * get_entry(char * identifier)
{
    Stack * el = Tabela_Simbolos;
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
void update_types(char * type)
{
    Stack * el = Tabela_Simbolos;
    Entry * en = (Entry *) el->v;
    VariavelSimples * vs = NULL;
 
    while(el && en && en->category == cate_vs) {
        vs = (VariavelSimples*) en->element;

        if (nivel_lexico != en->addr.nl || vs->type != tipo_indefinido)
            return;

        vs->type = get_type_enum(type);

        el = el->prev;
        if (el)
            en = (Entry *) el->v;
    }
}

void print_operand_code(int operand){
    switch(operand) {
        case 1:
            geraCodigo(NULL, "SOMA");
            break;
        case 2:
            geraCodigo(NULL, "SUBT");
            break;
        case 3:
            geraCodigo(NULL, "MULT");
            break;
        case 4:
            geraCodigo(NULL, "DIVI");
            break;
        case 5:
            geraCodigo(NULL, "CMIG");
            break;
        case 6:
            geraCodigo(NULL, "CMDG");
            break;
        case 7:
            geraCodigo(NULL, "CMME");
            break;
        case 8:
            geraCodigo(NULL, "CMMA");
            break;
        case 9:
            geraCodigo(NULL, "CMEG");
            break;
        case 10:
            geraCodigo(NULL, "CMAG");
            break;
        case 11:
            geraCodigo(NULL, "CONJ");
            break;
        case 12:
            geraCodigo(NULL, "DISJ");
            break;
        default:
            trigger_error("unknown op code");
    }
}

int check_valid_int_operation(int operand){
    if (1 <= operand  && operand <= 11)
        return 1;
    return 0;
}

int check_valid_bool_operation(int operand){
    if (12 <= operand && operand <= 13 || 5 <= operand  && operand <= 6)
        return 1;
    return 0;
}

int resolve_operation_return(int op1, int op2, int operand){
    if (5 <= operand && operand <= 10 && op1 == tipo_inteiro && op2 == tipo_inteiro)
        return tipo_booleano;

    if (1 <= operand && operand <= 4 && op1 == tipo_inteiro && op2 == tipo_inteiro)
        return tipo_inteiro;

    if(op1 == tipo_booleano && op2 == tipo_booleano)
        return tipo_booleano;

    trigger_error("invalid operation");

    return tipo_indefinido;
}

int create_rotulo(){
    int * rot = malloc(sizeof(int));
    must_alloc(rot, __func__);
    *rot = Rotulo++;
    push(&Rotulos, (void*) rot);
    
    return *rot;
}

Stack* get_top_rotulo(){
    return Rotulos;
}

