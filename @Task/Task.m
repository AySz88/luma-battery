classdef (Abstract) Task < matlab.mixin.Copyable
    %TASK Interface for anything that can run an atomic action (ex. trial)
    %   Subclasses of this class can run different types of trials and
    %   stimuli, different mixes of trials, in different order, etc.
    
    properties
        OutFile
    end
    
    properties (Access = protected)
        Completed = false;
    end
    
    % ==== Flatfile management functions ====
    % TODO be able to push columns into the start of the line
    %   for global trial number, etc.
    methods
        function set.OutFile(self, dataFile)
            self.OutFile = dataFile;
        end
    end
    methods(Static)
        % Column labels for flatfiles of this class
        % Returns a cell array of strings
        function columns = getColumns()
            columns = {'DateTime'};
        end
    end
    methods
        % Function that opens a datafile automatically through a path
        function [] = openDataFile(self, path)
            if isempty(self.OutFile)
                self.OutFile = DataFile(path, self.getColumns());
            else
                error('Task:DataFileAlreadyOpen', ...
                    ['Can''t open a datafile because self.OutFile' ...
                    ' already exists']);
            end
        end
    end
    
    % ==== Flatfile writing functions ====
    methods
        % Flatfile data output, as a vector of numbers
        function data = collectFlatData(~)
            data = now();
        end
        
        function [] = appendFlatData(self)
            if ~isempty(self.OutFile)
                self.OutFile.append(collectFlatData(self));
            end
        end
    end
    
    % ==== Common task interfaces (override these) ====
    methods
        % Returns:
        %   success: whether the task was successfully run (i.e. should be
        %      counted as having run)
        %   result: the result object from this trial
        function [success, result] = runOnce(task)
            % I'm just a superclass, so just do stuff with the data that
            % was gathered by the subclass
            task.appendFlatData();
            task.Completed = true;
        end
        
        % Returns whether the task(s) have been completed
        % TODO needs to be a get/set function
        function value = completed(task)
            value = task.Completed;
        end
    end
    methods (Abstract)
        % Returns: a cell array of each result object, in the order they
        %   were run.
        [results] = collectResults(task)
    end
    
end

