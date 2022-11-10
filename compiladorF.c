
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

simbolos simbolo, relacao;
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

int imprimeErro ( char* erro )
{
    fprintf (stderr, "Erro na linha %d - %s\n", nivel_lexico, erro);
    exit(-1);
}


void push_symbol(int nl, int offset)
{
    Entry * ne = malloc(sizeof(Entry));

    ne->identificador = malloc(strlen(token));
    strcpy(ne->identificador, token);
    ne->nl = nl;
    ne->offset = offset;

    printf("%s %i %i\n", ne->identificador, ne->nl, ne->offset);

    push(&Tabela_Simbolos, ne);
}


void entry_destroy(void * ptr)
{
    Entry * ent = (Entry *) ptr;
    free(ent->identificador);
    free(ent);
}