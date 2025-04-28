function [] = transmit_stop(client)
    write(client, "stop");
    pause(0.5);
    response = read(client, client.NumBytesAvailable, 'uint8');
    disp(char(response));
end

