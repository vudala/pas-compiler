
/* -------------------------------------------------------------------
 *            Aquivo: compilador.c
 * -------------------------------------------------------------------
 *              Autor: Bruno Muller Junior
 *               Data: 08/2007
 *      Atualizado em: [09/08/2020, 19h:01m]
 *
 * -------------------------------------------------------------------
 *
 * Funções auxiliares ao compilador
 *
 * ------------------------------------------------------------------- */

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
Stack * Tabela_Simbolos;

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
            printf("VS %s tipo %d\n", en->identifier, vs->type);
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

    ne->category = category;

    if (category == cate_vs) {
        VariavelSimples * vs = malloc(sizeof(VariavelSimples));
        must_alloc(vs, "malloc");

        vs->type = tipo_indefinido;
        vs->address.nl = nivel_lexico;
        vs->address.offset = offset;

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


void * get_entry_value(Entry * en)
{
    if (!en) {
        trigger_error("must have a valid entry");
    }

    if (en->category == cate_vs) {
        return en->element;
    }
    else if (en->category == cate_pf) {

    }
    else if (en->category == cate_proc) {

    }
    else {
        trigger_error("unknown entry category");
    }   
}


// atualiza os tipos das variaveis simples recem declaradas
void update_types(char * type)
{
    Stack * el = Tabela_Simbolos;
    Entry * en = (Entry *) el->v;
    VariavelSimples * vs = NULL;
 
    while(el && en && en->category == cate_vs) {
        vs = (VariavelSimples*) en->element;

        if (nivel_lexico != vs->address.nl || vs->type != tipo_indefinido)
            return;

        vs->type = get_type_enum(type);

        el = el->prev;
        if (el)
            en = (Entry *) el->v;
    }
}

