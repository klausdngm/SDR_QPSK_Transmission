function output = GardnerQPSK(received, sps)
Tsym = 100;
Up = 100/sps; % bring data up from sps to 100
N = floor(length(received)/sps); % Amount of data
p = sin(2*pi*(0:Tsym-1)/(2*Tsym)); % Sinusoidal wave
data_up =  zeros(1,length(received)*Up); % Preallocating memory
data_up(1:Up:end) = received; % Interpolation of data
S11 = conv(data_up,p); % convolve
S1 = S11(1:end-Tsym+1); % Remove last bits due to convolution
% Conversion complex No. to normal No.
Sreal = real(S1);
Simag = imag(S1);
% Detection and correction
tau = 0;                        % Initial value for tau
delta = Tsym/2;                 % The shifting value before and after the midway sample
center = 60;                    % The assumed place for the first midway sample
a1 = zeros(1,N-1);
a2 = zeros(1,N-1);
cenpoint = zeros(1,N-1);
remind = zeros(1,N-1);
avgsamples = 6;                 % Six values of Gardner algorithm are used to find the average
stepsize = 1;                   % Correction step size
rit = 0;                        % Iteration counter
GA = zeros(1,avgsamples);
tauvector = zeros(1,2000-Tsym);
uor = 0;                        % A counter for tauvector
a = zeros(1,N-1);
for ii = delta+1:Tsym:N*Tsym-delta
    rit = rit+1;                        % A counter   
    % Sampling the real part
    midsample1 = Sreal(center);         % Midway Sample
    latesample1 = Sreal(center+delta);  % Late Sample
    earlysample1 = Sreal(center-delta); % Early Sample
    a1(rit) = earlysample1;             % Save samples
    % Sampling the imaginary part
    midsample2 = Simag(center);         % Midway Sample
    latesample2 = Simag(center+delta);  % Late Sample
    earlysample2 = Simag(center-delta); % Early Sample
    a2(rit) = earlysample2;             % Save samples 
    % Error detection
    sub1 = latesample1-earlysample1;
    sub2 = latesample2-earlysample2;
    GA(mod(rit,avgsamples)+1) = sub1*midsample1+sub2*midsample2; % Gardner algorithm 
    % Loop filter
    if mean(GA) > 0
        tau = -stepsize;
    elseif mean(GA) < 0
        tau = stepsize;
    else 
        tau = 0;
    end 
    % Save remind values
    cenpoint(rit) = center;                     % Save positions of midway samples
    remind(rit) = rem((center-Tsym/2),Tsym);    % Save remind values to find convergence plots
    % tau vector
    if rit>=100 && rit<2000                     % Tau vector from 100 to 2000
        uor = uor+1;                            % where the convergence happens
        tauvector(uor) = (remind(rit) - (Tsym/2)).^2; % Difference between remind and Tsym
    end
    % Correction
    center = center+Tsym+tau;       % Adding the tau value
    if center >= N*Tsym-(Tsym/2)-1  % Break the loop when the midway sample
                                    % reach to position 51 before the last
                                    % sample
        break;
    end
end
% Mean Squared Error (MSE)
MSE = mean(tauvector);
% Combining all bits
for df=1:(N-1)
    a(df) = [a1(df)+a2(df)*1i]; % Combine bits to create complex numbers
end
output = reshape(a, [], 1)./2;
end













