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
    
    properties (GetAccess = private, SetAccess = private)
        tasksToDo
        tasksDone
        results
    end
    
    methods (Access = protected)
        % Returns which task will be the next to be run (override me)
        function task = selectNextTask(group)
            if group.completed()
                task = [];
            else
                task = group.tasksToDo(1);
            end
        end
    end
    
    methods
        function [] = addChoice(group, t)
            if ~isa(t, 'Task')
                e = MException('Group.addChoice:badType', ...
                    'The object must implement Task.');
                throw(e);
            end
            if find(group.tasksToDo, t)
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
            group.tasksToDo = [group.tasksToDo t];
        end
        
        function value = completed(group)
            value = isempty(group.tasksToDo);
        end
        
        function [success, result] = runAll(group)
            allResults = [];
            while ~group.completed
                [s, r] = group.runOnce();
            end
            success = true;
            result = allResults;
        end
        
        function [success, result] = runOnce(group)
            currentTask = group.selectNextTask();
            
            if isempty(currentTask)
                success = false;
                result = [];
            else
                [success, result] = currentTask.runOnce();
                % TODO Any default action if success = false?
                
                if currentTask.completed()
                    % Removal from the task list
                    taskIdx = find(group.tasksToDo, currentTask, 1);
                    group.tasksToDo(taskIdx) = group.tasksToDo(end);
                    group.tasksToDo(end) = currentTask;
                    group.tasksToDo = group.tasksToDo(1:end-1);
                    
                    group.tasksDone = [group.tasksDone currentTask];
                end
            end
        end
        
        function results = collectResults(group)
            results = group.results;
        end
    end
end

