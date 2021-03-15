function [outputArg1,outputArg2] = SymbolSync(y)

%% Interpolation filter
% Define interpolator coefficients
alpha = 0.5;
InterpFilterCoeff = ...
    [ 0,        0,        1,         0;      % Constant
    -alpha,  1+alpha, -(1-alpha), -alpha;    % Linear
    alpha,    -alpha,   -alpha,    alpha];   % Quadratic
% Filter input data
ySeq = [y(i); InterpFilterState]; % Update delay line
% Produce filter output
filtOut = sum((InterpFilterCoeff * ySeq) .* [1; mu; mu^2]);
InterpFilterState = ySeq(1:3); % Save filter input data

%% zcTED
% ZC-TED calculation occurs on a strobe
if Trigger && all(~TriggerHistory(2:end))
    % Calculate the midsample point for odd or even samples per symbol
    t1 = TEDBuffer(end/2 + 1 - rem(N,2));
    t2 = TEDBuffer(end/2 + 1);
    midSample = (t1+t2)/2;
    e = real(midSample)*(sign(real(TEDBuffer(1)))-sign(real(filtOut)))...
        imag(midSample)*(sign(imag(TEDBuffer(1)))-sign(imag(filtOut)));
else
    e = 0;
end

% Update TED buffer to manage symbol stuffs
switch sum([TriggerHistory(2:end), Trigger])
    case 0
        % No update required
    case 1
        % Shift TED buffer regularly if ONE trigger across N samples
        TEDBuffer = [TEDBuffer(2;end), filtOut];
    otherwise % > 1
        % Stuff a missing sample if 2 triggers across N samples
        TEDBuffer = [TEDBuffer(3:end), 0, filtOut];
end

%% Loop filter
loopFiltOut = LoopPreviousInput + LoopFilterState;
g = e*ProportionalGain + loopFiltOut; % Filter error signal
LoopFilterState = loopFiltOut;
LoopPreviousInput = e*IntegratorGain;
% Loop filter ( alternative with filter objects)
lf = dsp.BiquadFilter('SOSMatrix',tf2sos([1 0],[1 -1])); % Create filter
g = lf(IntegratorGain*e) + ProportionalGain*e; % Filter error signal



%% Interpolation Control
% Interpolation Controller with modulo-1 counter
d = g + 1/N;
TriggerHistory = [TrigerHistory(2:end), Trigger];
Trigger = (Counter < d); % Check if a trigger condition
if Trigger % Update mu if a trigger
    mu = Counter / d;
end
Counter = mod(Counter - d, 1); % Update counter
        
        
        
        
        
        
    


end

