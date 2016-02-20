classdef (Abstract) AdjustmentStimulus < Task
    %ADJUSTMENTSTIMULUS Interface for method-of-adjustment stimuli
    %   Generic - override me
    
    properties
        CurrValue
    end
    
    properties(Abstract)
        initValue
    end
    
    properties(Constant)
        stopKey = 'return'; % FIXME hack
    end
    
    methods(Static)
        function columns = getColumns(varargin)
            if nargin < 1
                columns = [getColumns@Task(), ...
                    {'Final value', 'Initial value'}];
            else
                unitText = varargin{1};
                columns = [getColumns@Task(), ...
                    {sprintf('Final value (%s)', unitText), ...
                     sprintf('Initial value (%s)', unitText)}];
            end
        end
    end
    
    methods
        function data = collectFlatData(t)
            data = [t.collectFlatData@Task(), t.Result, t.initValue];
        end
    end
    
    methods
        function [success, result] = runOnce(self)
            HWRef = HWReference();
            HW = HWRef.hw;
            
            self.CurrValue = self.initValue;
            
            stop = false;
            
            KbWait([],1); % wait until all keys are released
            wasKeyUp = false;
            
            % Set cursor to (near) the center
            mousePtr = HW.screenNum;
            scrCenter = round(0.5*[HW.width HW.height]);
            scrCtrX = scrCenter(1);
            scrCtrY = scrCenter(2);
            SetMouse(scrCtrX, scrCtrY, mousePtr);
            
            while ~stop
                % Present new stimulus frame
                self.draw();
                
                % Process response
                [keyDown, ~, keyCode, ~] = KbCheck();
                downstroke = keyDown && wasKeyUp;
                if downstroke
                    response = KbName(keyCode);
                else
                    response = [];
                end
                if downstroke && ~iscell(response)
                    switch lower(response)
                        case HW.upKey
                            self.goUp();
                        case HW.downKey
                            self.goDown();
                        case self.stopKey
                            stop = self.stopCheck();
                        case HW.haltKey
                            % 'graceful' bail
                            throw(MException('FindThreshold:Halt', ...
                                ['Halted by user hitting ''' ...
                                HW.haltKey '''!']));
                        otherwise
                            % That wasn't one of the valid keys!
                            PsychPortAudio('Start', HW.failSoundHandle);
                            % TODO display message to user?
                    end
                end
                wasKeyUp = ~keyDown;
                
                % Look for displacement in mouse, then reset it
                [mouseX, mouseY, buttons] = GetMouse(mousePtr);
                mouseVec = [mouseX - scrCtrX, mouseY - scrCtrY];
                if buttons(1)==1
                    stop = self.stopCheck();
                else
                    self.handleMouse(mouseVec);
                end
                SetMouse(scrCtrX, scrCtrY, mousePtr);
            end
            
            success = true;
            result = self.CurrValue;
            
            self.Completed = true;
            self.Result = result;

            self.runOnce@Task();
        end
    end
    
    methods (Abstract)
        % Function called every frame to refresh the screen
        [] = draw(task);
        
        % Function called each time the subject presses HW.upKey
        [] = goUp(task);
        % Function called each time the subject presses HW.downKey
        [] = goDown(task);
        
        % Function called every frame on mouse position changes
        % Arguments:
        %   vector = [x,y] pixel vector of mouse movement this frame
        % Relative movement only, one frame at a time
        % Mouse is reset to the middle of the frame after this call
        [] = handleMouse(task, vector);
        
        % Function called when the subject says they are finished
        % Returns true iff the task should stop / is completed
        [stop] = stopCheck(task);
    end
    
end
