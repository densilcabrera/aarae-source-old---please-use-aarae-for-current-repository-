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
    
    
    N = round(dur * fs);
    k = (1:N)';
    Hlow = exp(1i * 4 * m * pi * k(k<=N/2).^2 ./ N.^2);
    if mod(N,2) == 0
        % even N
        H = [Hlow;conj(flipud(Hlow(2:end)))];
    else
        % odd N
        H = [Hlow;conj(flipud(Hlow))];
    end
    S = real(ifft(H));
    S = circshift(S,-round(N/2-m));
    
    Sinv = flipud(S);

    OUT.audio = S;
    OUT.audio2 = Sinv;
    OUT.fs = fs;
    OUT.tag = ['Sine sweep linear' num2str(dur)];
else
    OUT = [];
end