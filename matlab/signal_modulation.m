clear; close all;

% Parameters
M = 16; % modulation order (M-QAM)
k = log2(M); % number of bits per symbol
numSymbols = 100; % number of symbols
numBits = numSymbols*k; % number of bits
SNR = 20; % signal-to-noise ratio in dB
rolloff = 0.25; % RRC roll-off factor
span = 25; % RRC filter transient lenght
Rsamp = 40e6; % sample rate
Rsym = 10e6; % symbol rate
filter = 'yes'; % opt filter 'yes' or 'no'

%% Transmitter

% Generate random binary data
bitsIn = randi([0 1], numBits, 1);

% Reshape data into k-bit symbols for QAM modulation
dataIn = reshape(bitsIn, [], k);

% Convert binary values to decimal values (integers)
decIn = bi2de(dataIn, 'left-msb');

% QAM Modulation
symbols = qammod(decIn, M, 'gray', UnitAveragePower=true);

% observe signals
figure, subplot(1,3,1)
plot((0:length(symbols)-1)/Rsym*1e6, real(symbols))
title('Real')
xlabel('Time (us)')
subplot(1,3,2)
plot((0:length(symbols)-1)/Rsym*1e6, imag(symbols))
title('Imaginary')
xlabel('Time (us)')
subplot(1,3,3)
plot(symbols,'*')
title('Constellation')
axis square, grid on

switch filter
    case 'yes'
        % Create RRC filter
        rrc_filt = rcosdesign(rolloff, span, Rsamp/Rsym,'sqrt');
        figure, subplot(1,2,1)
        pwelch(rrc_filt,[],[],[],'centered',40e6)
        subplot(1,2,2)
        plot((-2*span:2*span)/40,rrc_filt)
        grid on
        xlabel('Time (us)')

        % up-sample
        symbolsUp = upsample(symbols, Rsamp/Rsym);

        % pulse shaping
        txSignal = conv(rrc_filt,symbolsUp);

        figure, subplot(1,2,1)
        pwelch(txSignal,[],[],[],'centered',40e6)
        subplot(1,2,2)
        plot((0:length(txSignal)-1)/40,txSignal)
        grid on
        xlabel('Time (us)')

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

scatterplot(rxSymbols)

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
