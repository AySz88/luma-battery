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
        DiskColor = 0;
        DotType = 1; % Screen(DrawDots) dot type argument
        
        MouseMaxWanderDeg = 1.0; % max distance the mouse can wander from the 
        MouseDotLum = [1 0 0];
        MouseLineSizePx = 3;
        MouseDotSizePx = 15;
        MouseLineType = 2;
        ActiveDiskLum = [0.3 0 0];
    end
    
    properties(Access=private)
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
            HWRef = HWReference();
            hw = HWRef.hw;
            
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
            
            % Calculate positions of disks and objects
            reversedDisk = randi(self.nDisks);
            
            scrCenter = 0.5*[hw.width hw.height];
            angles = (0:self.nDisks-1) * 2*pi/self.nDisks;
            diskOffsetsPx = self.DiskOffFromCenterDeg * ppd;
                
            posJitterPx = self.DiskPosJitterDeg * ppd;
            jitterOffsets = (rand(1,self.nDisks) - 0.5) * posJitterPx;
            
            idealCenters = [cos(angles); sin(angles)] * diskOffsetsPx;
            diskCenters = idealCenters + [jitterOffsets; zeros(1, self.nDisks)];

            disparityOffsetPx = 0.5 * self.DisparityDeg * ppd;
            disparityOffsets = ones(1,self.nDisks) * disparityOffsetPx;
            disparityOffsets(reversedDisk) = disparityOffsets(reversedDisk) * -1;
            
            diskSizePx = self.DiskSizeDeg * ppd;
            
            stimulusStart = GetSecs();
            displayComplete = false;
            while ~displayComplete;
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

                    Screen('DrawDots', hw.winPtr, ...
                        currEyeCenters, diskSizePx, self.DiskColor, ...
                        scrCenter, self.DotType);

                    % For debugging
                    % Yellow = original locations, red = jittered locations
%                     Screen('DrawDots', hw.winPtr, ...
%                         [cos(angles); sin(angles)] * diskOffsetsPx, ...
%                         10, [255 255 0 255], screenCenter, 1);
%                     Screen('DrawDots', hw.winPtr, ...
%                         diskCenters, 10, [255 0 0 255], screenCenter, 1);
                end
                hw.ScreenCustomStereo('Flip', hw.winPtr);
                
                if GetSecs() - stimulusStart > self.DurationSec
                    displayComplete = true;
                end
            end
            
            % Set cursor to (near) the center
            mousePtr = hw.screenNum;
            scrCtrX = scrCenter(1);
            scrCtrY = scrCenter(2);
            SetMouse(scrCtrX, scrCtrY, mousePtr);
            mouseMaxPx = self.MouseMaxWanderDeg * ppd;
            
            trialComplete = false;
            while ~trialComplete
                [mouseX, mouseY, buttons] = GetMouse(mousePtr);
                mouseVec = [mouseX - scrCtrX, mouseY - scrCtrY];
                mouseTheta = mod(atan2(mouseVec(2), mouseVec(1)), 2*pi);
                mouseDist = norm(mouseVec);
                
                % Ensure mouse is not outside limits
                if mouseDist > mouseMaxPx
                    %mouseDist = mouseMaxPx;
                    mouseVec = [cos(mouseTheta), sin(mouseTheta)] * mouseMaxPx;
                    mouseVecOnScreen = mouseVec + scrCenter;
                    SetMouse(mouseVecOnScreen(1), mouseVecOnScreen(2), mousePtr);
                end
                
                activeDisk = mod(round(mouseTheta/(2*pi) * self.nDisks)+1, self.nDisks);
                if activeDisk == 0, activeDisk = self.nDisks; end
                
                for i=0:1
                    % i=0 for left eye, i=1 for right eye
                    hw.ScreenCustomStereo('SelectStereoDrawBuffer', hw.winPtr, i);
                    Screen('DrawTexture', hw.winPtr, self.BGTexture, ...
                        [], bgDestRect, [], 0);
                    
                    Screen('DrawDots', hw.winPtr, ...
                        idealCenters, diskSizePx, self.DiskColor, ...
                        scrCenter, self.DotType);
                    
                    % Draw over the active disk with the highlight color
                    Screen('DrawDots', hw.winPtr, ...
                        idealCenters(:, activeDisk), diskSizePx, ...
                        self.ActiveDiskLum * hw.white, scrCenter, self.DotType);
                    
                    % Draw the mouse location
                    Screen('DrawDots', hw.winPtr, ...
                        mouseVec, self.MouseDotSizePx, ...
                        self.MouseDotLum * hw.white, scrCenter, self.DotType);
                    Screen('DrawLines', hw.winPtr, ...
                        [[0;0], mouseVec'], self.MouseLineSizePx, ...
                        self.MouseDotLum * hw.white, scrCenter, ...
                        self.MouseLineType);
                end
                hw.ScreenCustomStereo('Flip', hw.winPtr);
                
                if buttons(1) == 1
                    trialComplete = true;
                end
                %fprintf('%i, %f  ', activeDisk, mouseTheta);
            end
            
            correct = (activeDisk == reversedDisk);
            
            success = true;
            result = [reversedDisk, activeDisk, correct];
        end
        
        % Returns whether the task(s) have been completed
        function value = completed(self)
        end
        
        % Returns: a cell array of each result object, in the order they
        %   were run.
        function [results] = collectResults(self)
            % FIXME? Disks are currently numbered clockwise from the right x-axis
            % (due to the fact that positive Y-axis is downwards in graphics)
        end
    end
end