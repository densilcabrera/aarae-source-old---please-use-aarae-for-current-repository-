function filltable(audiodata,start,handles)
fields = fieldnames(audiodata);
fields = fields(start:end-1);
categories = fields(mod(1:length(fields),2) == 1);
catdata = cell(size(categories));
catunits = cell(size(categories));
for n = 1:length(categories)
    catdata{n,1} = '[1]';
    catunits{n,1} = audiodata.(genvarname([categories{n,1} 'info'])).units;
end
dat = [categories,catdata,catunits];
set(handles.cattable, 'Data', dat);
