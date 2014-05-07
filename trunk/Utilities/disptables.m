function varargout = disptables(fig,tables)

% disptables    Adjust figure to fit MATLAB generated uitables.
%   fighandle = disptables(fig,tables) helps resize figures in order to
%   better display MATLAB generated uitables. If fig is a single figure
%   handle the function will adjust the array of handles corresponding to
%   the tables input or adjust the limits of the figure to a single table
%   handle.
%
%   fig and tables can be arrays of handles. E.g.:
%   fighandle = disptables(fig,tables); - where fig and tables are a single
%   figure handle and a single uitable handle.
%
%   tables = [t1 t2 t3];
%   fighandle = disptables(fig,tables); - where fig is a single figure
%   handle and tables is an array of uitable handles.
%
%   fig = [f1 f2 f3];
%   tables = [t1 t2 t3];
%   fighandle = disptables(fig,tables); - where fig is an array of figure
%   handles and tables is an array of uitable handles.
%
%   As added functionality, by clicking in the grey area outside the
%   displayed uitable you can automatically copy the displayed tables into
%   your computer's clipboard to export it to text editing software such as
%   Microsoft Excel.
%
%   See also copytoclipboard
%
%   Code by Daniel R. Jimenez for the AARAE project. (28 March 2014)

if length(fig) ~= length(tables), window = 'single'; end
if length(fig) == length(tables), window = 'multi'; end
figpos = get(fig,'Position');
ntables = length(tables);
if ntables == 1
    window = 'multi';
    temp = figpos;
    clear figpos
    figpos{1,1} = temp;
end
switch window
    case 'multi'
        for i = 1:ntables
            set(tables(i),'Parent',fig(i))
            s = get(tables(i),'Extent');
            set(fig(i),'Position',[figpos{i,1}(1) figpos{i,1}(2) s(3) s(4)],'WindowButtonDownFcn','copytoclipboard')
            set(tables(i),'Position',s)
        end
    case 'single'
        set(tables,'Parent',fig)
        s = get(tables,'Extent');
        s = flipud(s);
        tables = fliplr(tables);
        set(tables(1),'Position',s{1,1})
        y = s{1,1}(1,4);
        x = s{1,1}(1,3);
        for i = 2:ntables
            set(tables(i),'Position',[s{i,1}(1,1) y+10 s{i,1}(1,3) s{i,1}(1,4)])
            y = y + s{i,1}(1,4) + 10;
            if s{i,1}(1,3) > x, x = s{i,1}(1,3); end
        end
        set(fig,'Position',[figpos(1) figpos(2) x y],'WindowButtonDownFcn','copytoclipboard')
end
for n = 1:length(tables)
    outtables(n).RowName = get(tables(n),'RowName');
    outtables(n).ColumnName = get(tables(n),'ColumnName');
    outtables(n).Data = get(tables(n),'Data');
end
varargout{1} = fig;
varargout{2} = outtables;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2013,2014, Daniel Jimenez
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
%
%  * Redistributions of source code must retain the above copyright notice,
%    this list of conditions and the following disclaimer.
%  * Redistributions in binary form must reproduce the above copyright
%    notice, this list of conditions and the following disclaimer in the
%    documentation and/or other materials provided with the distribution.
%  * Neither the name of the University of Sydney nor the names of its
%    contributors may be used to endorse or promote products derived from
%    this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
% TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
% OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%