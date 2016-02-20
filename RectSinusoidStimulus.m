classdef RectSinusoidStimulus < AdjustmentStimulus
    %RECTSTIMUSOIDSTIMULUS Ding-Sperling type stimulus, with bands
    %   Task: adjust (trade-off) contrasts b/t eyes until it looks centered
    %
    % Adapted from
    %   TrainGabors\IOCMeasures\RectangularSinusoidAdjustment.m
    % 	TrainGabors\IOCMeasures\RectangularSinusoidDisplay.m
    % by Alex, 2016-02
    
    properties
        % Value is log10 contrast ratio between left and right eyes (bigger = left
        % brighter)
        initValue = 0;
        stepSize = log10(1.20); % percent changes (multiplicative)
        totalContrast = 1.0;
        
        flashUptime = 1.0;
        flashDowntime = 1.0;
        
        %RECTANGULARSINUSOIDDISPLAY Draws a grating + fusion lock into the window
        % Grating is oriented horizontally (lum changes in vertical direction) with
        % luminances from 0 (assumed black) to 1 (display max).
        % No color correction is done; that is done elsewhere (i.e. PsychImaging)
        % Use of ScreenCustomStereo is (probably?) required
        %  widthDeg     : Width of grating rectangle (deg)
        %  heightDeg    : Height of grating rectangle (deg)
        %  bgLum        : Luminance of background relative to display max
        %  contrasts    : Contrasts relative to max possible for bgLum
        %  bands        : # of bands to render (use [] for fully smooth)
        %  phases       : Phase at center (in each eye), positive = shift up
        %  cycles       : # of cycles vertically (ex. peak to peak)
        %  lockWidthDeg : Width of fusion lock box (deg), see DrawFusionLock
        %  lockSquares  : # of squares on each edge of fusion lock box
        %  markWidthPx  : Width of mark on screen in pixels
        %  markHeightPx : Height of mark on screen in pixels
        %  markOffsetPx : Offset of height of mark (for bracketing)
        bgLum = 0.5;
        widthDeg = 0.25;
        heightDeg = 6.0;
        bands = 16; % # of bands, use [] for no banding
        phases = (2*pi/6 * [0.5 -0.5]) + pi;
        cycles = 1;
        lockWidthDeg = 8.0; % full width of the lock box
        lockSquares = 16;
        markWidthPx = 100;
        markHeightPx = 5;
        markOffsetPx = 0;
    end
    
    % === Flatfile handling functions ===
    methods(Static)
        function columns = getColumns()
            columns = [getColumns@AdjustmentStimulus(), ...
                {'Initial value (log10 contrast ratio, l/r)', ...
                'Final value (log10 contrast ratio)'}];
        end
    end
    
    methods
        function data = collectFlatData(t)
            data = [t.collectFlatData@AdjustmentStimulus(), t.initValue];
        end
    end
    
    methods
        function self = RectSinusoidStimulus()
            self = self@AdjustmentStimulus();
            
            self.CurrValue = self.initValue;
        end
        
        function [success, result] = runOnce(self)
            [success, result] = self.runOnce@AdjustmentStimulus();
            
            self.Completed = success;
            self.Result = result;
        end
        
        function [] = draw(self)
            HWRef = HWReference();
            HW = HWRef.hw;
            
            value = self.CurrValue;
            
            % decide whether to display full stimulus
            % divides time up into up and down times
            flashTime = self.flashUptime + self.flashDowntime;
            flashUp = mod(GetSecs, flashTime) < self.flashUptime;
            if flashUp
                contrasts = ...
                    self.totalContrast .* [(10^value), 1]./(10^value + 1);
            else
                contrasts = [0 0];
            end
            %{
            % Luminance maximization method
            if value > 0
                contrasts = [1 10^(-value)];
            else
                contrasts = [10^value 1];
            end
            %}
            
            center = 0.5 .* (HW.screenRect([3 4]) - HW.screenRect([1 2]));
            width = round(self.widthDeg * HW.ppd);
            height = round(self.heightDeg * HW.ppd);
            destXs = center(1) + [-0.5 0.5] .* width;
            destYs = center(2) + [-0.5 0.5] .* height;
            trueDestRect = [destXs(1) destYs(1) destXs(2) destYs(2)];
            
            if ~isfield(self, 'bands') || isempty(self.bands)
                self.bands = height;
            end
            
            lockWidthPx = self.lockWidthDeg * HW.ppd;
            
            additive = true;
            
            amp = min(1-self.bgLum, self.bgLum); % maximum possible contrast
            
            stimImg(:,:,:,1) = amp * contrasts(1) .* ...
                SinusoidImage(width, self.bands, self.phases(1), self.cycles, additive);
            stimImg(:,:,:,2) = amp * contrasts(2) .* ...
                SinusoidImage(width, self.bands, self.phases(2), self.cycles, additive);
            
            stimImg = self.bgLum + stimImg;
            
            for eye=[1,2]
                HW.ScreenCustomStereo(...
                    'SelectStereoDrawBuffer', HW.winPtr, eye-1);
                Screen('FillRect', HW.winPtr, HW.white * self.bgLum);
                Screen('PutImage', HW.winPtr, ...
                    HW.white * stimImg(:,:,:,eye), trueDestRect);
                
                markRects = [ ... First mark ...
                    destXs(1) - self.markWidthPx, ...
                    center(2) - 0.5*self.markHeightPx + self.markOffsetPx, ...
                    destXs(1), ...
                    center(2) + 0.5*self.markHeightPx + self.markOffsetPx; ...
                    ... Second mark ...
                    destXs(2), ...
                    center(2) - 0.5*self.markHeightPx + self.markOffsetPx, ...
                    destXs(2) + self.markWidthPx, ...
                    center(2) + 0.5*self.markHeightPx + self.markOffsetPx];
                
                Screen('FillRect', HW.winPtr, 0, markRects(1,:));
                Screen('FillRect', HW.winPtr, 0, markRects(2,:));
                
                %DrawFusionLock(HW, center, 0.5*lockWidthPx, self.lockSquares);
            end
            
            HW.ScreenCustomStereo('Flip', HW.winPtr);
        end
        
        function [] = goUp(self)
            % wants left eye (higher) to be brighter
            self.CurrValue = self.CurrValue + self.stepSize;
            disp(10^self.CurrValue);
        end
        
        function [] = goDown(self)
            self.CurrValue = self.CurrValue - self.stepSize;
            disp(10^self.CurrValue);
        end

        function [stop] = stopCheck(~)
            stop = true;
%             % For bracketing:
%             self.markStage = mod(self.markStage, length(self.markBracketsPx)) + 1;
%             stop = (self.markStage == 1); % back to start
%             if ~stop
%                 fprintf('Bracketed at: %f\n', self.value);
%             end
%             newVal = val;
        end
        
        function [results] = collectResults(task)
            error('Not yet implemented');
        end
    end
end

function img = SinusoidImage(width, height, phase, cycles, additive)
% SINUSOIDIMAGE Creates matrix containing image of sinusoidal contrast stim
% Horizontal grating (luminance varies in vertical direction)
% Parameters:
%   width, height: the dimensions of the image
%   phase       : offset of max from the center (more positive = upwards)
%   cycles      : number of full cycles across the full height
%   additive	: iff true, range from -1 to 1, else range from 0 to 1
% Example: image(SinusoidImage(10,1000, 0, 4, false));

if nargin < 5
    additive = false;
end

centerY = (height+1)/2;
y = (1:height) - centerY;
yLums = sin(2*pi*y*cycles/height + phase + pi/2);
if ~additive
    yLums = yLums*0.5 + 0.5;
end

lums = repmat(yLums', 1, width);

img = cat(3,lums,lums,lums); % to RGB
end