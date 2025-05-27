function [txSignal,tx_preamble_waveform, tx_payload_waveform] = transmit_start(client, bitsIn)
% PARAMETERS
M = 16; % Modulation order
rolloff = 0.25; % RRC roll-off factor
span = 20; % RRC filter transient lenght
Rsamp = 100e6; % sample rate
Rsym = 5e6; % symbol rate
filter = 'yes'; % opt filter 'yes' or 'no'
plotting = 'yes'; % opt plot 'yes' or 'no'
sps = Rsamp/ Rsym;


% Generate random binary data
M = 16; % modulation order (M-QAM)
k = log2(M); % number of bits per symbol
numSymbols = 40; % number of symbols
numPreambleSymbols = 10;
numBits = numSymbols*k; % number of bits
numPreambleBits = numPreambleSymbols*k;

% Modulate signal
k = log2(M);
% Reshape data into k-bit symbols for QAM modulation

% preamble_bits = bitsIn(1:numPreambleBits);
% payload_bits = bitsIn(numPreambleBits+1:end);

dataIn = reshape(bitsIn, [], k);
% preamble_bits_reshaped = reshape(preamble_bits, [], k);
% payload_bits_reshaped = reshape(payload_bits, [], k);

% Convert binary values to decimal values (integers)
decIn = bi2de(dataIn, 'left-msb');
% dec_preamble = bi2de(preamble_bits_reshaped, 'left-msb');
% dec_payload = bi2de(payload_bits_reshaped, 'left-msb');
% QAM Modulation
symbols = qammod(decIn, M, 'gray', UnitAveragePower=true);
% preamble_sym = qammod(dec_preamble, M, 'gray', UnitAveragePower=true);
load("mats/pilot_sequence.mat");
preamble_sym = pilotSeq;
% payload_sym = qammod(dec_payload, M, 'gray', UnitAveragePower=true);

switch filter
    case 'yes'
        % % up-sample
        % symbolsUp = upsample([symbols; preamble_sym], Rsamp/Rsym);
        % preamble_upsampled = upsample(preamble_sym, Rsamp/Rsym);
        % % pulse shaping
        % txSignal = conv(rrc_filt,symbolsUp);
        % tx_preamble_waveform = conv(rrc_filt,preamble_upsampled);
        % % tx_preamble_waveform = upfirdn(preamble_sym, rrc_filt, Rsamp/Rsym, 1);
        % % tx_payload_waveform = upfirdn(payload_sym, rrc_filt, Rsamp/Rsym, 1);
        % tx_payload_waveform = upfirdn(symbols, rrc_filt, Rsamp/Rsym, 1);

        % Create RRC filter
        rrc_filt = rcosdesign(rolloff, span, Rsamp/Rsym,"sqrt");
        filter_delay = span * sps / 2;

        % Separate preamble and payload upsampling
        preamble_upsampled = upsample(preamble_sym, sps);
        payload_upsampled = upsample(symbols, sps);
    
        % Apply pulse shaping
        tx_preamble_waveform = conv(preamble_upsampled, rrc_filt);  % Full waveform
        tx_payload_waveform = conv(payload_upsampled, rrc_filt);
    
        % Remove filter delay (optional: keep for alignment purposes)
        tx_preamble_waveform = tx_preamble_waveform(filter_delay+1 : end-filter_delay);
        tx_payload_waveform = tx_payload_waveform(filter_delay+1 : end-filter_delay);
    
        % Concatenate full signal
        txSignal = [tx_preamble_waveform; tx_payload_waveform];

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

% flush(client);

write(client, int32(length(txSignal)));
write(client, single(imag(txSignal)));
write(client, single(real(txSignal)));

%single(txSignal)
%response = read(client, client.NumBytesAvailable, 'uint8');

%write(client, double(txSignal));

end

