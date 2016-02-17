classdef StereoDisksGroup < Group
    %STEREODISKSGROUP Summary of this class goes here
    %   TODO Detailed explanation goes here
    
    properties
        logDisparityAM = 1.0:-0.2:-0.6; % From 10 arcmin down to 0.25
        repetitions = 8;
        
        stopCheckFreq = 8;
        stopCheckWindowSize = 16;
        stopCount = 6; % Count of correct answers below which further disparities won't be tested
    end
    
    properties (Access = private)
        trialsDone
        corrects
    end
    
    methods
        function self = StereoDisksGroup()
            self@Group();
            
            % One block of trials for each disparity in logDisparityAM
            % Blocks of (self.repetitions) trials
            disparitiesDeg = (10 .^ self.logDisparityAM) / 60.0;
            nDisparities = length(disparitiesDeg);
            nTrials = nDisparities * self.repetitions;
            trialOrder = floor(((1:nTrials)-1) / nDisparities)+1;
            
            allDisparitiesDeg = disparitiesDeg(trialOrder);
            
            mainTrials(nTrials) = StereoDisks();
            disparitiesAsCell = num2cell(allDisparitiesDeg);
            [mainTrials.DisparityDeg] = disparitiesAsCell{:};
            
            self.addChoices(mainTrials);
            
            self.trialsDone = 0;
            self.corrects = zeros(1, nTrials);
        end
        
        function [s, r] = runOnce(self)
            [s, r] = self.runOnce@Group();
            
            self.trialsDone = self.trialsDone + 1;
            correct = r(4); %FIXME HACK
            self.corrects(self.trialsDone) = correct;
            
            correctStr = 'correct';
            if ~correct
                correctStr = 'incorrect';
            end
            fprintf('Disparity %f was %s\n', r(1), correctStr);
        end
        
        function done = completed(self)
            % If out of trials, return true
            done = self.completed@Group();
            if done
                return;
            end
            
            % Check if we should stop early
            t = self.trialsDone;
            n = self.stopCheckFreq;
            w = self.stopCheckWindowSize;
            if mod(t, n) == 0 && t > w
                window = (t-w+1) : t;
                correctCount = sum(self.corrects(window));
                done = correctCount <= self.stopCount;
            else
                done = false;
            end
        end
    end
    
end

