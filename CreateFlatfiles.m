% CreateFlatfiles.m
%
% With some code adapted from GatherData2RefitsCombined.m
% 2017-07-13 Alex

baseDir = DataFile.DEFAULT_SUBFOLDER;

statusUpdateInterval = 0.5;
experimentStartDate = datetime(2016, 02, 20); % ignore data prior to this date

if ~exist('GetSecs', 'file')
    GetSecs = @()now()*24*60*60;
end

dataDirs = dir([baseDir 'lma*']);
nSes = length(dataDirs);
[allSessionDirs{1:nSes}] = deal(dataDirs(:).name);

%% Metadata

% Input directories
sessions = table();
sessions.Directory = allSessionDirs';
sessions.Subject = repmat({''}, nSes, 1);
sessions.DateTime = datetime(zeros(nSes, 1), 'ConvertFrom', 'posixtime');
sessions.SessionNum = zeros(nSes, 1);
% CSV output files:
outCache = table();
outCache.Name = {''}; % filename
outCache.HeaderIn = {''}; % expected (input) CSV header (for checking conflicts & column reordering TODO)
outCache.h = zeros(1,1); % file handles
outCache(1,:) = [];

% Gather metadata on sessions
for iDir = 1:nSes
    currDir = sessions.Directory{iDir};
    
    % Metadata from parsing folder name
    split = regexp(currDir, ' ', 'split');
    % datenum format is 'yyyy_mm_dd HHMMSS'
    sessions.DateTime(iDir) = datetime([split{end-1} ' ' split{end}], 'InputFormat', 'yyyy_MM_dd HHmmss');
    code = regexpi(currDir, 'LMA[_\-]?\d\d', 'match', 'once');
    subjNum = regexpi(code, '\d\d', 'match', 'once');
    sessions.Subject{iDir} = ['LMA_' subjNum];
end
sessions.Subject = categorical(sessions.Subject);

% Ignore data prior to experiment start date
sessions(sessions.DateTime < experimentStartDate, :) = [];
nSes = height(sessions);

% Number each subject's sessions, in chronological order
sessions = sortrows(sessions,'DateTime','ascend'); % cosmetic

subjects = unique(sessions.Subject);
for iSub = 1:size(subjects);
    subjSessIdxs = sessions.Subject == subjects(iSub);
    [~, order] = sortrows(sessions.DateTime(subjSessIdxs));
    sessions.SessionNum(subjSessIdxs) = order;
end

writetable(sessions, 'sessions.csv');

%% Gather experimental data
lastStatus = 0;
for iSes = 1:nSes
    currDir = sessions.Directory{iSes};
    
    % Print occasional status updates
    if (GetSecs() - lastStatus > statusUpdateInterval)
        fprintf('Parsing %i of %i: ''%s''...\n', iSes, nSes, currDir);
        lastStatus = GetSecs();
    end
    
    sesDir = [baseDir currDir filesep];
    dataCSVs = dir([sesDir '*.csv']);
    
    headerPrepend = 'Subject,Session';
    dataPrepend = sprintf('%s,%i', ...
        sessions.Subject(iSes), sessions.SessionNum(iSes));
    
    for iFile = 1:length(dataCSVs)
        inFilename = dataCSVs(iFile).name;
        inH = fopen([sesDir inFilename]);
        
        outCacheHits = strcmp(inFilename, outCache.Name);
        cacheHit = any(outCacheHits);
        if ~cacheHit % need to open a new output file
            newEntry = struct();
            
            newName = inFilename;
            newEntry.Name = {newName};
            outH = fopen(newName, 'a');
            
            newEntry.h = outH;
        else
            outH = outCache{outCacheHits, 'h'};
        end
        
        fgetl(inH); % repetition of session folder name
        fgetl(inH); % empty line
        
        header = fgetl(inH); % excludes newline
        % TODO check the cached data to ensure we're only merging files with the same header
        if ~cacheHit
            fullHeader = sprintf('%s,%s\n', headerPrepend, header);
            fprintf(outH, '%s', fullHeader);
            
            newEntry.HeaderIn = {header};
            outCache = [outCache;struct2table(newEntry)]; %#ok<AGROW>
        end
        
        % dump rest of data into file
        line = fgets(inH);
        while ischar(line) % at end of file, line = numeric value -1
            fprintf(outH, '%s,%s', dataPrepend, line);
            line = fgets(inH);
        end
        
        fclose(inH);
    end
end

if ~isempty(outCache.h), for h = outCache.h', fclose(h); end; end;