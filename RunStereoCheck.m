VerifyEnvironment;

%% Define the experiment's trials
fullExperiment = Group();

% One demo trial first
demoTrial = StereoDisks();
demoTrial.DurationSec = Inf;
fullExperiment.addChoice(demoTrial);

% Practice trials
nPracticeTrials = 10;
pracTrials(nPracticeTrials) = StereoDisks();
[pracTrials.DurationSec] = deal(1.0);
[pracTrials.DisparityDeg] = deal(0.1);
fullExperiment.addChoices(pracTrials);

% Main trials
mainGroup = StereoDisksGroup();

fullExperiment.addChoice(mainGroup);

%% Run experiment

% Hold hardware open (ready) until end of experiment
HWRef = HWReference();

fullExperiment.runAll();

% Allow hardware to close
delete(HWRef);
