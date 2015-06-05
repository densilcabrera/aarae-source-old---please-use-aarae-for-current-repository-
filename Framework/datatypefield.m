function datatypestring = datatypefield(choice)
% This function returns one of AARAE's data-type strings, which determine
% where the audio leaf appears in the uitree of the GUI. Note that the
% fourth datatype ('results') can display data in a 'tables' field
% in the GUI (whereas the others cannot).
%
% The purpose of this function is to prevent undefined datatype field
% strings from being used by accident (which would cause an error).

switch choice
    case 1
        datatypestring = 'testsignals';
    case 2
        datatypestring = 'measurements';
    case 3
        datatypestring = 'processed';
    case 4
        datatypestring = 'results';
    otherwise
        datatypestring = 'processed';
end