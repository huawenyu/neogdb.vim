#include <stdlib.h>
#include <string.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h> /* sleep() */

struct cb_ops {
	void (*cb)(int);
};

int bar(int a, int b)
{
	return a + b;
}

int foo(int a)
{
	int x = 11;
	int y = 22;
	char *str = "This is function 'foo'";

	return bar(a, x + y);
}

int main(void)
{
	int a = 3;
	struct embedd {
		struct ops *ops;
	} cb;
	int b = 6;
	char *str = "Hello world";

	a += 1;
	b += 1;
	cb.ops = 0;

	a = foo(a);

	printf("a=%d\n", a);
	return 1;
}

/*

#0  main () at t1.c:13

*/

