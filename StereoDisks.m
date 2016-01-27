classdef StereoDisks < Task
    properties(Access=private)
        Disparity
        
        DurationSec = 0.200;
        
        BGCheckSizeAM = 30; % size of squares in arcmin
        BGLuminanceAvg = 0.75;
        BGLuminanceSD = 0.20;
        DiskLuminance = 0.0;
    end
    
    properties(Access=private)
        BGTexture
        BGTextureSize
    end
    
    methods
        function self = StereoDisks(disparity)
            self.Disparity = disparity;
        end
        
        % Returns:
        %   success: whether the task was successfully run (i.e. should be
        %      counted as having run)
        %   result: the result object from this trial
        function [success, result] = runOnce(self)
            hw = HardwareSetup.instance();
            
            KbWait([],1); % wait until all keys are released
            
            ppd = hw.ppd;
            
            BGCheckSizePx = self.BGCheckSizeAM / 60.0 * ppd;
            self.BGTextureSize = [hw.width hw.height]/BGCheckSizePx;
            
            bgImg = self.BGTextureAvg + ...
                (randn(self.BGTextureSize) * self.BGTextureSD);
            
            hw.ScreenCustomStereo('SelectStereoDrawBuffer', hw.winPtr, 0);
            self.BGTexture = hw.ScreenCustomStereo('MakeTexture', hw.winPtr, bgImg);
            
            for i=0:1
                % i=0 for left eye, i=1 for right eye
                hw.ScreenCustomStereo('SelectStereoDrawBuffer', hw.winPtr, i);
                Screen('DrawTexture', hw.winPtr, self.BGTexture);
            end
            pause(20);
            delete(hw);
        end
        
        % Returns whether the task(s) have been completed
        function value = completed(self)
        end
        
        % Returns: a cell array of each result object, in the order they
        %   were run.
        function [results] = collectResults(self)
        end
    end
end