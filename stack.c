#include "stack.h"

#include <stdlib.h>
#include <stdio.h>


void destroy(Stack ** base, void (*destroyer)(void *))
{
    void * ret = NULL;
    Stack * el = top(*base);
    while (el != NULL) {
        ret = pop(&el);
        if (ret)
            destroyer(ret);
    }
}


void push(Stack ** base, void * v)
{
    if (base == NULL)
        return;
   
    Stack * elem = malloc(sizeof(Stack));
    if (!elem) {
        perror("malloc");
        exit(-1);
    }

    elem->v = v;
    elem->next = NULL;

    *base = top(*base);

    if (*base == NULL) {
        elem->prev = NULL;
    }
    else {
        Stack * top_el = *base;
        elem->prev = top_el;
        top_el->next = elem;
    }
    
    *base = elem;
}


void * pop(Stack ** base)
{
    if (base == NULL || *base == NULL)
        return NULL;

    *base = top(*base);

    Stack * el = *base;
    *base = el->prev;
    if (*base)
        (*base)->next = NULL;

    void * ret = el->v;
    free(el);

    return ret;
}


void pop_n(Stack ** base, unsigned int n)
{
    *base = top(*base);
    if (base)
        while(*base && n--)
            pop(base);
}


Stack * top(Stack * base)
{
    if (base == NULL)
        return NULL;
    
    Stack * top_el = NULL;
    Stack * el = base;
    while(el != NULL) {
        top_el = el;
        el = el->next;
    }
    return top_el;
}