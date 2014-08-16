function hoa2BinCfg = Hoa2BinDecodingFilters(hoaFmt,hrirs,hoa2BinOpt)

% Default options
if nargin < 3
    hoa2BinOpt = GenerateHoa2BinOpt ;
end

% HRIR data
Hri    = hrirs.impulseResponses ;
smpFrq = hrirs.sampFreq ;
azmMea = hrirs.sourceSphCoord(:,1) ;
elvMea = hrirs.sourceSphCoord(:,2) ;
radMea = hrirs.sourceSphCoord(:,3) ;

% Shortcuts
nmbHrm = hoaFmt.nbComp ;
method = hoa2BinOpt.method ;
fltLng = hoa2BinOpt.filterLength ;
eqlOpt = hoa2BinOpt.equalisation ;

% Change the filter length if it is less than the HRIR length
hriLng = size(Hri,1) ;
if hriLng >fltLng
    fprintf(['WARNING: ' ...
        'The filters are shorter than the HRIRs... ' ...
        'updating to ' num2str(hriLng) ' taps \n']) ;
    fltLng = hirLng ;
    hoa2BinOpt.filterLength = fltLng ;
end

% Initialize the filter structure
filters.sampFreq  = smpFrq ;
filters.nbInput   = nmbHrm ;
filters.nbOutput  = 2 ;
filters.firMatrix = [] ;

%%%%%%%%%%%%%%%%%%%%%%
% FILTER CALCULATION %
%%%%%%%%%%%%%%%%%%%%%%
    
% Number of frequency bins, frequency and wave number values
frq = (0:fltLng/2)'*smpFrq/fltLng ;

% HRTFS
Hrt = permute(fft(Hri,fltLng),[1 3 2]) ;

% Calculate the filters depending on the method
FltRsp = zeros(fltLng,nmbHrm,2) ;
switch lower(method)
        
    case 'virtualspk'
                
        % Virtual speaker set-up
        if hoaFmt.res3d == 0
            
            % Then it is a 2d format: a circular speaker array is used
            spkFmt = GenerateSpkFmt('nbSpk',nmbHrm+1, ...
                'distribType','even2d','setupRadius',radMea) ;
        else
            
            % Then it is a 3d format: a 3d speaker array is used
            
            % Find the optimal number of speakers
            nmbSpk = nmbHrm ;
            spkFmt = GenerateSpkFmt('nbSpk',nmbSpk, ...
                'distribType','even3d') ;
            SphHrmMat = SphericalHarmonicMatrix(hoaFmt, ...
                spkFmt.sphCoord(:,1),spkFmt.sphCoord(:,2)) ;
            cnd = cond(SphHrmMat) ; 
            while cnd > 10
                nmbSpk = nmbSpk + 1 ;
                spkFmt = GenerateSpkFmt('nbSpk',nmbSpk, ...
                    'distribType','even3d') ;
                SphHrmMat = SphericalHarmonicMatrix(hoaFmt, ...
                    spkFmt.sphCoord(:,1),spkFmt.sphCoord(:,2)) ;
                cnd = cond(SphHrmMat) ; 
            end
            
            % Final speaker array configuration
            spkFmt = GenerateSpkFmt('nbSpk',nmbSpk, ...
                'distribType','even3d','setupRadius',radMea(1)) ;
            
        end
        
        % Decoding filters
        decOpt = GenerateHoa2SpkOpt('filterLength',fltLng) ;
        DecFlt = Hoa2SpkDecodingFilters(hoaFmt,spkFmt,decOpt) ;
        DecFlt = fftshift(DecFlt.filters.firMatrix,1) ;

        % Decoding filter frequency responses
        DecRsp = fft(DecFlt) ;
        
        % HRTFs corresponding to the speaker positions
        HriSpk = InterpolateHrirs(azmMea,elvMea,Hri, ...
            spkFmt.sphCoord(:,1),spkFmt.sphCoord(:,2)) ;
        HrtSpk = fft(HriSpk,fltLng) ;
        
        % HOA -> binaural filters
        for I = 1 : length(frq)
            FltRsp(I,:,:)  = permute( ...
                squeeze(HrtSpk(I,:,:))*squeeze(DecRsp(I,:,:)), ...
                [3 2 1]) ;
        end
        
        
    case 'leasterr'
        
        % Projection (decoding) matrix
        PrjMat = Hoa2SpkDecodingMatrix(hoaFmt, ...
            azmMea,elvMea,'invMethod','tikhonov') ;
        
        % Project the measured HRTFs on the spherical harmonic basis
        FltRsp(:,:,1) = Hrt(:,:,1) * PrjMat ;
        FltRsp(:,:,2) = Hrt(:,:,2) * PrjMat ;
        
    case 'magoptim'
        
        % Transition frequency
        if strcmpi(hoa2BinOpt.magOptimFreq,'auto')
            % Automatic estimation of the transition frequency, based on
            % the least-error method phase-reconstruction error
            %
            % Projection (decoding) matrix
            PrjMat = Hoa2SpkDecodingMatrix(hoaFmt, ...
                azmMea,elvMea,'invMethod','tikhonov') ;
            % Spherical harmonic function values in the HRTF directions
            SphHrm = SphericalHarmonicMatrix(hoaFmt,azmMea,elvMea) ;
            % Least-err reconstructed HRTFs
            HrtRec(:,:,1) = Hrt(1:length(frq),:,1) * PrjMat * SphHrm ;
            HrtRec(:,:,2) = Hrt(1:length(frq),:,2) * PrjMat * SphHrm ;
            % Phase reconstruction error
            PhaErr = sqrt(mean(mean(abs(angle(HrtRec ...
                ./Hrt(1:length(frq),:,:))).^2,3),2)) ;
            % Frequency above which PhaErr > pi/12
            trnFrq = frq(find(PhaErr<=pi/12,1,'last')) ;
            % Cap the transition freq at 5000
            %  trnFrq = min(trnFrq,5000) ;
        else
            % Manually chosen transition frequency
            trnFrq = hoa2BinOpt.magOptimFreq ;
        end
        
        % Index of the transition frequency
        trnIdx = find(frq>=trnFrq,1,'first') ;
        trnIdx = min(trnIdx,fltLng/2-1) ;
        
        % Number of frequency bins for the LF->HF transition 
        trnLng = min(trnIdx,fltLng/2+1-trnIdx) ;

        % Original HRTF phases at low frequency
        Pha = unwrap(angle(Hrt(1:fltLng/2+1,:,:))) ;
      
        % Modify the HRTF phases (make them converge at high frequencies)
        wdw = triang(2*trnLng-1) ;
        gai = [ ones(trnIdx-1,1) ; 1-wdw(1:trnLng) ; ...
            zeros(fltLng/2+1-trnLng-trnIdx+1,1)] ;
        PhaNew = bsxfun(@plus, ...
            bsxfun(@times,Pha,gai),bsxfun(@times,mean(Pha,2),1-gai)) ;

        % Phase-customized HRTFs
        HrtCor = abs(Hrt(1:fltLng/2+1,:,:)) .* exp(1i*PhaNew) ;

        % Projection (decoding) matrix
        PrjMat = Hoa2SpkDecodingMatrix(hoaFmt, ...
            azmMea,elvMea,'invMethod','tikhonov') ;
        
        % Project the new HRTFs on the spherical harmonic basis
        FltRsp(1:fltLng/2+1,:,1) = HrtCor(:,:,1) * PrjMat ;
        FltRsp(1:fltLng/2+1,:,2) = HrtCor(:,:,2) * PrjMat ;   
        
end

% Global frequency equalisation if required
if eqlOpt == true
    
    % Spherical harmonic components for the measurement directions
    SphHrmMea = SphericalHarmonicMatrix(hoaFmt,azmMea,elvMea) ;
    
    % Calculate the average reconstructed HRTF energy as a function of 
    % frequency and adjust the filter gains accordingly
    for I = 1 : length(frq)
        % Average energy of the measured HRTFs
        EngMea = mean(mean(abs(Hrt(I,:,:)).^2)) ;
        % Reconstructed HRTFs
        HrtRec = permute(FltRsp(I,:,:),[3 2 1]) * SphHrmMea ;
        % Average energy of the reconstructed HRTFs
        EngRec = mean(mean(abs(HrtRec).^2)) ;
        % Adjust the gain pf the filters
        FltRsp(I,:,:) = sqrt(EngMea/EngRec) * FltRsp(I,:,:) ;
    end
    
end

% Filter impulse responses
FltRsp(fltLng/2+2:fltLng,:,:) = conj(FltRsp(fltLng/2:-1:2,:,:)) ;
FltImp = fftshift(permute(real(ifft(FltRsp)),[1 3 2]),1) ;

% Normalise the magnitude of the filter frequency responses
FltImp = .999 * FltImp / max(max(max(abs(fft(FltImp))))) ;

% Assign the filters into the output structure
filters.firMatrix = FltImp ;


%%%%%%%%%%%%%%%%%%%%
% OUTPUT STRUCTURE %
%%%%%%%%%%%%%%%%%%%%

% Fill the hoa2BinCfg structure
hoa2BinCfg.hoaFmt     = hoaFmt ;
hoa2BinCfg.hrirs      = hrirs ;
hoa2BinCfg.hoa2BinOpt = hoa2BinOpt ;
hoa2BinCfg.filters    = filters ;