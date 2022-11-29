#include "stack.h"

#include <stdlib.h>
#include <stdio.h>


void destroy(Stack ** base, void (*destroyer)(void *))
{
    void * ret = NULL;
    while (*base != NULL) {
        ret = pop(base);
        if (ret)
            destroyer(ret);
    }
}


void push(Stack ** base, void * v)
{
    if (base == NULL)
        return;
   
    Stack * elem = malloc(sizeof(Stack));
    elem->v = v;
    elem->next = NULL;

    if (*base == NULL) {
        elem->prev = NULL;
    }
    else {
        elem->prev = *base;
        (*base)->next = elem;
    }
    *base = elem;
}


void * pop(Stack ** base)
{
    if (base == NULL || *base == NULL)
        return NULL;

    Stack * el = *base;
    *base = el->prev;

    void * ret = el->v;
    free(el);

    return ret;
}


void * top(Stack ** base)
{
    if (base == NULL || *base == NULL)
        return NULL;

    return (*base)->v;
}


void pop_n(Stack ** base, int n)
{
    while(base && n--)
        pop(base);
}