classdef (Abstract) AdjustmentStimulus < Task
    %ADJUSTMENTSTIMULUS Interface for method-of-adjustment stimuli
    %   Generic - override me
    
    properties
        CurrValue
    end
    
    properties(Constant)
        stopKey = 'return'; % FIXME hack
    end
    
    methods
        function [success, result] = runOnce(self)
            HWRef = HWReference();
            HW = HWRef.hw;
            
            stop = false;
            
            KbWait([],1); % wait until all keys are released
            wasKeyUp = false;
            
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
            end
            
            success = true;
            result = self.CurrValue;
            
            self.Completed = true;
            self.Result = result;

            self.runOnce@Task();
        end
    end
    
    methods (Abstract)
        [] = draw(task);
        [] = goUp(task);
        [] = goDown(task);
        [stop] = stopCheck(task);
    end
    
end
