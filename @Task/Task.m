classdef Task < handle
    %TASK Interface for anything that can run an atomic action (ex. trial)
    %   Subclasses of this class can run different types of trials and
    %   stimuli, different mixes of trials, in different order, etc.
    
    properties
    end
    
    methods (Abstract)
        % Returns:
        %   success: whether the task was successfully run (i.e. should be
        %      counted as having run)
        %   result: the result object from this trial
        [success, result] = runOnce(task)
        
        % Returns whether the task(s) have been completed
        value = completed(task)
        
        % Returns: a cell array of each result object, in the order they
        %   were run.
        [results] = collectResults(task)
    end
    
end

