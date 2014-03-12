% Generates a linear sweep (Optimized Aoshima Time Streteched Pulse)
% and its inverse for IR measurement,
% based on the concepts in:
% 
% Yôiti Suzuki, Futoshi Asano, Hack-Yoon Kim, Toshio Sone (1995)
% "An optimum computer-generated pulse signal suitable for the measurement 
% of very long impulse responses"
% Journal of the Acoustical Society of America 97(2):1119-1123
%
% code by Densil Cabrera
% version 0 (beta) 11 March 2013

function OUT = OATSP(dur,m,fs)


if nargin == 0
    param = inputdlg({'Duration [s]';...
                       'm (positive integer)';...
                       'Sampling Frequency [samples/s]'},...
                       'Sine sweep input parameters',1,{'1';'1200';'48000'});
    param = str2num(char(param));
    if length(param) < 3, param = []; end
    if ~isempty(param)
        dur = param(1);
        m = param(2);
        fs = param(3);
    end   
else
    param = [];
end
if ~isempty(param) || nargin ~=0
    if ~exist('fs','var')
       fs = 48000;
    end
    
    
    N = 2*ceil(dur * fs/2);
    m = (N*m)/2;
    k = (0:N/2)';
    Hlow = exp(1i * 4 * m * pi * k.^2 ./ N.^2);
    H = [Hlow;conj(flipud(Hlow(2:end)))];
    Sinv = ifft(H);
    Sinv = circshift(Sinv,-round(N/2-m));
    
    S = flipud(Sinv);

    OUT.audio = S;
    OUT.audio2 = Sinv;
    OUT.fs = fs;
    OUT.tag = ['OATS' num2str(dur)];
else
    OUT = [];
end