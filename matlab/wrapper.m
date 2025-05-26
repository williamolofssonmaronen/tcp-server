%%
clear all; close all;

fs_rx = 105e6;
fs_tx = 100e6;

% SERVER DETAILS
%serverIP = '192.168.50.125'; % Change to the server's IP address
serverIP = "localhost";
serverPort = 8080;    % Change to the server's port

% Create a TCP/IP client
client = tcpclient(serverIP, serverPort);
client.InputBufferSize = 8192;

flush(client);

rolloff = 0.25; % RRC roll-off factor
span = 20; % RRC filter transient lenght
Rsamp = 100e6; % sample rate
Radc = 105e6;
Rsym = 5e6; % symbol rate


sps_rx = fs_rx / Rsym;
sps_tx = fs_tx / Rsym;

% Generate random binary data
M = 16; % modulation order (M-QAM)
k = log2(M); % number of bits per symbol
numSymbols = 10; % number of symbols
numPreambleSymbols = 32;
numBits = numSymbols*k; % number of bits
numPreambleBits = numPreambleSymbols*k;
preamble_bits = randi([0 1], numPreambleBits, 1); % 128 bits = 32 symbols for 16-QAM
%preamble_sym = qam_mod(preamble_bits);

data_bits = randi([0 1], numBits, 1);
bitsIn = [preamble_bits; data_bits];

rrc_filt = rcosdesign(rolloff, span, Radc/Rsym,'sqrt');
rrc_rx = rcosdesign(rolloff, span, sps_rx,'sqrt');

% Start transmission
[txSignal, tx_preamble_waveform] = transmit_start(client, bitsIn);
tx_to_rx = resample(tx_preamble_waveform, fs_rx, fs_tx);
matched_preamble = conv(tx_to_rx, rrc_rx, 'same');
% Stop transmission
transmit_stop(client);
% Recieve signal
rxSignal = recieve(client);

% [corr_vals, lags] = xcorr(rxSignal, matched_preamble);
% [~, max_idx] = max(real(corr_vals));  % or real()
% start_lag = lags(max_idx);
% rx_start = start_lag + length(matched_preamble);

[corr_vals, lags] = xcorr(rxSignal, matched_preamble);
[~, peak_idx] = max(abs(corr_vals));
rx_start = lags(peak_idx) + length(matched_preamble);

if rx_start < length(rxSignal)
    rx_synced = rxSignal(rx_start + 1:end);
    rxSymbols = rx_synced(1:sps_rx:end);
else
    error("Start index too late. No room for data after preamble.");
end

% corr = abs(xcorr(rxSignal, matched_preamble));
% [~, max_idx] = max(corr);
% start_idx = max_idx-length(matched_preamble) + 1;


% Sync and downsample
% rxSignalSynced = rxSignal(start_idx + length(matched_preamble):end);
%rxSymbols = rxSignalSynced((span*Radc/Rsym)+1:Radc/Rsym:(numSymbols+numPreambleSymbols+span)*Radc/Rsym);

% Extract and downsample after preamble
%rxSignalSynced = rx_filtered(start_idx + length(preamble_up_rx):end);
% rxSymbols = rxSignalSynced(1:sps_rx:end);

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
%% Shutdown
write(client, "exit");
response = read(client, client.NumBytesAvailable, 'uint8');
disp(char(response));