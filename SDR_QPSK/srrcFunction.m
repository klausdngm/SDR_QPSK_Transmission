function [p,t,filtDelay] = srrcFunction(alpha, L, filterSpan)
% Function for generating square-root raised-cosine (SRRC) pulse
% alpha - roll-off factor of SRRC pulse
% L - oversampling factor (number of samples per symbol)
% filterSpan - filter span in symbols
% Returns the output pulse p(t) that spans the discrete-time base
% -filterSpan:1/L:filterSpan. Also returns the filter delay when the
% function is viewed as an FIR filter
Tsym = 1; t = - (filterSpan/2):1/L:(filterSpan/2); % unit symbol duration time-base
numerator = sin(pi*t*(1-alpha)/Tsym)+...
    ((4*alpha*t/Tsym).*cos(pi*t*(1+alpha)/Tsym));
denominator = pi*t.*(1-(4*alpha*t/Tsym).^2)/Tsym;
p = 1/sqrt(Tsym)*numerator./denominator; % srrc pulse definition
% handle catch corner cases (singularities)
p(ceil(length(p)/2)) = 1/sqrt(Tsym)*((1-alpha)+4*alpha/pi);
temp = (alpha/sqrt(2*Tsym))*((1+2/pi)*sin(pi/(4*alpha))...
    + (1-2/pi)*cos(pi/(4*alpha)));
p(t==Tsym/(4*alpha))=temp; p(t==-Tsym/(4*alpha))=temp;
% FIR filter delay = (N-1)/2, N = length of the filter
filtDelay = (length(p)-1)/2; % FIR filter delay
end
