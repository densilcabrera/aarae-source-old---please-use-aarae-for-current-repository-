function closefigures
% closes all figures except for the AARAE GUI
% This function may be useful in writing workflows in cases where you do
% not want any previous figures to be preserved.
h = findobj('type','figure','-not','tag','aarae');
delete(h)