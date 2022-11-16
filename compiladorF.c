
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

Simbolos simbolo, relacao;
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


int trigger_error ( char* erro )
{
    fprintf (stderr, "Erro na linha %d - %s\n", nivel_lexico, erro);
    exit(-1);
}


void push_symbol(int nl, int offset)
{
    Entry * ne = malloc(sizeof(Entry));

    ne->identifier = malloc(strlen(token));
    strcpy(ne->identifier, token);
    ne->address.nl = nl;
    ne->address.offset = offset;
    ne->type = tipo_indefinido;

    printf("%s %i %i\n", ne->identifier, ne->address.nl, ne->address.offset);

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
    if (!strcmp(type, "bool")) return tipo_booleano;

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
        en = (Entry*) el->v;
    }

    return NULL;
}


void update_types(char * type)
{
    Stack * el = Tabela_Simbolos;
    Entry * en = (Entry *) el->v;
 
    // enquanto houver elementos validos e seus tipos forem indefinidos e sob o mesmo nivel lexico
    while(el && en && !en->type && en->address.nl == nivel_lexico) {
        en->type = get_type_enum(type);

        el = el->prev;
        if (el)
            en = (Entry *) el->v;
    }
}
