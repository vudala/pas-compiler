#ifndef STACK_INCLUDED
#define STACK_INCLUDED

typedef struct stack_el {
    void * v;
    struct stack_el *prev, *next;
} Stack;

void destroy(Stack ** base, void (*destroyer)(void *));

void push(Stack ** base, void * v);

void * pop(Stack ** base);

void * top(Stack ** base);

void pop_n(Stack ** base, int n);

#endif