% Ensure everything is OK with MATLAB, PTB, git, etc.
tempDiaryName = tempname();
diary(tempDiaryName); % Temporary diary
VerifyEnvironment;

%% File output directory and file setup
parentFolder = DataFile.DEFAULT_SUBFOLDER;

sessionIDStr = input('Subject code: ', 's');

curdate = datestr(now, 'yyyy_mm_dd HHMMSS');
if isempty(sessionIDStr)
    subfolder = curdate;
else
    subfolder = [sessionIDStr ' ' curdate];
end
dataFolder = [parentFolder filesep subfolder];

mkdir(dataFolder);

% Move diary to the correct location
diaryFile = [dataFolder filesep 'diary.log'];
diary('off');
movefile(tempDiaryName, diaryFile);
diary(diaryFile);

% Open files
sdColumns = StereoDisks.getColumns();

practiceFilePath = [dataFolder filesep 'practice.csv'];
practiceDataFile = DataFile(practiceFilePath, sdColumns);

experimentFilePath = [dataFolder filesep 'stereodisks.csv'];
experimentDataFile = DataFile(experimentFilePath, sdColumns);

%% Define the experiment's trials
fullExperiment = Group();

% One demo trial first
demoTrial = StereoDisks();
demoTrial.DurationSec = Inf;
demoTrial.OutFile = practiceDataFile;
fullExperiment.addChoice(demoTrial);

% Practice trials
nPracticeTrials = 10;
pracTrials(nPracticeTrials) = StereoDisks();
[pracTrials.DurationSec] = deal(1.0);
[pracTrials.DisparityDeg] = deal(0.1);
[pracTrials.OutFile] = deal(practiceDataFile);
fullExperiment.addChoices(pracTrials);

% Main trials
mainGroup = StereoDisksGroup();
mainGroup.OutFile = experimentDataFile;

fullExperiment.addChoice(mainGroup);

%% Run experiment

% Hold hardware open (ready) until end of experiment
HWRef = HWReference();

caughtError = [];
try
    fullExperiment.runAll();
catch caughtError
end

% Allow hardware to close
delete(HWRef);

diary off

workspaceSavePath = [dataFolder filesep 'workspace.mat'];
save(workspaceSavePath);

if isempty(caughtError)
    clear; % all finished as expected!
else
    rethrow(caughtError);
end
