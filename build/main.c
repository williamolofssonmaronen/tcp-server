#include <arpa/inet.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define PORT 8080
#define BUFFER_SIZE 8192
#define RECV_INTERVAL 1 // 2 seconds receive window
#define SEND_INTERVAL 1 // 2 seconds send window

int main() {
  int server_fd, client_fd;
  struct sockaddr_in server_addr, client_addr;
  socklen_t client_len = sizeof(client_addr);
  char buffer[BUFFER_SIZE];

  // Create socket
  if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
    perror("Socket creation failed");
    return 1;
  }

  // Define server address
  server_addr.sin_family = AF_INET;
  server_addr.sin_addr.s_addr = INADDR_ANY;
  server_addr.sin_port = htons(PORT);

  // Bind socket to port
  if (bind(server_fd, (struct sockaddr *)&server_addr, sizeof(server_addr)) <
      0) {
    perror("Bind failed");
    return 1;
  }

  // Listen for connections
  if (listen(server_fd, 1) < 0) {
    perror("Listen failed");
    return 1;
  }

  printf("Server listening on port %d...\n", PORT);

  // Accept client connection
  if ((client_fd = accept(server_fd, (struct sockaddr *)&client_addr,
                          &client_len)) < 0) {
    perror("Accept failed");
    return 1;
  }

  printf("Client connected. Starting TDD...\n");

  int cycle = 0;
  while (1) {
    if (cycle % 2 == 0) { // Even cycle: RECEIVE
      memset(buffer, 0, BUFFER_SIZE);
      ssize_t bytes_read = recv(client_fd, buffer, BUFFER_SIZE, 0);
      if (bytes_read > 0) {
        printf("Received: %s", buffer);
      } else if (bytes_read == 0) {
        printf("Client disconnected.\n");
        break;
      } else {
        perror("Receive failed");
        break;
      }
      sleep(RECV_INTERVAL);
    } else { // Odd cycle: SEND
      snprintf(buffer, BUFFER_SIZE, "Server response at time: %ld\n",
               time(NULL));
      if (send(client_fd, buffer, strlen(buffer), 0) < 0) {
        perror("Send failed");
        break;
      }
      printf("Sent: %s", buffer);
      sleep(SEND_INTERVAL);
    }
    cycle++;
  }
  close(client_fd);
  close(server_fd);
  return 0;
}
