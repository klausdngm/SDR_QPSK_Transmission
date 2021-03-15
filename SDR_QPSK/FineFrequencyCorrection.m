function [rxFine] = FineFrequencyCorrection(rxCoarse, M)
% rxCoarse - coarse carrier recovered data
% M - Modulation order
% rxFine - fine carrier recovered data
sps = 1; % 1 cause Decimation took place in the Timing Recovery
DampingFactor = 1.3; NormalizedLoopBandwidth = 0.09;
% Configure LF and PI
LoopFilter = dsp.IIRFilter('Structure', 'Direct Form II transposed', ...
    'Numerator', [1 0], 'Denominator', [1 -1]);
Integrator = dsp.IIRFilter('Structure', 'Direct form II transposed', ...
    'Numerator', [0 1], 'Denominator', [1 -1]);
% Calculate coefficients for FFC
PhaseRecoveryLoopBandwidth = NormalizedLoopBandwidth*sps;
PhaseRecoveryGain = sps;
PhaseErrorDetectorGain = log2(M); DigitalSynthesizerGain = -1;
theta = PhaseRecoveryLoopBandwidth/...
    ((DampingFactor + 0.25/DampingFactor)*sps);
delta = 1 + 2*DampingFactor*theta + theta*theta;
% G1
ProportionalGain = (4*DampingFactor*theta/delta)/...
    (PhaseErrorDetectorGain*PhaseRecoveryGain);
% G3
IntegratorGain = (4/sps*theta*theta/delta)/...
    (PhaseErrorDetectorGain*PhaseRecoveryGain);
% Correct carrier offset
output = zeros(size(rxCoarse));
Phase = 0; previousSample = complex(0);
LoopFilter.release(); Integrator.release();

%-----------PLL------------
for k = 1:length(rxCoarse)-1
    % Complex phase shift
    output(k) = rxCoarse(k+1)*exp(1i*Phase);
    % PED
    phErr = sign(real(previousSample)).*imag(previousSample)...
        - sign(imag(previousSample)).*real(previousSample);
    % Loop filter
    loopFiltOut = step(LoopFilter, phErr*IntegratorGain);
    % Direct Digital Synthesizer
    DDSOut = step(Integrator, phErr*ProportionalGain + loopFiltOut);
    Phase = DigitalSynthesizerGain * DDSOut;
    previousSample = output(k);
end

rxFine = output;
end








