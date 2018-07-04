#include <stdlib.h>
#include <string.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h> /* sleep() */

struct my_str {
	char *val;
	int len;
};

struct cb_ops {
	void (*cb)(int);
};

void f_sleep(void)
{
	int count = 0;
	int a;

	while ((++count) <= 20) {
		printf("pid=%d sleep(%d)\n", getpid(), count);
		sleep(2);
	}
}

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

void f_str(void)
{
	int a, b, c;
	struct my_str *str1;

	a = 11;
	b = 12;
	c = 13;
	str1 = malloc(sizeof(*str1));
	str1->val = "hello";
	str1->len = 6;

	free(str1);
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

	f_str();
	a = foo(a);

	printf("a=%d\n", a);
	return 1;
}

/*

#0  main () at t1.c:13

*/

