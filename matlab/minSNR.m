function [numErrors] = minSNR(SNR,M)
% PARAMETERS
k = log2(M); % number of bits per symbol
numSymbols = 100; % number of symbols
numBits = numSymbols*k; % number of bits
rolloff = 0.25; % RRC roll-off factor
span = 25; % RRC filter transient lenght
Rsamp = 40e6; % sample rate
Rsym = 10e6; % symbol rate
filter = 'yes'; % opt filter 'yes' or 'no'
% TRANSMITTER
% Generate random binary data
bitsIn = randi([0 1], numBits, 1);
% Reshape data into k-bit symbols for QAM modulation
dataIn = reshape(bitsIn, [], k);
% Convert binary values to decimal values (integers)
decIn = bi2de(dataIn, 'left-msb');
% QAM Modulation
symbols = qammod(decIn, M, 'gray', UnitAveragePower=true);
switch filter
    case 'yes'
        % Create RRC filter
        rrc_filt = rcosdesign(rolloff, span, Rsamp/Rsym,'sqrt');
        % up-sample
        symbolsUp = upsample(symbols, Rsamp/Rsym);
        % pulse shaping
        txSignal = conv(rrc_filt,symbolsUp);
    case 'no'
        txSignal = symbols;
end
%% Receiver
% Add noise
rxSignal = awgn(txSignal, SNR, 'measured');
switch filter
    case 'yes'
        % matched filter
        rxSignal = conv(rrc_filt,rxSignal);
        % downsample
        rxSymbols = rxSignal((span*Rsamp/Rsym)+1:Rsamp/Rsym:(length(symbols)+span)*Rsamp/Rsym);
    case 'no'
        rxSymbols = rxSignal;
end
% QAM Demodulation
dataSymbolsOut = qamdemod(rxSymbols, M, 'gray', UnitAveragePower=true);
% convert decimal values back to binary
dataOutMatrix = de2bi(dataSymbolsOut, k, 'left-msb');
% reshape binary matrix to a vector
dataOut = dataOutMatrix(:);
% calculate the number of bit errors
numErrors = sum(bitsIn ~= dataOut);
end

