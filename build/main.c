#include <arpa/inet.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define PORT 8080
#define BUFFER_SIZE 8192
#define MAX_FLOATS (BUFFER_SIZE / sizeof(float))

int main() {
  int server_fd, client_fd;
  struct sockaddr_in server_addr, client_addr;
  socklen_t client_len = sizeof(client_addr);
  char buffer[BUFFER_SIZE];
  float realPart[BUFFER_SIZE];
  float imaginaryPart[BUFFER_SIZE];
  float real_data[500];
  float imaginary_data[500];
  int num_real = 0;
  int num_imaginary = 0;

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

  printf("Client connected. Awaiting ...\n");

  bool transmission = false;
  while (1) {
    memset(buffer, 0, BUFFER_SIZE);
    ssize_t bytes_read = recv(client_fd, buffer, BUFFER_SIZE, 0);
    if (bytes_read > 0) {
      printf("Received: %s\n", buffer);
      if (strcmp(buffer, "transmit") == 0) {
        transmission = true;
        snprintf(buffer, BUFFER_SIZE, "Starting transmission");
        if (send(client_fd, buffer, strlen(buffer), 0) < 0) {
          perror("Send failed");
          break;
        }
        printf("Starting transmission...\n");
        // Read in imaginary part
        memset(imaginaryPart, 0, BUFFER_SIZE);
        ssize_t imaginary_read = recv(client_fd, imaginaryPart, BUFFER_SIZE, 0);
        // Assume data is float-aligned
        int num_imaginary = imaginary_read / sizeof(float);
        float *imaginary_data = (float *)imaginaryPart;
        // Read in real part
        memset(realPart, 0, BUFFER_SIZE);
        ssize_t real_read = recv(client_fd, realPart, BUFFER_SIZE, 0);
        // Assume data is float-aligned
        int num_real = real_read / sizeof(float);
        float *real_data = (float *)realPart;
        // Print out collected complex data
        for (int i = 0; i < num_real; i++) {
          printf("real[%d] = %f imaginary[%d] = %f\n", i, real_data[i], i,
                 imaginary_data[i]);
        }
        // Start loop transmission
      } else if (strcmp(buffer, "stop") == 0) {
        snprintf(buffer, BUFFER_SIZE, "Stopped transmission");
        if (transmission == false) {
          perror("Not transmitting");
          break;
        } else if (send(client_fd, buffer, strlen(buffer), 0) < 0) {
          perror("Send failed");
          break;
        }
        printf("Transmission stopped\n");
        transmission = false;
        // Stop the transmission loop
      } else if (strcmp(buffer, "recieve") == 0) {
        snprintf(buffer, BUFFER_SIZE, "Starting recieving");
        if (transmission == true) {
          perror("Transmitting");
          break;
        } else if (send(client_fd, buffer, strlen(buffer), 0) < 0) {
          perror("Send failed");
          break;
        }
        printf("Starting recieving\n");
        send(client_fd, &num_real, sizeof(int), 0);
        send(client_fd, real_data, num_real * sizeof(float), 0);
        send(client_fd, &num_imaginary, sizeof(int), 0);
        send(client_fd, imaginary_data, num_imaginary * sizeof(float), 0);
        printf("Sent %d real and %d imaginary floats to client\n", num_real,
               num_imaginary);
      } else {
        snprintf(buffer, BUFFER_SIZE, "Unkown command");
        if (send(client_fd, buffer, strlen(buffer), 0) < 0) {
          perror("Send failed");
          break;
        }
        perror("Unkown command\n");
      }
    } else if (bytes_read == 0) {
      printf("Client disconnected.\n");
      break;
    } else {
      perror("Receive failed");
      break;
    }
  }
  close(client_fd);
  close(server_fd);
  return 0;
}
