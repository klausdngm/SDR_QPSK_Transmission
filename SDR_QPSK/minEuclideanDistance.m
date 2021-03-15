function bin_str_est = minEuclideanDistance(received,ref)
% Function to compute the pairwise minimum Distance between two vectors x
% and y in p-dimensional signal space and select the vectors in y that
% provides the minimum distance
% received - received signal in I+jQ form
% ref - Modulation table
% bin_str_est - estimated binary stream
received = received.';
len = length(received);
% Go through every received waveform and determine Euclidean distance
% between received waveform and the available waveforms
eucl_dist = zeros(4,len);
for ind = 1:1:4
    eucl_dist(ind,1:1:len) = abs(ref(ind).*ones(1,len) - received);
end
% Select shortest Euclidean distance
[mdist,min_ind] = min(eucl_dist);
% Decode into estimated binary streams
X = min_ind-ones(1,len);
bin_str_est = reshape((dec2bin(typecast(X(:),'double'))-'0').',1,[]).';
%bin_str_est = dec2bin(min_ind-ones(1,len)) - '0'; % '0' to get output datatype as 'double' instead of 'char'
%bin_str_est = reshape(bin_str_est,1,[]);
end

