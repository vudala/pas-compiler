#ifndef COMPILADOR_INCLUDED
#define COMPILADOR_INCLUDED

#include "stack.h"

#define TAM_TOKEN 16

typedef enum simbolos {
    simb_program, simb_var, simb_begin, simb_end,
    simb_identificador, simb_numero,
    simb_ponto, simb_virgula, simb_ponto_e_virgula, simb_dois_pontos,
    simb_atribuicao, simb_abre_parenteses, simb_fecha_parenteses,
    simb_inteiro, simb_booleano,
    simb_mais, simb_menos, simb_multiplicacao, simb_divisao,
    simb_if, simb_then, simb_else,
    simb_menor, simb_maior, simb_menor_igual, simb_maior_igual,
    simb_igual, simb_diferente, simb_and, simb_not, simb_or,
    simb_true, simb_false
} Simbolos; 


typedef enum type {
    tipo_indefinido = 0,
    tipo_inteiro,
    tipo_booleano
} Type;

/* -------------------------------------------------------------------
 * variáveis globais
 * ------------------------------------------------------------------- */

extern Simbolos simbolo;
extern char Token[TAM_TOKEN];
extern int nivel_lexico;
extern int offset;

typedef struct mepa_addr {
    int nl, offset;
} MEPA_Address;

typedef struct variavel_simples {
	Type type;
} VariavelSimples;


typedef struct parametro_formal {
	Type type;
    int ref;                // 0 -> valor, != 0 -> referencia
} ParametroFormal;


typedef struct entry_t {
    char * identifier;  // identificador
    void * element;     // valor
    MEPA_Address addr;        // endereço na memória
    enum {
        cate_vs = 0,    // variavel simples
        cate_proc,      // procedimento
        cate_pf         // parametro formal
    } category;
} Entry;

void generate_code(int label_n, char * command);

int yylex();

void yyerror(const char *s);

void push_symbol(int category);

void entry_destroy(void * ptr);

void update_types(char * type);

void trigger_error (char* erro);

Entry * get_entry(char * identifier);

void print_operation_code(int opcode);

int check_valid_int_operation(int operand);

int check_valid_bool_operation(int operand);

int resolve_operation_return(int op1, int op2, int operator);

void print_tabela_simbolos();

void destroy_labels(unsigned int n);

int create_label();

Stack * get_top_label();

#endif