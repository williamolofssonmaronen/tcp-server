#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define PORT 8080
#define BUFFER_SIZE 1024

int main()
{
	int server_fd, new_socket;
	struct sockaddr_in adress;
	int opt = 1;
	int addrlen = sizeof(adress);
	char buffer[BUFFER_SIZE] = {0};
	
	// Create a socket file descriptor
	if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0)
	{
		perror("socket failed");
		exit(EXIT_FAILURE);
	}
	printf("Hello World!\n");
}