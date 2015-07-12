function X = workflow_example2
% This is an example of a workflow with no input signal

% This generates a STIPA signal with hardware-specific octave-band levels
% (In this case, the signal is for the NTI Talkbox)
X = STIPA_signal(30,48000,[-0.7            0           -3         -9.4        -16.5        -23.4        -31.6]);
end