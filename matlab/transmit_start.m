function [txSignal] = transmit_start(client, bitsIn)
% PARAMETERS
M = 16; % Modulation order
numSymbols = 100; % Number of symbols
rolloff = 0.25; % RRC roll-off factor
span = 25; % RRC filter transient lenght
Rsamp = 40e6; % sample rate
Rsym = 10e6; % symbol rate
filter = 'yes'; % opt filter 'yes' or 'no'
plotting = 'yes'; % opt plot 'yes' or 'no'
% Modulate signal
k = log2(M);
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
write(client, single(imag(txSignal)));
write(client, single(real(txSignal)));

%single(txSignal)
%response = read(client, client.NumBytesAvailable, 'uint8');

%write(client, double(txSignal));

end

