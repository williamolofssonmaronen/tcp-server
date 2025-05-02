%%
clear all;
% SERVER DETAILS
%serverIP = '192.168.50.125'; % Change to the server's IP address
serverIP = "localhost";
serverPort = 8080;    % Change to the server's port

% Create a TCP/IP client
client = tcpclient(serverIP, serverPort);
client.InputBufferSize = 8192;

%%
% Close all figures
close all; flush(client);

rolloff = 0.25; % RRC roll-off factor
span = 25; % RRC filter transient lenght
Rsamp = 40e6; % sample rate
Rsym = 10e6; % symbol rate

% Generate random binary data
M = 16; % modulation order (M-QAM)
k = log2(M); % number of bits per symbol
numSymbols = 3; % number of symbols
numBits = numSymbols*k; % number of bits
bitsIn = randi([0 1], numBits, 1);

rrc_filt = rcosdesign(rolloff, span, Rsamp/Rsym,'sqrt');

% Start transmission
txSignal = transmit_start(client, bitsIn);
% Stop transmission
transmit_stop(client);
% Recieve signal
rxSignal = recieve(client);

% Downsample
rxSymbols = rxSignal((span*Rsamp/Rsym)+1:Rsamp/Rsym:(numSymbols+span)*Rsamp/Rsym);
scatterplot(rxSymbols);
% QAM Demodulation
dataSymbolsOut = qamdemod(rxSymbols, M, 'gray', UnitAveragePower=true);
% convert decimal values back to binary
dataOutMatrix = de2bi(dataSymbolsOut, k, 'left-msb');
% reshape binary matrix to a vector
dataOut = dataOutMatrix(:);
% calculate the number of bit errors
numErrors = sum(bitsIn ~= dataOut);
disp(['Number of bit errors: ' num2str(numErrors)])
disp(['Bit error rate: ' num2str(numErrors / numBits)])

% Calculate delay
delay = (length(rrc_filt)-1)/2;
% Trim filtered rxSignal
rxSignal_trimmed = rxSignal(delay+1:end-delay);
% Plot total
figure('Name','Total'), subplot(1,2,1)
pwelch(txSignal,[],[],[],'centered',40e6)
hold on
pwelch(rxSignal,[],[],[],'centered',40e6)
legend("Transmitted", "Recieved");
subplot(1,2,2)
plot((0:length(txSignal)-1)/40, real(txSignal));
hold on
plot((0:length(txSignal)-1)/40, imag(txSignal));
plot((0:length(rxSignal)-1)/40, real(rxSignal));
plot((0:length(rxSignal)-1)/40, imag(rxSignal));
legend("Re(TX)", "Im(TX)", "Re(RX)", "Im(RX)");
title("IQ Data")
grid on
xlabel('Time (us)')