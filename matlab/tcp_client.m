% Define server details
clear client;
serverIP = "localhost"; % Change to the server's IP address
serverPort = 8080;    % Change to the server's port

% Create a TCP/IP client
client = tcpclient(serverIP, serverPort);

% Send the message
while(true)
    message = 'transmit';
    write(client, uint8(message));
    response = read(client, client.NumBytesAvailable, 'uint8');
    disp(char(response));
    pause(1)
    message = 'stop';
    write(client, uint8(message));
    response = read(client, client.NumBytesAvailable, 'uint8');
    disp(char(response));
    pause(1);
    message = 'recieve';
    write(client, uint8(message));
    response = read(client, client.NumBytesAvailable, 'uint8');
    disp(char(response));
    pause(1);
end
% Optionally, wait for a response (if the server sends one)
% pause(1); % Give the server some time to respond
% response = read(client, client.NumBytesAvailable, 'uint8');
% disp(char(response));

% Close the connection
%clear client;
