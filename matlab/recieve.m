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
%while t.NumBytesAvailable == 0
%    pause(0.1);
%end

pause(0.5);
response = read(client, 18, 'uint8');
disp(char(response));

pause(0.5);
real_data = fread(client, 500, 'single');   % 500 floats * 4 bytes
disp('Real part bytes received:');
%disp(real_bytes);  % Debug: Show raw byte data

pause(0.5);
imaginary_data = fread(client, 500, 'single');   % 500 floats * 4 bytes
disp('Imaginary part bytes received:');
%disp(imaginary_bytes);

% Convert into complex vecotr
rxSignal = complex(real_data, imaginary_data);
% Convert single point float to double
rxSignal = double(rxSignal);

% matched filter
rrc_filt = rcosdesign(rolloff, span, Rsamp/Rsym,'sqrt');
rxSignal = conv(rrc_filt,rxSignal);
% downsample
%rxSymbols = rxSignal((span*Rsamp/Rsym)+1:Rsamp/Rsym:(length(symbols)+span)*Rsamp/Rsym);\
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
end

