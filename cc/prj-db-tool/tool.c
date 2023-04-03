
#include <sqlite3.h>
#include <stdio.h>
#include <stdlib.h>

int init_vars() {
  const char* path = getenv("PATH");
  printf("PATH :%s\n", (path != NULL) ? path : "getenv returned NULL");

  return 1;
}

int main() {
  printf("%s\n", sqlite3_libversion()); 

  init_vars();
    
  return 0;
}
