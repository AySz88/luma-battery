classdef StereoDisks < Task
    properties (Constant)
        CROSS_VS_UNCROSS = 1;
        ZERO_VS_CROSS = 2;
        %VERTICAL_VS_CROSS = 3;
    end
    properties
        DisparityDeg = 0.2;
        
        PreStimSec = 0.75; % Duration to display background before stimulus
        DurationSec = 1.0; % Stimulus duration; use Inf to wait until mouse/key press
        DelaySec = 0.1; % "Blank" time between stimulus and response UI
        
        StimShortenable = true; % Whether stimulus can be cut short by a mouse or key press
        
        BGCheckSizeAM = 30.0; % size of squares in arcmin
        BGLuminanceAvg = 0.65;
        BGLuminanceSD = 0.20;
        
        % Angles are clockwise from the right x-axis
        % (due to the fact that positive Y-axis is downwards in graphics)
        % FIXME? not very intuitive
        nDisks = 4;
        StartDotTheta = 2 * pi * 0.125; % Theta (position) of disk 1, radians
        
        DiskLuminance = 0.0;
        DiskOffFromCenterDeg = 1.5; % How far center of each disk is from the center of the screen
        DiskSizeDeg = 1.0; % diameter
        DiskPosJitterDeg = 0.25; % total horizontal variation (half left, half right)
        DiskColor = 0;
        DotType = 1; % Screen(DrawDots) dot type argument
        
        EccentricityFactor = 1.0; % Factor to scale the size of the disks and most of the stimulus (but not disparity or nonius lines)
        
        DisparityType = StereoDisks.CROSS_VS_UNCROSS;
        DisparityDirection = 'x';
        
        DiskResponseSizeDeg = 0.75;
        DiskResponseOutlineSizeDeg = 0.9;
        DiskResponseOutlineColor = 1.0;
        
        MouseMaxWanderDeg = 3.0; % max distance the mouse can wander from the 
        MouseDotLum = [1 0 0];
        MouseLineSizePx = 3;
        MouseDotSizePx = 15;
        MouseLineType = 2;
        ActiveDiskLum = [0.3 0 0];
        
        AnnulusLum = 0.5;
        AnnulusInnerRDeg = 2.0;
        AnnulusOuterRDeg = 3.0;
        
        FixWidthDeg = 0.5;
        FrameWidthPx = 5; % Line width
        NoniusWidthPx = 5; % Line width
        NoniusLengthDeg = 0.5;
        NoniusOffsetDeg = 0.5; % Distance from center of screen
    end
    
    properties(Access=private)
        BGTexture = []
        BGTextureSize
%         AnnuTexture
%         AnnuTextureSize
    end
    
    properties
        Result
    end
    
    % === Flatfile handling functions ===
    methods(Static)
        function columns = getColumns()
            columns = [getColumns@Task(), ...
                {'Disparity (deg)', ...
                'Eccentricity Factor', ...
                'Reversed Disk No.', 'Selected Disk', 'Correct'}];
        end
    end
    
    methods
        function data = collectFlatData(t)
            data = [t.collectFlatData@Task(), t.Result];
        end
    end
    
    methods
        function self = StereoDisks(varargin)
            if nargin >= 1
                dispaDeg = varargin{1};
                if ~isnumeric(dispaDeg) || ~isscalar(dispaDeg)
                    error('StereoDisk:WrongType', ...
                        'Disparity must be a scalar number');
                end
                self.DisparityDeg = dispaDeg;
            end
        end
        
        % Returns:
        %   success: whether the task was successfully run (i.e. should be
        %      counted as having run)
        %   result: the result object from this trial
        function [success, result] = runOnce(self)
            HWRef = HWReference();
            hw = HWRef.hw;
            
            ppd = hw.ppd;
            ef = self.EccentricityFactor;
            
            % Build background texture
            BGCheckSizePx = self.BGCheckSizeAM / 60.0 * ppd;
            self.BGTextureSize = ceil([hw.width hw.height]/BGCheckSizePx);
            bgDestRect = [0,0, self.BGTextureSize * BGCheckSizePx];
            
            bgImg = self.BGLuminanceAvg + ...
                (randn(self.BGTextureSize([2 1])) * self.BGLuminanceSD);
            bgImg = max(0.0, min(1.0, bgImg)); % Prevent going over white or below black
            bgImg = bgImg * hw.white;
            
            self.BGTexture = hw.ScreenCustomStereo('MakeTexture', hw.winPtr, bgImg);
            
            % Calculate positions of disks and objects
            reversedDisk = randi(self.nDisks);
            
            scrCenter = 0.5*[hw.width hw.height];
            angles = (0:self.nDisks-1) * 2*pi/self.nDisks + self.StartDotTheta;
            diskOffsetsPx = self.DiskOffFromCenterDeg * ppd * ef;
                
            posJitterPx = self.DiskPosJitterDeg * ppd * ef;
            jitterOffsets = (rand(1,self.nDisks) - 0.5) * posJitterPx;
            
            idealCenters = [cos(angles); sin(angles)] * diskOffsetsPx;
            diskCenters = idealCenters + [jitterOffsets; zeros(1, self.nDisks)];
            
            if self.DisparityType == self.CROSS_VS_UNCROSS
                disparityOffsetPx = 0.5 * self.DisparityDeg * ppd;
                disparityOffsets = ones(1,self.nDisks) * disparityOffsetPx;
                disparityOffsets(reversedDisk) = disparityOffsets(reversedDisk) * -1;
            elseif self.DisparityType == self.ZERO_VS_CROSS
                disparityOffsetPx = self.DisparityDeg * ppd;
                disparityOffsets = zeros(1,self.nDisks) * disparityOffsetPx;
                disparityOffsets(reversedDisk) = disparityOffsetPx;
            end
            
            diskSizePx = self.DiskSizeDeg * ppd * ef;
            annulusOuterSizePx = self.AnnulusOuterRDeg * ppd * ef;
            
            annulusColor = self.AnnulusLum * hw.white;
            
            %% Background stage
            delayStart = GetSecs();
            delayComplete = false;
            while ~delayComplete;
                for i=0:1
                    % i=0 for left eye, i=1 for right eye
                    hw.ScreenCustomStereo('SelectStereoDrawBuffer', hw.winPtr, i);
                    Screen('DrawTexture', hw.winPtr, self.BGTexture, ...
                        [], bgDestRect, [], 0);
                    
                    Screen('gluDisk', hw.winPtr, annulusColor, ...
                        scrCenter(1), scrCenter(2), annulusOuterSizePx);
                end
                self.drawFixMark(hw);
                hw.ScreenCustomStereo('Flip', hw.winPtr);
                
                % Wait until keys are released before starting the stimulus
                timeout = GetSecs() - delayStart > self.PreStimSec;
                keyDown = KbCheck();
                if timeout && ~keyDown
                    delayComplete = true;
                end
            end
            
            %% Stimulus display
            stimulusStart = GetSecs();
            displayComplete = false;
            % Track mouse and keyboard state, so we can skip rest of
            % stimulus when the mouse button or pressed key is RELEASED
            preMouseDown = false;
            preKeyDown = false;
            while ~displayComplete;
                for i=0:1
                    % i=0 for left eye, i=1 for right eye
                    hw.ScreenCustomStereo('SelectStereoDrawBuffer', hw.winPtr, i);
                    Screen('DrawTexture', hw.winPtr, self.BGTexture, ...
                        [], bgDestRect, [], 0);
                    
                    Screen('gluDisk', hw.winPtr, annulusColor, ...
                        scrCenter(1), scrCenter(2), annulusOuterSizePx);

                    if i == 0
                        disparityMult = -1;
                    else
                        disparityMult = 1;
                    end

                    % Calculate dot positions for this eye including offsets
                    currEyeCenters = diskCenters;
                    switch lower(self.DisparityDirection)
                        case 'x'
                            offsetRowIdx = 1;
                        case 'y'
                            offsetRowIdx = 2;
                    end
                    currEyeCenters(offsetRowIdx,:) = ...
                        currEyeCenters(offsetRowIdx,:) + ...
                        disparityMult * disparityOffsets;

%                     Screen('DrawDots', hw.winPtr, ...
%                         currEyeCenters, diskSizePx, self.DiskColor * hw.white, ...
%                         scrCenter, self.DotType);
                    
                    rects = ...
                        [currEyeCenters(1,:) + scrCenter(1) - 0.5*diskSizePx; ...
                         currEyeCenters(2,:) + scrCenter(2) - 0.5*diskSizePx; ...
                         currEyeCenters(1,:) + scrCenter(1) + 0.5*diskSizePx; ...
                         currEyeCenters(2,:) + scrCenter(2) + 0.5*diskSizePx];
                    Screen('FillOval', hw.winPtr, ...
                        self.DiskColor * hw.white, rects);
                    
                    % For debugging
                    % Yellow = original locations, red = jittered locations
%                     Screen('DrawDots', hw.winPtr, ...
%                         [cos(angles); sin(angles)] * diskOffsetsPx, ...
%                         10, [255 255 0 255], screenCenter, 1);
%                     Screen('DrawDots', hw.winPtr, ...
%                         diskCenters, 10, [255 0 0 255], screenCenter, 1);
                end
                self.drawFixMark(hw);
                hw.ScreenCustomStereo('Flip', hw.winPtr);
                
                timeout = GetSecs() - stimulusStart > self.DurationSec;
                [~,~,buttons] = GetMouse();
                mouseClicked = preMouseDown && ~any(buttons);
                keyPressed = preKeyDown && ~KbCheck();
                if timeout || (self.StimShortenable && (mouseClicked || keyPressed))
                    displayComplete = true;
                end
                
                preMouseDown = any(buttons);
                preKeyDown = KbCheck();
            end
            
            %% Brief pause between stimulus and response UI
            delayStart = GetSecs();
            delayComplete = false;
            while ~delayComplete;
                for i=0:1
                    % i=0 for left eye, i=1 for right eye
                    hw.ScreenCustomStereo('SelectStereoDrawBuffer', hw.winPtr, i);
                    Screen('DrawTexture', hw.winPtr, self.BGTexture, ...
                        [], bgDestRect, [], 0);
                    
                    Screen('gluDisk', hw.winPtr, annulusColor, ...
                        scrCenter(1), scrCenter(2), annulusOuterSizePx);
                end
                self.drawFixMark(hw);
                hw.ScreenCustomStereo('Flip', hw.winPtr);
                
                timeout = GetSecs() - delayStart > self.DelaySec;
                mouseDown = any(buttons);
                
                if timeout && ~mouseDown
                    delayComplete = true;
                end
            end
            
            %% Response collection
            % Set cursor to (near) the center
            mousePtr = hw.screenNum;
            scrCtrX = round(scrCenter(1));
            scrCtrY = round(scrCenter(2));
            SetMouse(scrCtrX, scrCtrY, mousePtr);
            mouseMaxPx = self.MouseMaxWanderDeg * ppd * ef;
            
            diskResponseSizePx = self.DiskResponseSizeDeg * ppd * ef;
            diskResponseOutlineSizePx = self.DiskResponseOutlineSizeDeg * ppd * ef;
            
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
                    mouseVecOnScreen = round(mouseVec + scrCenter);
                    SetMouse(mouseVecOnScreen(1), mouseVecOnScreen(2), mousePtr);
                end
                
                activeDisk = mod(round((mouseTheta-self.StartDotTheta)/(2*pi) * self.nDisks)+1, self.nDisks);
                if activeDisk == 0, activeDisk = self.nDisks; end
                
                for i=0:1
                    % i=0 for left eye, i=1 for right eye
                    hw.ScreenCustomStereo('SelectStereoDrawBuffer', hw.winPtr, i);
                    Screen('DrawTexture', hw.winPtr, self.BGTexture, ...
                        [], bgDestRect, [], 0);
                    
                    Screen('gluDisk', hw.winPtr, annulusColor, ...
                        scrCenter(1), scrCenter(2), annulusOuterSizePx);
                    
%                     Screen('DrawDots', hw.winPtr, ...
%                         idealCenters, diskResponseOutlineSizePx, ...
%                         self.DiskResponseOutlineColor * hw.white, ...
%                         scrCenter, self.DotType);
                    outlineRects = ...
                        [idealCenters(1,:) + scrCenter(1) - 0.5*diskResponseOutlineSizePx; ...
                         idealCenters(2,:) + scrCenter(2) - 0.5*diskResponseOutlineSizePx; ...
                         idealCenters(1,:) + scrCenter(1) + 0.5*diskResponseOutlineSizePx; ...
                         idealCenters(2,:) + scrCenter(2) + 0.5*diskResponseOutlineSizePx];
                    Screen('FillOval', hw.winPtr, ...
                        self.DiskResponseOutlineColor * hw.white, outlineRects);
                    
%                     Screen('DrawDots', hw.winPtr, ...
%                         idealCenters, diskResponseSizePx, ...
%                         self.DiskColor * hw.white, ...
%                         scrCenter, self.DotType);
                    idealRects = ...
                        [idealCenters(1,:) + scrCenter(1) - 0.5*diskResponseSizePx; ...
                         idealCenters(2,:) + scrCenter(2) - 0.5*diskResponseSizePx; ...
                         idealCenters(1,:) + scrCenter(1) + 0.5*diskResponseSizePx; ...
                         idealCenters(2,:) + scrCenter(2) + 0.5*diskResponseSizePx];
                    Screen('FillOval', hw.winPtr, ...
                        self.DiskColor * hw.white, idealRects);
                    
                    % Draw over the active disk with the highlight color
%                     Screen('DrawDots', hw.winPtr, ...
%                         idealCenters(:, activeDisk), diskResponseSizePx, ...
%                         self.ActiveDiskLum * hw.white, scrCenter, self.DotType);
                    highlightRect = ...
                        [idealCenters(1,activeDisk) + scrCenter(1) - 0.5*diskResponseSizePx; ...
                         idealCenters(2,activeDisk) + scrCenter(2) - 0.5*diskResponseSizePx; ...
                         idealCenters(1,activeDisk) + scrCenter(1) + 0.5*diskResponseSizePx; ...
                         idealCenters(2,activeDisk) + scrCenter(2) + 0.5*diskResponseSizePx];
                    Screen('FillOval', hw.winPtr, ...
                        self.ActiveDiskLum * hw.white, highlightRect);
                    
                    % Draw the mouse location
                    Screen('DrawDots', hw.winPtr, ...
                        mouseVec, self.MouseDotSizePx, ...
                        self.MouseDotLum * hw.white, scrCenter, self.DotType);
                    Screen('DrawLines', hw.winPtr, ...
                        [[0;0], mouseVec'], self.MouseLineSizePx, ...
                        self.MouseDotLum * hw.white, scrCenter, ...
                        self.MouseLineType);
                end
                self.drawFixMark(hw);
                hw.ScreenCustomStereo('Flip', hw.winPtr);
                
                if buttons(1) == 1
                    trialComplete = true;
                end
                %fprintf('%i, %f  ', activeDisk, mouseTheta);
            end
            
            correct = (activeDisk == reversedDisk);
            
            if correct
                PsychPortAudio('Start', hw.rightSoundHandle);
            else
                PsychPortAudio('Start', hw.wrongSoundHandle);
            end
            
            try
                Screen('Close', self.BGTexture);
                self.BGTexture = [];
            catch
            end
            
            success = true;
            result = [self.DisparityDeg, self.EccentricityFactor, ...
                reversedDisk, activeDisk, correct];
            
            self.Result = result;
            self.Completed = true;
            
            self.runOnce@Task();
        end
        
        % Returns whether the task(s) have been completed
        function value = completed(self)
            value = self.Completed;
        end
        
        % Returns: a cell array of each result object, in the order they
        %   were run.
        function [results] = collectResults(self)
            results = self.Result;
        end
        
        function delete(self)
            if ~isempty(self.BGTexture)
                try
                    Screen('Close', self.BGTexture);
                catch
                end
            end
%             if ~isempty(self.AnnuTexture)
%                 Screen('Close', self.AnnuTexture);
%             end
        end
    end
    
    methods (Access = private)
        function drawFixMark(self, hw)
            fixWidthPx = self.FixWidthDeg * hw.ppd;
            scrCenter = 0.5*[hw.width hw.height];
            centerX = scrCenter(1);
            centerY = scrCenter(2);
            for i=0:1
                % i=0 for left eye, i=1 for right eye
                startOffset = self.NoniusOffsetDeg * hw.ppd;
                endOffset = startOffset + self.NoniusLengthDeg * hw.ppd;
                if i == 0
                    % Nonius line up (negative y) for left eye
                    startOffset = -startOffset;
                    endOffset = -endOffset;
                end
                hw.ScreenCustomStereo('SelectStereoDrawBuffer', hw.winPtr, i);
                Screen('FrameRect', hw.winPtr, hw.white, ...
                    [scrCenter-0.5*fixWidthPx, scrCenter+0.5*fixWidthPx], ...
                    self.FrameWidthPx);
                Screen('DrawLine', hw.winPtr, hw.white, ...
                    centerX, centerY+startOffset, ...
                    centerX, centerY+endOffset, ...
                    self.NoniusWidthPx);
            end
        end
    end
end
