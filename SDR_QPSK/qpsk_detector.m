function bin_str_est = qpsk_detector(received,ref)
% Optimum Detector for 2-dim signals (MPSK) in IQ Plane
% received - vector of form I+jQ
% ref - reference constellation of form I+jQ
% Note: BPSK is one dim. modulation. The same function can be applied with
% quadrature = 0 (Q=0)
% bin_str_est - estimated binary stream
bin_str_est = minEuclideanDistance(received,ref);
end

