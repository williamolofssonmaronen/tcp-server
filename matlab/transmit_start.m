function [txSignal,tx_preamble_waveform] = transmit_start(client, bitsIn)
% PARAMETERS
M = 16; % Modulation order
rolloff = 0.25; % RRC roll-off factor
span = 20; % RRC filter transient lenght
Rsamp = 100e6; % sample rate
Rsym = 5e6; % symbol rate
filter = 'yes'; % opt filter 'yes' or 'no'
plotting = 'yes'; % opt plot 'yes' or 'no'

% Generate random binary data
M = 16; % modulation order (M-QAM)
k = log2(M); % number of bits per symbol
numSymbols = 40; % number of symbols
numPreambleSymbols = 32;
numBits = numSymbols*k; % number of bits
numPreambleBits = numPreambleSymbols*k;

% Modulate signal
k = log2(M);
% Reshape data into k-bit symbols for QAM modulation

preamble_bits = bitsIn(1:numPreambleBits);

% dataIn = reshape(bitsIn, [], k);
dataIn = reshape(bitsIn, [], k);
preamble_bits_reshaped = reshape(preamble_bits, [], k);

% Convert binary values to decimal values (integers)
decIn = bi2de(dataIn, 'left-msb');
dec_preamble = bi2de(preamble_bits_reshaped, 'left-msb');
% QAM Modulation
symbols = qammod(decIn, M, 'gray', UnitAveragePower=true);
preamble_sym = qammod(dec_preamble, M, 'gray', UnitAveragePower=true);


switch filter
    case 'yes'
        % Create RRC filter
        rrc_filt = rcosdesign(rolloff, span, Rsamp/Rsym,'sqrt');
        % up-sample
        symbolsUp = upsample(symbols, Rsamp/Rsym);
        % pulse shaping
        txSignal = conv(rrc_filt,symbolsUp);
        tx_preamble_waveform = upfirdn(preamble_sym, rrc_filt, Rsamp/Rsym, 1);
    case 'no'
        txSignal = symbols;
end

switch plotting
    case 'yes'
        figure('Name','Transmitter'), subplot(1,2,1)
        pwelch(txSignal,[],[],[],'centered',40e6)
        subplot(1,2,2)
        plot((0:length(txSignal)-1)/40, real(txSignal),"b");
        hold on
        plot((0:length(txSignal)-1)/40, imag(txSignal),"g");
        legend("In-phase", "Quadrature");
        title("IQ Data")
        grid on
        xlabel('Time (us)')
    case 'no'
end
write(client, "transmit");

while (client.NumBytesAvailable == 0)
    pause(0.1);
end
response = read(client, client.NumBytesAvailable, 'uint8');
disp(char(response));

write(client, int32(length(txSignal)));

write(client, single(imag(txSignal)));
write(client, single(real(txSignal)));

%single(txSignal)
%response = read(client, client.NumBytesAvailable, 'uint8');

%write(client, double(txSignal));

end

