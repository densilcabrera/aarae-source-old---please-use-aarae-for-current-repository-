function out = DynamicCompressiveGammachirpFilterbank(in)
% This function interfaces AARAE with Toshio Irino's GCFBv208 filters
%
% Note that this uses mex files, which may not be compatible with all
% systems.
%
% Please read the license for this toolbox:
%
% Toshio Irino, Wakayama university (National university corporation, Japan)
% Copyright (c) 2006, 2007
%
% Permission to use, copy, modify, and distribute this software without 
% fee is hereby granted FOR RESEARCH/EDUCATION PURPOSES only, provided 
% that this copyright notice appears in all copies and in all supporting 
% documentation, and that the software is not redistributed for any 
% fee (except for a nominal shipping charge). 
%
% For any other uses of this software, in original or modified form, 
% including but not limited to consulting, production or distribution
% in whole or in part, specific prior permission must be obtained 
% from the author.
% Signal processing methods and algorithms implemented by this
% software may be claimed by patents owned by ATR or others.
%
% The author makes no representation about the suitability of this 
% software for any purpose.  It is provided "as is" without warranty 
% of any kind, either expressed or implied.  
% Beware of the bugs.

% Interface file by Densil Cabrera 
% Version 0 (5 November 2013)


% Dialog box for settings
 
% Prompt for 3 named parameters:
     prompt = {'Passive or Compressive GC filter [0 | 1]', ...
         'Number of bands', ...
         'Highest band frequency (Hz)', ...
         'Lowest band frequency (Hz)', ...
         'Outer and middle ear correction [0 | 1]'};
 

% Title of the dialog box
     dlg_title = 'Settings'; 
 

    num_lines = 1;
 

% Default values
     def = {'1','75','6000','100','1'}; 
 

    answer = inputdlg(prompt,dlg_title,num_lines,def);
     
 % Set function variables from dialog box user-input values
     if ~isempty(answer)
         compressive = str2num(answer{1,1});
         GCparam.NumCh = str2num(answer{2,1});
         Hicutoff = str2num(answer{3,1});
         Locutoff = str2num(answer{4,1});
         GCparam.OutMidCrct = str2num(answer{5,1});
     end

% get audio signal from AARAE field
SndIn = in.audio;
SndIn = mean(SndIn,3); % mixdown the third dimension, if it exists
SndIn = SndIn(:,1); % select the first channel in the case of multichannel
SndIn = SndIn'; % transpose (1 row of audio signal is required for GCFBv208)

% set gammachirp parameters
GCparam.fs = in.fs;
GCparam.FRange = [Locutoff Hicutoff];

GCparam = GCFBv208_SetParam(GCparam);

[cGCout, pGCout, GCparam, GCresp] = GCFBv208(SndIn,GCparam);

if compressive
    out = permute(cGCout,[2,3,1]);
else
    out = permute(pGCout,[2,3,1]);
end

