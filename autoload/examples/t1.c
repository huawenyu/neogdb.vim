#include <stdlib.h>
#include <string.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h> /* sleep() */

int main(void)
{
	int count = 0;
	int a;

	while ((++count) <= 20) {
		printf("pid=%d sleep(%d)\n", getpid(), count);
		sleep(2);
	}

	a += 1;
	a += 1;
	a += 1;
	a += 1;
	return 1;
}

/*

#0  main () at t1.c:13

*/

