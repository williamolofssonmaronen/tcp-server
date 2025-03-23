#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define PORT 8080
#define BUFFER_SIZE 1024

int main() {
  int server_fd, new_socket;
  struct sockaddr_in address;
  int opt = 1;
  int addrlen = sizeof(address);
  char buffer[BUFFER_SIZE] = {0};
  char *message = "Hello Client!";

  // Create a socket file descriptor
  if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
    perror("socket failed");
    exit(EXIT_FAILURE);
  }
  // Set socket options
  if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT, &opt,
                 sizeof(opt))) {
    perror("setsockopt");
    exit(EXIT_FAILURE);
  }

  // Setup the server address
  // Set the address family to AF_INET (IPv4)
  address.sin_family = AF_INET;

  // ACccepting connection on any availabe interface / communication mean
  address.sin_addr.s_addr = INADDR_ANY;

  // Set the port number in any ntework byte order / PORT 8080
  address.sin_port = htons(PORT);

  if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
    perror("bind fails!");
    exit(EXIT_FAILURE);
  }
  if (listen(server_fd, 3) < 0) {
    perror("listening fails!");
  }
  // Prints messages indicating that the server has not failed and is actively
  // listening in the specified port(8080)
  printf("Server listening on port %d\n", PORT);

  if ((new_socket = accept(server_fd, (struct sockaddr *)&address,
                           (socklen_t *)&addrlen)) < 0) {
    perror("Accepted!");
    exit(EXIT_FAILURE);
  }
  printf("Connection accepted\n");

  send(new_socket, message, strlen(message), 0);

  // Read data from the client and print it
  // Declare a signed size type variable for the number of bytes read

  ssize_t valread;
  while ((valread = read(new_socket, buffer, BUFFER_SIZE)) > 0) {
    printf("Client %s\n", buffer);
    memset(buffer, 0, sizeof(buffer));
  }
  close(server_fd);
  return 0;
}
