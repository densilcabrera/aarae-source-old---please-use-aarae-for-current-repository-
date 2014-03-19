function [OUT, varargout] = InverseHilbert(IN,fs)
% This function performs an inverse Hilbert transform (only useful for
% complex input data)


    
    
if isstruct(IN) 
    audio = IN.audio; % Extract the audio data
    fs = IN.fs;       % Extract the sampling frequency of the audio data
    
    
  
    
    
elseif ~isempty(param) || nargin > 1
    
    audio = IN;
    fs = input_1;
end

if ~isempty(audio)
    
    
   % inverse of the Hilbert transform
    audio = abs(audio).* cos(angle(audio));
    

    if isstruct(IN)
        OUT = IN; 
        OUT.audio = audio; 
    else
        
        OUT = audio;
    end
    varargout{1} = fs;
    
else
    
    OUT = [];
end

