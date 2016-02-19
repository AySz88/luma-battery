% Runs an experiment testing stereo acuity and fixation disparity

%% Ensure everything is OK with MATLAB, PTB, git, etc.
tempDiaryName = tempname();
diary(tempDiaryName); % Temporary diary
VerifyEnvironment;

%% Subject information
sessionIDStr = input('Subject code: ', 's');
amblyEye = [];
while isempty(amblyEye)
    amblyEyeStr = input('Amblyopic eye: ', 's');
    switch lower(amblyEyeStr)
        case {'l', 'left', 'os'}
            amblyEye = 0;
        case {'r', 'right', 'od'}
            amblyEye = 1;
        otherwise
            fprintf('Huh? Try ''os'', ''od'', ''left'', or ''right''... ');
    end
end

%% File output directory and file setup
parentFolder = DataFile.DEFAULT_SUBFOLDER;

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

% Prepare for opening files
metadata = [subfolder sprintf('\n')];

% Open files
sdColumns = StereoDisks.getColumns();

practiceFilePath = [dataFolder filesep 'practice.csv'];
practiceDataFile = DataFile(practiceFilePath, sdColumns, metadata);

experimentFilePath = [dataFolder filesep 'stereodisks.csv'];
experimentDataFile = DataFile(experimentFilePath, sdColumns, metadata);

noniusColumns = NoniusAdjustmentTask.getColumns();

preNoniusFilePath = [dataFolder filesep 'prenonius.csv'];
preNoniusDataFile = DataFile(preNoniusFilePath, noniusColumns, metadata);

postNoniusFilePath = [dataFolder filesep 'postnonius.csv'];
postNoniusDataFile = DataFile(postNoniusFilePath, noniusColumns, metadata);

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
[pracTrials.DurationSec] = deal(1.5);
[pracTrials.DisparityDeg] = deal(0.1);
[pracTrials.OutFile] = deal(practiceDataFile);
fullExperiment.addChoices(pracTrials);

% Nonius pre-test
nNoniusPretest = 3;
noniusPretest(nNoniusPretest) = NoniusAdjustmentTask();
if amblyEye == 0
    [noniusPretest.leftLuminance] = deal(1.00);
    [noniusPretest.rightLuminance] = deal(0.45);
else
    [noniusPretest.leftLuminance] = deal(0.45);
    [noniusPretest.rightLuminance] = deal(1.00);
end
[noniusPretest.OutFile] = deal(preNoniusDataFile);
fullExperiment.addChoices(noniusPretest);

% Main trials
mainGroup = StereoDisksGroup(1.0);
mainGroup.OutFile = experimentDataFile;
halfGroup = StereoDisksGroup(0.5);
halfGroup.OutFile = experimentDataFile;
doubleGroup = StereoDisksGroup(2.0);
doubleGroup.OutFile = experimentDataFile;

fullExperiment.addChoice(mainGroup);
fullExperiment.addChoice(halfGroup);
fullExperiment.addChoice(doubleGroup);

% Nonius lines post-test
nNoniusPosttest = 3;
noniusPosttest(nNoniusPosttest) = NoniusAdjustmentTask();
if amblyEye == 0
    [noniusPosttest.leftLuminance] = deal(1.00);
    [noniusPosttest.rightLuminance] = deal(0.45);
else
    [noniusPosttest.leftLuminance] = deal(0.45);
    [noniusPosttest.rightLuminance] = deal(1.00);
end
[noniusPosttest.OutFile] = deal(postNoniusDataFile);
fullExperiment.addChoices(noniusPosttest);

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

%% Cleanup
workspaceSavePath = [dataFolder filesep 'workspace.mat'];
save(workspaceSavePath);

if isempty(caughtError)
    diary off
    
    clear; % all finished as expected!
else
    rethrow(caughtError);
end
