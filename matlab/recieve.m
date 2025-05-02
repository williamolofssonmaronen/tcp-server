function [rxSignal] = recieve(client)
% Parameters
rolloff = 0.25; % RRC roll-off factor
span = 25; % RRC filter transient lenght
Rsamp = 40e6; % sample rate
Rsym = 10e6; % symbol rate
SNR = 20;
plotting = 'yes';
noise = true;
filter = true;

% Signal the server to recieve
write(client, "recieve");

while (client.NumBytesAvailable == 0)
    pause(0.1);
end
response = read(client, 18, 'uint8');
disp(char(response));

while (client.NumBytesAvailable == 0)
    pause(0.1);
end

% Read header: the number of floats to expect (int32)
%numBytes = read(client, 4, "uint8");
%numFloats = typecast(uint8(numBytes), 'int32');
%disp(['Expecting ', num2str(numFloats), ' floats.']);

numFloats = fread(client,1,'int32');

while (client.NumBytesAvailable == 0)
    pause(0.1);
end

real_data = fread(client, numFloats, 'single');   % 500 floats * 4 bytes
disp('Real part bytes received:');
disp(length(real_data));  % Debug: Show raw byte data

while (client.NumBytesAvailable == 0)
    pause(0.1);
end

imaginary_data = fread(client, numFloats, 'single')   % 500 floats * 4 bytes
disp('Imaginary part bytes received:');
disp(length(imaginary_data));

% Convert into complex vecotr
rxSignal = complex(real_data, imaginary_data);
% Convert single point float to double
rxSignal = double(rxSignal);

% Add noise
if noise
    rxSignal = awgn(rxSignal, SNR, 'measured');
end

% Matched filter

if filter
    rrc_filt = rcosdesign(rolloff, span, Rsamp/Rsym,'sqrt');
    rxSignal = conv(rrc_filt,rxSignal);
end

switch plotting
    case 'yes'
        figure('Name','Reciever'), subplot(1,2,1)
        pwelch(rxSignal,[],[],[],'centered',40e6)
        subplot(1,2,2)
        plot((0:length(rxSignal)-1)/40, real(rxSignal),"b");
        hold on
        plot((0:length(rxSignal)-1)/40, imag(rxSignal),"g");
        legend("In-phase", "Quadrature");
        title("IQ Data")
        grid on
        xlabel('Time (us)')
    case 'no'
end

% downsample
%rxSymbols = rxSignal((span*Rsamp/Rsym)+1:Rsamp/Rsym:(length(symbols)+span)*Rsamp/Rsym);\

end

