function [smoothmagspectrum]= octavesmoothing(fftdbin, octsmooth,fs)

% fftdbin is the fft of the signal in dB

fftpoints = length(fftdbin);

freqeval = linspace(0,fs/2,fftpoints);

if octsmooth > 0
    octsmooth=2*octsmooth;
    % octave center freqevaluencies
    f1=1;
    i=0;
    while f1 < (fs/2)
        f1=f1*10^(3/(10*octsmooth));
        i=i+1;
        fc(i,:)=f1;
    end

    % octave edge freqevaluencies
    for i=0:length(fc)-1
        i=i+1;
        f1=10^(3/(20*octsmooth))*fc(i);
        fe(i,:)=f1;
    end

    % find nearest freqevaluency edges
    for i=1:length(fe)
        fe_p=find(freqeval>fe(i),1,'first');
        fe_m=find(freqeval<fe(i),1,'last');
        fe_0=find(freqeval==fe(i));
        if isempty(fe_0)==0
            fe(i)=fe_0;
        else
            p=fe_p-fe(i);
            m=fe(i)-fe_m;
            if p<m
                fe(i)=fe_p;
            else
               fe(i)=fe_m;
            end
        end
    end
assignin('base','a',fe);
    for i=1:length(fe)-1
        fftdbin_i=fftdbin(fe(i):fe(i+1),:);
        smoothmagspectrum(i,1:size(fftdbin,2))=mean(fftdbin_i);
    end
    fc=fc(2:end);
    smoothmagspectrum=interp1(fc,smoothmagspectrum,freqeval,'spline');
    smoothmagspectrum = real(smoothmagspectrum);
    smoothmagspectrum = smoothmagspectrum';
else
    smoothmagspectrum = fftdbin;
end