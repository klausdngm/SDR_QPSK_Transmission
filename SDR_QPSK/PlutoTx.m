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
centerFrequency = 2.4e9;
gain = 0;
tx = sdrtx('Pluto');


%% Visuals
% enabled = true;
% constd = comm.ConstellationDiagram('SamplesPerSymbol', 1, ...
%     'Name', 'Pre SRRC Receive Filter', 'ReferenceConstellation', ref);
% constd2 = comm.ConstellationDiagram('SamplesPerSymbol', 1, ...
%     'Name', 'Final Frame', 'ReferenceConstellation', ref);
% constd3 = comm.ConstellationDiagram('SamplesPerSymbol', 1, ...
%     'Name', 'Post Symbol Sync (Gardner Algorithm)', 'ReferenceConstellation', ref);
% constd4 = comm.ConstellationDiagram('SamplesPerSymbol', 1, ...
%     'Name', 'Post Fine Carrier Sync', 'ReferenceConstellation', ref);
% constd5 = comm.ConstellationDiagram('SamplesPerSymbol', 1, ...
%     'Name', 'Post SRRC Receive Filter', 'ReferenceConstellation', ref);
% constd6 = comm.ConstellationDiagram('SamplesPerSymbol', 1, ...
%     'Name', 'Post Coarse Carrier Sync', 'ReferenceConstellation', ref);
% sa = dsp.SpectrumAnalyzer('SampleRate', symbolRate);

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
transmitRepeat(tx, txDatafiltered.');
% for i = 1:5
%     rxSig = rx();
% end

% Rx filtering
%rxDatafiltered = conv(rxSig,p,'full'); % convolve received signal with Rx SRRC filter

% Symbol rate Samples
%rxData = rxDatafiltered(filtDelay+1:1:end-filtDelay)/sqrt(2);
% Correction of filter delay and amplitude through Tx and Rx filter

%% Symbol timing recovery
%rxDataTC = GardnerQPSK(rxData,sps);

%% Coarse carrier frequency correction
%[rxCoarse, estFreqOff] = CoarseFrequencyCorrection(rxDataTC, sampleRate, M);

%% Fine carrier frequency correction
%rxFine = FineFrequencyCorrection(rxCoarse, M);
%% Frame synchronisation
%[frame, frameIndex] = FindFrameStart(rxFine, xPreamble, frameLength);
% if isempty(frame)
%     warning('No frame found, skipping');
% end
%rxPayload = frame(length(xPreamble)+1:end);

% Demodulate
%rxDataDemod = qpsk_detector(rxPayload, ref);
%data1 = bits2ASCII(rxDataDemod(1:end-lengthTail), true);
%% View Visuals
% if enabled
%     sa(rxSig);
%     %sa(rxCoarse);
%     % Pre SRRC Receive filter
%     constd(rxSig(frameIndex+length(xPreamble)+1:frameIndex+length(xPreamble)+1+length(rxPayload)));
%     % Post SRRC Receive filter
%     constd5(rxData(frameIndex+length(xPreamble)+1:4:frameIndex+length(xPreamble)+1+length(rxPayload)*4));
%     % Post Symbol Synchronisation
%     constd3(rxDataTC(frameIndex+length(xPreamble)+1:frameIndex+length(xPreamble)+1+length(rxPayload)));
%     % Post Frequency Compensation
%     constd4(rxFine(frameIndex+length(xPreamble)+1:frameIndex+length(xPreamble)+1+length(rxPayload)));
%     constd6(rxCoarse(frameIndex+length(xPreamble)+1:frameIndex+length(xPreamble)+1+length(rxPayload)));
%     % Final Frame Payload
%     constd2(rxPayload);
%     
% end

%% Release Objects
release(tx)
%release(rx)









