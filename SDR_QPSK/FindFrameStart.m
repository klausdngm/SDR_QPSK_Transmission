
function [frame,ind] = FindFrameStart(signal, xPreamble, frameLength)

preambleLength = length(xPreamble);

%% Filter Method
% %Using Filter method with time reversal, therefore we need to reverse
% %order of xPreamble
% % % Estimate start of frame
% cor = abs(filter(xPreamble(end:-1:1).',1,signal));
% cor(1:preambleLength) = 0;% Remove invalid positions
% [pks,ind] = findpeaks(cor(1:end-frameLength),'SortStr', 'descend');

%% Cross Correlation method
% CorssCorr method without time reversal but with zero padding to bring
% xPreamble and signal to an even length, leads to Zero lag
cor = abs(xcorr(signal, xPreamble));
% get local Maxima and sort in descending order
[pks,locs] = findpeaks(cor(1:end-frameLength),'SortStr', 'descend');
numZeros = length(signal) - preambleLength;
ind = locs - numZeros;
% Estimation of peak position
% The correlation sequence should be 2*L-1, where L is the length of the
% longest of the two sequences
%
% The first N-M will be zeros, where N is the length of the long sequence
% and N is the length of the shorter sequence
%
% The peak itself will occur at zero lag, or when they are directly
% overlapping, resulting in a peak in the middle sample in correlation

% Correct to edge of preamble
ind = ind(1) - preambleLength;
frame = signal(ind+1:ind+frameLength); % Includes preamble
% Compensating for the phase offset, Get orientation
phaseEst = round(angle(mean(conj(xPreamble) .* frame(1:preambleLength)))*2/pi)*(pi/2);
frame = frame .* exp(-1i*phaseEst);


end