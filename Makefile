 # -------------------------------------------------------------------
 #            Arquivo: Makefile
 # -------------------------------------------------------------------
 #              Autor: Bruno Müller Junior
 #               Data: 08/2007
 #      Atualizado em: [09/08/2020, 19h:01m]
 #
 # -------------------------------------------------------------------

$DEPURA=1

compilador: lex.yy.c compilador.tab.c compilador.o stack.o
	gcc lex.yy.c compilador.tab.c compilador.o stack.o -o compilador -ll -ly -lc

stack.o: stack.c
	gcc -g -c stack.c

lex.yy.c: compilador.l
	flex compilador.l

compilador.tab.c: compilador.y
	bison compilador.y -d -v

compilador.o : compiladorF.c
	gcc -g -c compiladorF.c -o compilador.o

clean :
	rm -f compilador.tab.* lex.yy.c compilador.o stack.o MEPA compilador.output compilador
