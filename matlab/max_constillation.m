clear; close all; clc;
M=[2^1 2^2 2^3 2^4 2^5 2^6 2^7 2^8 2^9 2^10 2^11 2^12 2^13 2^14];
constillation_max(:,1) = M;
index = 1;
while index <= length(M)
    for SNR=80:-1:-40
        if minSNR(SNR,M(index)) > 0
            break
        end
    end
    constillation_max(index,2) = SNR;
    index = index + 1;
end
disp(constillation_max)