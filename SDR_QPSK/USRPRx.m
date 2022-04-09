clear all;
close all;
clc



%% Create message

msg = booktxt();
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
%len = length(bits)/2;


hPSKModTrain = comm.PSKModulator(4, ...
    'PhaseOffset', pi/4, ...
    'SymbolMapping', 'Binary');
xPreamble = hPSKModTrain(preamble);
%% Modulation

% Modulate data to QPSK
M = 4; % Modulation order
%[txData, ref] = qpsk_modulator(bits);
%txData = [xPreamble; txData];
frameLength = 820;
%% Init Rx and Tx
sampleRate = 1e6;
symbolRate = 250e3;
sps = sampleRate/symbolRate;
samplesPerFrame = 120*2;
hRadio                   = comm.SDRuReceiver;
hRadio.Platform          = 'N200/N210/USRP2';
hRadio.TransportDataType = 'int16';
hRadio.OutputDataType    = 'double';
hRadio.IPAddress       = 'put IP here';
hRadio.CenterFrequency = 915e6;
hRadio.SamplesPerFrame   = 20000;
hRadio.ChannelMapping    = 1;
hRadio.Gain = 8;

hRadioInfo = info(hRadio)
ref = [exp(1i*(pi/4+3*pi/2)) exp(1i*(pi/4+pi/2)) exp(1i*(pi/4+pi)) exp(1i*(pi/4+0))];


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
constd6 = comm.ConstellationDiagram('SamplesPerSymbol', 1, ...
    'Name', 'Post Coarse Carrier Sync', 'ReferenceConstellation', ref);
constd5 = comm.ConstellationDiagram('SamplesPerSymbol', 1, ...
    'Name', 'Post SRRC Receive Filter', 'ReferenceConstellation', ref);
%% BER
hErrorRate = comm.ErrorRate;
% Spectrum analyzer    
hSpectrum                           = dsp.SpectrumAnalyzer;
hSpectrum.SampleRate                = hRadioInfo.BasebandSampleRate;
hSpectrum.SpectralAverages          = 10;
hSpectrum.FrequencyResolutionMethod = 'WindowLength';
hSpectrum.WindowLength              = 8192;
hSpectrum.Window                    = 'Kaiser';
hSpectrum.SidelobeAttenuation       = 160;
%% Transmission
L = 4; % oversampling factor (L samples per symbol period)
% Tx filtering
alpha = 0.5;
filterSpan = 8;
[p, t, filtDelay] = srrcFunction(alpha, L, filterSpan); % design filter

% receive Data
% main loop

for iter = 1:100
    
    % Keep accessing the SDRu System object output until it is valid
    len = 0;
    while len <= 0
        [corruptSignal, len, overrun] = hRadio();
        if overrun ~= 0
            fprintf('overrun = %d. ', overrun);
            fprintf('******************************************************\n');
        end
    end
    
    

    hSpectrum(corruptSignal);
%sa(corruptSignal);
% Rx filtering
rxDatafiltered = conv(corruptSignal,p,'full'); % convolve received signal with Rx SRRC filter

% Symbol rate Samples
rxData = rxDatafiltered(filtDelay+1:1:end-filtDelay)/(sqrt(2)*(1/5));
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
BER = hErrorRate(bits,rxDataDemod);
BER(1);
data1 = bits2ASCII(rxDataDemod(1:end-lengthTail), true);
%% View Visuals
if enabled

    %sa(rxCoarse);
    % Pre SRRC Receive filter
    constd(corruptSignal(frameIndex+length(xPreamble)+1:frameIndex+length(xPreamble)+1+length(rxPayload)));
    % Post SRRC Receive filter
    constd5(rxData(frameIndex+length(xPreamble)+1:4:frameIndex+length(xPreamble)+1+length(rxPayload)*4));
    % Post Symbol Synchronisation
    constd3(rxDataTC(frameIndex+length(xPreamble)+1:frameIndex+length(xPreamble)+1+length(rxPayload)));
    % Post Coarse Carrier Sync
    constd6(rxCoarse(frameIndex+length(xPreamble)+1:frameIndex+length(xPreamble)+1+length(rxPayload)));
    % Post Frequency Compensation
    constd4(rxFine(frameIndex+length(xPreamble)+1:frameIndex+length(xPreamble)+1+length(rxPayload)));
    % Final Frame Payload
    constd2(rxPayload);
    
end
end




%% Release Objects
release(hRadio)












