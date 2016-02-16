classdef Group < Task
    %GROUP A group of tasks, in some order (one by one, by default)
    %   This "default" Group implementation runs all the trials in one Task
    %   until it is completed, then all the trials in the next Task, etc.
    %
    %   Extend this class and override selectNextTask to specify how to
    %   select which Task to run (if you are mixing multiple ones), and in
    %   which order to run them.  In a session they will be run one "unit"
    %   at a time (one trial for each call to runTask()).
    %
    %   For convenience, you may nest a group of tasks inside another group
    %   (ex. group A contains two groups B and C, where group B contains
    %   staircases and and group C contains check trials).  In other words,
    %   a Group is itself also a Task that can be added to a different
    %   Group.
    %
    %   Do not add the same object/handle multiple times to a Group.
    %   Override selectNextTask to do what you want.
    %
    %   Do not create Groups that contain themselves (directly or
    %   indirectly).  It is almost certain to create an infinite loop, and
    %   there currently is no error checking for this issue (TODO).  When
    %   this happens, you will observe a "stack overflow" error (I think?).
    
    properties% (GetAccess = private, SetAccess = private)
        tasksToDo = {}
        tasksDone = {}
        results = {}
    end
    
    methods (Access = protected)
        % Returns which task will be the next to be run (override me)
        function task = selectNextTask(group)
            if group.completed()
                task = [];
            else
                task = group.tasksToDo{1};
            end
        end
        
        function index = getIndexOf(group, task)
            index = find(cellfun(@(x) eq(x, task), group.tasksToDo), 1);
        end
    end
    
    methods
        function [] = addChoice(group, t)
            if ~isa(t, 'Task')
                e = MException('Group.addChoice:badType', ...
                    'The object must implement Task.');
                throw(e);
            end
            if ~isempty(group.getIndexOf(t))
                e = MException('Group.addChoice:alreadyExists', ...
                    ['A handle to the same Task object should not be' ...
                    ' added twice to the same Group.  If you want to' ...
                    ' repeat the Task, create a new instance of it' ...
                    ' first.  If you want to influence when or how' ...
                    ' often a particular Task is run, override this' ...
                    ' class and change selectNextTask();' ...
                    ]);
                throw(e);
            end
            
            % FYI, this method of appending to cell array is much faster
            % than A = [A {x}];
            idx = length(group.tasksToDo)+1;
            group.tasksToDo{idx} = t;
        end
        
        function addChoices(group, tasks)
            for t = tasks
                group.addChoice(t);
            end
        end
        
        function value = completed(group)
            value = isempty(group.tasksToDo);
        end
        
        function [success, allResults] = runAll(group)
            while ~group.completed
                [s, r] = group.runOnce();
                group.results = {group.results r};
                if ~s
                    success = false;
                    return;
                end
            end
            success = true;
            allResults = group.results;
        end
        
        function [success, result] = runOnce(group)
            currentTask = group.selectNextTask();
            
            if isempty(currentTask)
                success = false;
                result = [];
            else
                if ~isempty(group.OutFile) && isempty(currentTask.OutFile)
                    % Group OutFile overrides the task OutFile
                    % TODO overriding the setter function doesn't work :(
                    currentTask.OutFile = group.OutFile;
                end
                
                [success, result] = currentTask.runOnce();
                
                % TODO Any default action if success = false?
                
                if currentTask.completed()
                    % Remove from the task list
                    
                    taskIdx = group.getIndexOf(currentTask);
                    
                    % Swap the current task to position 1, just in case
                    % for compatibility with potential subclasses
                    group.tasksToDo{taskIdx} = group.tasksToDo{1};
                    group.tasksToDo{1} = currentTask;
                    
                    group.tasksToDo = group.tasksToDo(2:end);
                    
                    idx = length(group.tasksDone)+1;
                    group.tasksDone{idx} = currentTask;
                end
            end
        end
        
        function results = collectResults(group)
            results = group.results;
        end
    end
end

