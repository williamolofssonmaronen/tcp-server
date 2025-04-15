function [] = recieve(client, bitsIn)
% Parameters
M = 16; % modulation order (M-QAM)
k = log2(M); % number of bits per symbol
numSymbols = 100; % number of symbols
numBits = numSymbols*k; % number of bits
rolloff = 0.25; % RRC roll-off factor
span = 25; % RRC filter transient lenght
Rsamp = 40e6; % sample rate
Rsym = 10e6; % symbol rate


% signal the server to recieve
write(client, "recieve");
% Wait until data is available
while t.NumBytesAvailable == 0
    pause(0.1);
end

% Read raw bytes
numFloats = 500;  % you should know this ahead of time or send it first
rawData = read(client, numFloats * 4, 'uint8');

% Convert raw bytes to float (single precision)
rxSignal = typecast(uint8(rawData), 'single');
% Convert single point float to double
rxSignal = double(rxSignal);

% matched filter
rrc_filt = rcosdesign(rolloff, span, Rsamp/Rsym,'sqrt');
rxSignal = conv(rrc_filt,rxSignal);
% downsample
rxSymbols = rxSignal((span*Rsamp/Rsym)+1:Rsamp/Rsym:(length(symbols)+span)*Rsamp/Rsym);
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
end

