function [s, ref] = qpsk_modulator(d)
% Function to QPSK-modulate given data
% d - data to be modulated
% s - modulated signal
% ref - symbol table. represents the reference constellation that can be
% used in demod
bin_str1 = d(1:2:end-1); % Inphase data stream
bin_str2 = d(2:2:end); % Quadrature data stream
% Perform mapping of binary streams to symbols
ind_wave = 2.*bin_str1 + 1.*bin_str2; % Create waveform indices
ref = [exp(1i*(pi/4+3*pi/2)) exp(1i*(pi/4+pi/2)) exp(1i*(pi/4+pi)) exp(1i*(pi/4+0))];

% M-PSK Mapping
s = zeros(1,length(d)/2);
for ind1 = 1:1:4
    indices = find(ind_wave == ind1-1);
    s(indices) = ref(ind1);
end
s = reshape(s, [], 1);
end

