classdef StereoDisks < Task
    properties%(Access=private)
        DisparityDeg
        
        DurationSec = 0.200;
        
        BGCheckSizeAM = 30.0; % size of squares in arcmin
        BGLuminanceAvg = 0.75;
        BGLuminanceSD = 0.20;
        nDisks = 8;
        DiskLuminance = 0.0;
        DiskOffFromCenterDeg = 3.0; % How far center of each disk is from the center of the screen
        DiskSizeDeg = 1.125; % diameter
        DiskPosJitterDeg = 1.0; % total horizontal variation (half left, half right)
    end
    
    properties%(Access=private)
        BGTexture
        BGTextureSize
    end
    
    methods
        function self = StereoDisks(disparityDeg)
            self.DisparityDeg = disparityDeg;
        end
        
        % Returns:
        %   success: whether the task was successfully run (i.e. should be
        %      counted as having run)
        %   result: the result object from this trial
        function [success, result] = runOnce(self)
            hw = HardwareSetup.instance();
            
            KbWait([],1); % wait until all keys are released
            
            ppd = hw.ppd;
            
            % Build background texture
            BGCheckSizePx = self.BGCheckSizeAM / 60.0 * ppd;
            self.BGTextureSize = ceil([hw.width hw.height]/BGCheckSizePx);
            bgDestRect = [0,0, self.BGTextureSize * BGCheckSizePx];
            
            bgImg = self.BGLuminanceAvg + ...
                (randn(self.BGTextureSize([2 1])) * self.BGLuminanceSD);
            bgImg = bgImg * hw.white;
            
            self.BGTexture = hw.ScreenCustomStereo('MakeTexture', hw.winPtr, bgImg);
            
            reversedDisk = randi(self.nDisks);
            
            screenCenter = 0.5*[hw.width hw.height];
            angles = (0:self.nDisks-1) * 2*pi/self.nDisks;
            diskOffsetsPx = self.DiskOffFromCenterDeg * ppd;
                
            posJitterPx = self.DiskPosJitterDeg * ppd;
            jitterOffsets = (rand(1,self.nDisks) - 0.5) * posJitterPx;
            
            diskCenters = [cos(angles); sin(angles)] * diskOffsetsPx ...
                + [jitterOffsets; zeros(1, self.nDisks)];

            disparityOffsetPx = 0.5 * self.DisparityDeg * ppd;
            disparityOffsets = ones(1,self.nDisks) * disparityOffsetPx;
            disparityOffsets(reversedDisk) = disparityOffsets(reversedDisk) * -1;
            
            for i=0:1
                % i=0 for left eye, i=1 for right eye
                hw.ScreenCustomStereo('SelectStereoDrawBuffer', hw.winPtr, i);
                Screen('DrawTexture', hw.winPtr, self.BGTexture, ...
                    [], bgDestRect, [], 0);
                
                if i == 0
                    disparityMult = -1;
                else
                    disparityMult = 1;
                end
                
                % Calculate dot positions for this eye including offsets
                currEyeCenters = diskCenters;
                currEyeCenters(1,:) = currEyeCenters(1,:) + ...
                    disparityMult * disparityOffsets;
                
                diskSizePx = self.DiskSizeDeg * ppd;
                Screen('DrawDots', hw.winPtr, ...
                    currEyeCenters, diskSizePx, 0, screenCenter, 1);
                
                % For debugging
                % Yellow = original locations, red = jittered locations
%                 Screen('DrawDots', hw.winPtr, ...
%                     [cos(angles); sin(angles)] * diskOffsetsPx, ...
%                     10, [255 255 0 255], screenCenter, 1);
%                 Screen('DrawDots', hw.winPtr, ...
%                     diskCenters, 10, [255 0 0 255], screenCenter, 1);
            end
            hw.ScreenCustomStereo('Flip', hw.winPtr);
            
            % FIXME - FOR TESTING ONLY! remove me!
%             pause();
%             delete(hw);
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