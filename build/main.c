#include <arpa/inet.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>

#define PORT 8080
#define BUFFER_SIZE 8192
#define MAX_FLOATS (BUFFER_SIZE * sizeof(float))

int main() {
  int server_fd, client_fd;
  struct sockaddr_in server_addr, client_addr;
  int opt = 1;
  socklen_t client_len = sizeof(client_addr);
  char buffer[BUFFER_SIZE];
  float real_data[BUFFER_SIZE];
  float imaginary_data[BUFFER_SIZE];
  int num_real = 0;
  int num_imaginary = 0;
  int num_floats = 0;

  // Create socket
  if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
    perror("Socket creation failed");
    return 1;
  }

  // Set SO_REUSEADDR option before bind()
  if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0) {
    perror("setsockopt(SO_REUSEADDR) failed");
    close(server_fd);
    exit(EXIT_FAILURE);
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
  bool keep_running = true;
  while (keep_running) {
    printf("Awaiting command...\n");
    memset(buffer, 0, BUFFER_SIZE);
    ssize_t bytes_read = recv(client_fd, buffer, BUFFER_SIZE, 0);
    if (bytes_read > 0) {
      printf("Received: %s\n", buffer);
      if (strcmp(buffer, "transmit") == 0) {
        memset(real_data, 0, sizeof(real_data));
        memset(imaginary_data, 0, sizeof(imaginary_data));
        transmission = true;
        snprintf(buffer, BUFFER_SIZE, "Starting transmission");
        if (send(client_fd, buffer, strlen(buffer), 0) < 0) {
          perror("Send failed");
          break;
        }
        printf("Starting transmission...\n");
        ssize_t num_bytes = recv(client_fd, &num_floats, sizeof(int), 0);
        printf("Expecting %d floats of the maximum allowed %d\n.", num_floats,
               (int)MAX_FLOATS);
        if (num_floats > (int)MAX_FLOATS) {
          perror("Warning: too many floats!");
        }
        // Read in imaginary part
        ssize_t imaginary_read =
            recv(client_fd, imaginary_data, num_floats * sizeof(float), 0);
        // Read in real part
        ssize_t real_read =
            recv(client_fd, real_data, num_floats * sizeof(float), 0);
        num_imaginary = (int)imaginary_read / sizeof(float);
        num_real = (int)real_read / sizeof(float);
        if (num_imaginary != num_floats || num_real != num_floats) {
          printf("Re: %d. Im: %d\n", num_real, num_imaginary);
          perror("Not as many imaginary as real or vice versa!");
        }
        // Print out collected complex data
        for (int i = 0; i < num_floats; i++) {
          // printf("real[%d] = %f imaginary[%d] = %f\n", i, real_data[i], i,
          //        imaginary_data[i]);
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
        // Start recieving loop and timer.
        printf("Sending num_floats...\n");
        ssize_t sent1 = send(client_fd, &num_floats, sizeof(num_floats), 0);
        if (sent1 < 0) {
          perror("Sending of num_floats failed!");
        }
        printf("Sending real_data...\n");
        ssize_t sent2 =
            send(client_fd, real_data, num_floats * sizeof(float), 0);
        if (sent2 < 0) {
          perror("Sending of real_data failed!");
        }
        printf("Sending imaginary_data...\n");
        ssize_t sent3 =
            send(client_fd, imaginary_data, num_floats * sizeof(float), 0);
        if (sent3 < 0) {
          perror("Sending of imaginary_data failed!");
        }
        // Print out complex data that were just sent
        for (int i = 0; i < num_floats; i++) {
          // printf("real[%d] = %f imaginary[%d] = %f\n", i, real_data[i], i,
          //        imaginary_data[i]);
        }
        printf("Sent bytes: header=%zd, real=%zd, imag=%zd\n", sent1, sent2,
               sent3);
        printf("Recieved and sent successfully.\n");
      } else if (strcmp(buffer, "exit") == 0 ||
                 strcmp(buffer, "shutdown") == 0) {
        printf("Shutdown command received.\n");
        snprintf(buffer, BUFFER_SIZE, "Shutting down server...");
        send(client_fd, buffer, strlen(buffer), 0);
        keep_running = false; // exit loop and shut down
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
      client_fd =
          accept(server_fd, (struct sockaddr *)&client_addr, &client_len);
      if (client_fd < 0) {
        perror("Accept failed");
        break;
      }
      printf("New client connected.\n");
    } else {
      perror("Receive failed");
      break;
    }
  }
  close(client_fd);
  close(server_fd);
  return 0;
}
