classdef Staircase < Task
    %STAIRCASE Helper functions for a generic 3up1down Garcia Perez staircase
    % **abstract class** - must implement methods (see Task.m)
    %   TODO Detailed explanation goes here
    
    properties
        M
%         q % TODO create a quest version of this class
        trialVal
        
        trialVals
        trialLog
        lastLogged
        
        initialization
        recentRight
        recentWrong
        lastDirWasDown
        reversals
        reversalNum
    end
    
    methods
        function S = Staircase(M, maxTrials)
            %GenericInitStaircase Intializes experiment state variable S
            %   M: Model (i.e. staircase) parameter structure
            %   E: Experiment (i.e. stimulus) parameter structure
            
            if isempty(M)
                M.beta = 1;
                M.gamma = 1;
                M.delta = 0.05;
                M.downCount = 3;
                CalcGarciaPerezStaircase( M )
            end
            
            S.M = M;
%             S.q=QuestCreate(M.tAverage, M.tSD, ...
%                 M.pThreshold, M.beta, M.delta, M.gamma, M.grain, M.range);
            
            if M.useQuest
                e = MException('Staircase:noQuest', ...
                    ['TODO usage of QUEST to select new staircase values' ...
                    ' is not yet implemented in this class; it needs' ...
                    ' to be implemented in a new class.' ...
                    ]);
                throw(e);
%                 S.trialVal = QuestQuantile(S.q);
            else %nDownmUp
                S.trialVal = M.tStart;
                
                % Variables used in nDownmUp:
                S.recentRight = 0;
                S.recentWrong = 0;
                
                % Initialization period: start w/ quick 'down's, like Garcia-Perez
                S.initialization = true;
                
                % Reversal tracking
                S.lastDirWasDown = true;
                S.reversals = ...
                    zeros(1,ceil(2*maxTrials/(M.downCount + M.upCount)));
                S.reversalNum = 1; % which reversal index is next
            end
            
            S.trialVals = zeros(maxTrials, 1);
            S.trialLog = cell(maxTrials, 2);
            S.lastLogged = 0; % how many rows of trialLog have data?
        end
        
        function stop = update(S, P, i, correct, testVal)
            %Code derived from GenericUpdateHelper
            %   Generic code to update models based on trial response
            %   Intended to be called by specific update methods.
            %
            %   Inputs:
            %       M = Model (i.e. staircase) parameter structure
            %       S = Current experiment state
            %       P = Last stimulus parameters
            %       i = Current trial number (of full experiment)
            %       correct = Whether response was correct
            %       testVal = Value at which the trial stimulus was acutally displayed
            %
            %   Outputs:
            %       S = Updated experiment state
            %       stop = Whether staircase should halt
            
            % Log result
            S.trialLog(i, :) = {P, correct};
            S.trialVals(i) = S.trialVal;
            S.lastLogged = i;
            
            % Update models/statistics
%             S.q = QuestUpdate(S.q, testVal, correct);
            
            if S.M.useQuest
%                 S.trialVal = QuestQuantile(S.q);
            else % update nDownmUp
                if correct
                    S.recentRight = S.recentRight + 1;
                    S.recentWrong = 0;
                else
                    S.recentRight = 0;
                    S.recentWrong = S.recentWrong + 1;
                end
                
                % debugging code
                %fprintf('%3u right %3u wrong...\n', S.recentRight, S.recentWrong);
                
                % check for staircase steps and reversals
                if S.recentRight >= S.M.downCount || ...
                        (S.initialization && (S.recentRight >= 1))
                    % step down (harder)
                    if ~S.lastDirWasDown
                        S.reversals(S.reversalNum) = S.trialVal;
                        S.reversalNum = S.reversalNum + 1;
                    end
                    S.trialVal = S.trialVal + S.M.stepDown;
                    S.recentRight = 0;
                    S.lastDirWasDown = true;
                elseif S.recentWrong >= S.M.upCount
                    % step up (easier)
                    if S.lastDirWasDown
                        S.reversals(S.reversalNum) = S.trialVal;
                        S.reversalNum = S.reversalNum + 1;
                    end
                    S.trialVal = S.trialVal + S.M.stepUp;
                    S.recentWrong = 0;
                    S.initialization = false;
                    S.lastDirWasDown = false;
                end
            end
            
            % Check for early halting
%             stop = QuestSd(S.q) < S.M.sdTarget;
%             if (stop)
%                 fprintf('Uncertainty low - recommend stopping early!\n');
%             end
            stop = false;
        end
    end
    
end

