%%
% SERVER DETAILS
%serverIP = '192.168.50.125'; % Change to the server's IP address
serverIP = "localhost";
serverPort = 8080;    % Change to the server's port

% Create a TCP/IP client
client = tcpclient(serverIP, serverPort);


%%
% Generate random binary data
M = 16; % modulation order (M-QAM)
k = log2(M); % number of bits per symbol
numSymbols = 100; % number of symbols
numBits = numSymbols*k; % number of bits
bitsIn = randi([0 1], numBits, 1);
% Start transmission
transmit_start(client, bitsIn);
pause(1);
% Stop transmission
transmit_stop(client);
pause(1);
% Recieve signal
rxSignal = recieve(client);
