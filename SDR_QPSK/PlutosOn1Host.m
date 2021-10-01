clear all;
close all;
clc
%% Create message

msg = booktxt();
msg_length = length(msg);
% Generate Barker Code for Preamble
barker = [+1 +1 +1 +1 +1 +1 +1 +1 +1 +1 1 0 1 0 +1 +1 +1 +1 1 0 +1 +1 1 0 +1 +1];
barker = barker.';

% Convert message to bits
bits = ASCII2bits(msg);
tail = zeros(10,1);
lengthTail = length(tail);
bits = [barker; bits; tail];

%% Modulation

% Modulate data to QPSK
M = 4; % Modulation order
[txData, ref] = qpsk_modulator(bits);
%txData = [barker; txData];
frameLength = length(txData);
% get modulated Preamble for frame detection algorithm
xPreamble = txData(1:13);
%% Init Rx and Tx
sampleRate = 1e6;
symbolRate = 250e3;
sps = sampleRate/symbolRate;
samplesPerFrame = length(txData)*2;
centerFrequency = 915e6;
gain = 0;
tx = sdrtx('Pluto', 'RadioID', 'usb:0', 'CenterFrequency', centerFrequency);
rx = sdrrx('Pluto', 'RadioID', 'usb:1', 'OutputDataType', 'double', 'CenterFrequency', centerFrequency);


%% Visuals
enabled = true;
constd = comm.ConstellationDiagram('SamplesPerSymbol', 1, ...
    'Name', 'Pre SRRC Receive Filter', 'ReferenceConstellation', ref);
constd2 = comm.ConstellationDiagram('SamplesPerSymbol', 1, ...
    'Name', 'Final Frame', 'ReferenceConstellation', ref);
constd3 = comm.ConstellationDiagram('SamplesPerSymbol', 1, ...
    'Name', 'Post Symbol Sync (Gardner Algorithm)', 'ReferenceConstellation', ref);
constd4 = comm.ConstellationDiagram('SamplesPerSymbol', 1, ...
    'Name', 'Post Fine Carrier Sync', 'ReferenceConstellation', ref);
constd5 = comm.ConstellationDiagram('SamplesPerSymbol', 1, ...
    'Name', 'Post SRRC Receive Filter', 'ReferenceConstellation', ref);
constd6 = comm.ConstellationDiagram('SamplesPerSymbol', 1, ...
    'Name', 'Post Coarse Carrier Sync', 'ReferenceConstellation', ref);
hSpectrum                           = dsp.SpectrumAnalyzer;
hSpectrum.SampleRate                = symbolRate;
hSpectrum.SpectralAverages          = 10;
hSpectrum.FrequencyResolutionMethod = 'WindowLength';
hSpectrum.WindowLength              = 8192;
hSpectrum.Window                    = 'Kaiser';
hSpectrum.SidelobeAttenuation       = 160;
%sa = dsp.SpectrumAnalyzer('SampleRate', symbolRate);

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

for ix=1:10
% transmit Data
transmitRepeat(tx, txDatafiltered.');
for i = 1:5
    rxSig = rx();
end

% Rx filtering
rxDatafiltered = conv(rxSig,p,'full'); % convolve received signal with Rx SRRC filter

% Symbol rate Samples
rxData = rxDatafiltered(filtDelay+1:1:end-filtDelay)/sqrt(2);
% Correction of filter delay and amplitude through Tx and Rx filter

%% Symbol timing recovery
rxDataTC = GardnerQPSK(rxData,sps);

%% Coarse carrier frequency correction
[rxCoarse, estFreqOff] = CoarseFrequencyCorrection(rxDataTC, sampleRate, M);

%% Fine carrier frequency correction
rxFine = FineFrequencyCorrection(rxCoarse, M);
%% Frame synchronisation
[frame, frameIndex] = FindFrameStart(rxFine, xPreamble, frameLength);
if isempty(frame)
    warning('No frame found, skipping');
end
rxPayload = frame(length(xPreamble)+1:end);

% Demodulate
rxDataDemod = qpsk_detector(rxPayload, ref);
data1 = bits2ASCII(rxDataDemod(1:end-lengthTail), true);
%% View Visuals
if enabled
    hSpectrum(txDataUp.');
    %sa(rxCoarse);
    % Pre SRRC Receive filter
    constd(rxSig(frameIndex+length(xPreamble)+1:frameIndex+length(xPreamble)+1+length(rxPayload)));
    % Post SRRC Receive filter
    constd5(rxData(frameIndex+length(xPreamble)+1:4:frameIndex+length(xPreamble)+1+length(rxPayload)*4));
    % Post Symbol Synchronisation
    constd3(rxDataTC(frameIndex+length(xPreamble)+1:frameIndex+length(xPreamble)+1+length(rxPayload)));
    % Post Frequency Compensation
    constd4(rxFine(frameIndex+length(xPreamble)+1:frameIndex+length(xPreamble)+1+length(rxPayload)));
    constd6(rxCoarse(frameIndex+length(xPreamble)+1:frameIndex+length(xPreamble)+1+length(rxPayload)));
    % Final Frame Payload
    constd2(rxPayload);
    
end
end
%% Release Objects
release(tx)
release(rx)






