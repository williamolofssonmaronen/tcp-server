% Define server details
serverIP = '127.0.0.1'; % Change to the server's IP address
serverPort = 8080;    % Change to the server's port

% Create a TCP/IP client
client = tcpclient(serverIP, serverPort);

% Define the message to send
message = 'Hello, Server!';

% Send the message
while true
    write(client, uint8(message));
    pause(1);
end
% Optionally, wait for a response (if the server sends one)
% pause(1); % Give the server some time to respond
% response = read(client, client.NumBytesAvailable, 'uint8');
% disp(char(response));

% Close the connection
clear client;