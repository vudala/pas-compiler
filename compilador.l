%{

#include<stdio.h>
#include<string.h>

#include "compilador.h"
#include "compilador.tab.h"

extern int Line_Counter;

%}

pulo_linha [\n]

descarte [\t ]+

ident [a-zA-Z][a-zA-Z0-9]*

numero [0-9]+

comentario "(*".*"*)"

%%

{pulo_linha} {Line_Counter++;}

{descarte}

{comentario}

program {
    simbolo = simb_program;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return PROGRAM;
}

var {
    simbolo = simb_var;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return VAR;
}

begin {
    simbolo = simb_begin;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return T_BEGIN;
}

end {
    simbolo = simb_end;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return T_END;
}

:= {
    simbolo = simb_atribuicao;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return ATRIBUICAO;
}

\; {
    simbolo = simb_ponto_e_virgula;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return PONTO_E_VIRGULA;
}

\: {
    simbolo = simb_dois_pontos;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return DOIS_PONTOS;
}

\, {
    simbolo = simb_virgula;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return VIRGULA;
}


\. {
    simbolo = simb_ponto;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return PONTO;
}

\(  {
    simbolo = simb_abre_parenteses;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return ABRE_PARENTESES;
}

\)  {
    simbolo = simb_fecha_parenteses;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return FECHA_PARENTESES;
}

integer {
    simbolo = simb_inteiro;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return INTEIRO;
}

boolean {
    simbolo = simb_booleano;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return BOOLEANO;
}

\+ {
    simbolo = simb_mais;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return MAIS;
}

\- {
    simbolo = simb_menos;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return MENOS;
}

\* {
    simbolo = simb_multiplicacao;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return MULTIPLICACAO;
}

div {
    simbolo = simb_divisao;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return DIVISAO;
}

if {
    simbolo = simb_if;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return IF;
}

then {
    simbolo = simb_then;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return THEN;
}

else {
    simbolo = simb_else;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return ELSE;
}

while {
    simbolo = simb_while;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return WHILE;
}

do {
    simbolo = simb_do;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return DO;
}


\< {
    simbolo = simb_menor;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return MENOR;
}

\<= {
    simbolo = simb_menor_igual;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return MENOR_IGUAL;
}

\> {
    simbolo = simb_maior;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return MAIOR;
}

\>= {
    simbolo = simb_maior_igual;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return MAIOR_IGUAL;
}

\= {
    simbolo = simb_igual;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return IGUAL;
}

\<\> {
    simbolo = simb_diferente;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return DIFERENTE;
}

and {
    simbolo = simb_and;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return AND;
}

or {
    simbolo = simb_or;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return OR;
}

not {
    simbolo = simb_not;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return NOT;
}

true {
    simbolo = simb_true;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return TRUE;
}

false {
    simbolo = simb_false;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return FALSE;
}

procedure {
    simbolo = simb_procedure;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return PROCEDURE;
}

{numero} {
    simbolo = simb_numero;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return NUMERO;
}

{ident} {
    simbolo = simb_identificador;
    strncpy (Token, yytext, TAM_TOKEN);
    printf("%s ", Token); fflush(stdout);
    return IDENT;
}

%%
