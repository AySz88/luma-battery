
% disparitiesDeg = 10 .^ (-0.6:0.2:1.0) / 60.0; % 0.25 to 10 arcmin
disparitiesDeg = repmat(10 .^ (1.0:-0.2:-0.6) / 60.0, 1, 10); % 0.25 to 10 arcmin


nTrials = length(disparitiesDeg);

%[ hasChanges, output ] = GitChangeCheck( )

% mainExperiment = Group();
% for iTrial=1:nTrials
%     sd = StereoDisks(disparities(iTrial));
%     mainExperiment.addChoice(sd);
% end

% Hold hardware open (ready) until end of experiment
HWRef = HWReference();

% mainExperiment.runAll();

for iTrial=1:nTrials
    sd = StereoDisks(disparitiesDeg(iTrial));
    %sd.AnnulusOuterRDeg = 0;
    %sd.DisparityDirection = 'y';
    sd.DiskOffFromCenterDeg = 1.5;
    sd.nDisks = 4;
    sd.runOnce();
end

% Allow hardware to close
delete(HWRef);