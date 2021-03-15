function [rxCoarse, estFreqOff] = CoarseFrequencyCorrection(rxDataTC, sampleRate, M)
% Coarse Frequency Correction for Carrier Recovery
% sampleRate - samplerate of the system
% M - modulation order
% rxDataTC - already timing recovered data on Rx side
% rxCoarse - coarse carrier recovered data
% estFreqOff - Estimate of carrier offset between 2 radios 
fftOrder = 2^12; % FFT Order 
% Get rxData bins of FFT Length
rxDataTCFFT = rxDataTC(1:fftOrder);
indexToHz = sampleRate/(M*fftOrder);
% Remove modulation effects
sigNoMod = rxDataTCFFT.^M;
% Take FFT and abs
freqHist = abs(fft(sigNoMod));
% Determine most likely offset
[~, maxInd] = max(freqHist);
offsetInd = maxInd - 1;
if maxInd >= fftOrder/2 % Compensate spectrum shift
    offsetInd = offsetInd - fftOrder;
end
% Convert to Hz from normalized frequency
estFreqOff = offsetInd * indexToHz;
% Remove offset    
t = (0:1/sampleRate:(length(rxDataTC)-1)/sampleRate).';
rxCoarse = rxDataTC.*exp(-1i.*2.*pi.*estFreqOff.*t);
end

