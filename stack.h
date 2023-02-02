#ifndef STACK_INCLUDED
#define STACK_INCLUDED

typedef struct stack_el {
    struct stack_el *prev, *next;
    void * v;
} Stack;

void destroy(Stack ** base, void (*destroyer)(void *));

void push(Stack ** base, void * v);

void * pop(Stack ** base);

void pop_n(Stack ** base, unsigned int n);

Stack * top(Stack ** base);

#endif