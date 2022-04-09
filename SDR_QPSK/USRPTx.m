clear all;
close all;
clc
%% Create message

msg = 'Hello World!';
msg_length = length(msg);
% Generate Barker Code for Preamble
barker = comm.BarkerCode('SamplesPerFrame', 28, 'Length', 13);
preamble = barker()+1;
release(barker);
% barker = [+1 +1 +1 +1 +1 +1 +1 +1 +1 +1 0 0 0 0 +1 +1 +1 +1 0 0 +1 +1 0 0 +1 +1];
% barkerlength = length(barker);
% headerlength = barkerlength*2;

% Convert message to bits
bits = ASCII2bits(msg);
tail = zeros(100,1);
lengthTail = length(tail);
bits = [bits; tail];
len = length(bits)/2;

hPSKModTrain = comm.PSKModulator(4, ...
    'PhaseOffset', pi/4, ...
    'SymbolMapping', 'Binary');
xPreamble = hPSKModTrain(preamble);
%% Modulation

% Modulate data to QPSK
M = 4; % Modulation order
[txData, ref] = qpsk_modulator(bits);
txData = [xPreamble; txData];
frameLength = length(txData);
%% Init Rx and Tx
sampleRate = 1e6;
symbolRate = 250e3;
sps = sampleRate/symbolRate;
samplesPerFrame = length(txData)*2;
hRadioTx                     = comm.SDRuTransmitter;
hRadioTx.Platform            = 'N200/N210/USRP2';
hRadioTx.IPAddress            = 'put IP here';
hRadioTx.ChannelMapping      = 1;


%% Transmission

% Upsampling
L = 4; % oversampling factor (L samples per symbol period)
txData = txData(:).';
txDataUp = [txData;zeros(L-1, length(txData))];
txDataUp = txDataUp(:).'; % Convert to single stream

% Tx filtering
alpha = 0.5;
filterSpan = 8;
[p, t, filtDelay] = srrcFunction(alpha, L, filterSpan); % design filter
txDatafiltered = conv(txDataUp, p, 'full'); % Convolve modulated symbols with p[n] filter

% transmit Data
% main loop
for iter = 1:1e9

    % Use USRP radio to tx one frame of complex baseband I/Q samples.
    underrun = hRadioTx(txDatafiltered.');
    if underrun ~= 0
        fprintf('undderrun = %d.\n', underrun);
    end
    
end

release(hRadioTx)








