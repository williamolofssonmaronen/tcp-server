function rxSignal = recieve(client)
% Parameters
rolloff = 0.25; % RRC roll-off factor
span = 20; % RRC filter transient lenght
Rsamp = 105e6; % sample rate
Rsym = 5e6; % symbol rate
sps = Rsamp/ Rsym;
SNR = 50;
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

numFloats = read(client,1,'int32');
disp(['Expecting ', num2str(numFloats), ' floats.']);

while (client.NumBytesAvailable == 0)
    pause(0.1);
end
real_data = read(client,numFloats, "single");
% real_data = fread(client, numFloats, 'single');   % 500 floats * 4 bytes
disp('Real part bytes received:');
disp(length(real_data));  % Debug: Show raw byte data

while (client.NumBytesAvailable == 0)
    pause(0.1);
end

imaginary_data = read(client, numFloats, 'single');   % 500 floats * 4 bytes
disp('Imaginary part bytes received:');
disp(length(imaginary_data));

imaginary_data = resample(imaginary_data, 21, 20);
real_data = resample(real_data, 21, 20);

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
    rrc_filt = rcosdesign(rolloff, span, Rsamp/Rsym,"sqrt");
    filter_delay = span * sps / 2;
    rxSignal = conv(rrc_filt,rxSignal);
    rxSignal = rxSignal(filter_delay+1 : end-filter_delay);
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
