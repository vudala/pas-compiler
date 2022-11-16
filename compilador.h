/* -------------------------------------------------------------------
 *            Arquivo: compilador.h
 * -------------------------------------------------------------------
 *              Autor: Bruno Muller Junior
 *               Data: 08/2007
 *      Atualizado em: [09/08/2020, 19h:01m]
 *
 * -------------------------------------------------------------------
 *
 * Tipos, protótipos e variáveis globais do compilador (via extern)
 *
 * ------------------------------------------------------------------- */

#define TAM_TOKEN 16

typedef enum simbolos {
    simb_program, simb_var, simb_begin, simb_end,
    simb_identificador, simb_numero,
    simb_ponto, simb_virgula, simb_ponto_e_virgula, simb_dois_pontos,
    simb_atribuicao, simb_abre_parenteses, simb_fecha_parenteses,
    simb_inteiro, simb_boolean
} Simbolos; 

/* -------------------------------------------------------------------
 * variáveis globais
 * ------------------------------------------------------------------- */

extern Simbolos simbolo, relacao;
extern char token[TAM_TOKEN];
extern int nivel_lexico;

typedef struct entry_t {
    char * identificador;
    int nl, offset;
	enum {
		tipo_indefinido = 0,
		tipo_inteiro,
		tipo_booleano
	} tipo;
} Entry;


/* -------------------------------------------------------------------
 * prototipos globais
 * ------------------------------------------------------------------- */

void geraCodigo (char*, char*);
int yylex();
void yyerror(const char *s);

void push_symbol(int nl, int offset);

void entry_destroy(void * ptr);

void update_types(char * type);