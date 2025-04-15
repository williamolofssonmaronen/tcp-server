function [] = transmit_stop(client)
    write(client, "stop");
end

