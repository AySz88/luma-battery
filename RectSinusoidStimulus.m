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
        
        maxValue = 2.5;
        minValue = -2.5;
        
        flashUptime = 1.5;
        flashDowntime = 0.75;
        
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
        displayContrast = [0.5 0.5];
        widthDeg = 2.0;
        heightDeg = 6.0;
        bands = 16; % # of bands, use [] for no banding
        phases = (2*pi/6 * [0.5 -0.5]) + pi;
        cycles = 1;
        lockWidthDeg = 8.0; % full width of the lock box
        lockSquares = 16;
        markWidthPx = 100;
        markHeightPx = 5;
        markOffsetPx = 0;
        
        mouseValPerPx = 1.0/250.0; % Change in value per pixel vertical mouse movement
    end
    
    % === Flatfile handling functions ===
    methods(Static)
        function columns = getColumns(varargin)
            if nargin < 1
                units = 'log10 contrast ratio (l/r)';
            else
                units = varargin{1};
            end
            columns = getColumns@AdjustmentStimulus(units);
        end
    end
    
    methods
        function data = collectFlatData(t)
            data = t.collectFlatData@AdjustmentStimulus();
        end
    end
    
    % === Main methods ===
    methods
        function self = RectSinusoidStimulus()
            self = self@AdjustmentStimulus();
        end
        
        function [success, result] = runOnce(self)
            [success, result] = self.runOnce@AdjustmentStimulus();
            
            self.Completed = success;
            self.Result = result;
        end
        
        function [] = draw(self)
            % Determine how the value changes the stimulus first
            value = self.CurrValue;
            
            self.displayContrast = [(10^value), 1]./(10^value + 1);
            %{
            % Luminance maximization method
            if value > 0
                self.displayContrast = [1 10^(-value)];
            else
                self.displayContrast = [10^value 1];
            end
            %}
            
            self.noSideEffectDraw();
        end
        
        function [] = noSideEffectDraw(self)
            % Draws the stimulus using only the properties contained within,
            % ignoring the CurrValue.
            % (This is a helper to make it easier to override draw().)
            
            HWRef = HWReference();
            HW = HWRef.hw;
            
            % decide whether to display full stimulus
            % divides time up into up and down times
            flashTime = self.flashUptime + self.flashDowntime;
            flashUp = mod(GetSecs, flashTime) < self.flashUptime;
            if flashUp
                currContrasts = self.totalContrast .* self.displayContrast;
            else
                currContrasts = [0 0];
            end
            
            center = 0.5 .* (HW.screenRect([3 4]) - HW.screenRect([1 2]));
            width = round(self.widthDeg * HW.ppd);
            height = round(self.heightDeg * HW.ppd);
            destXs = center(1) + [-0.5 0.5] .* width;
            destYs = center(2) + [-0.5 0.5] .* height;
            trueDestRect = [destXs(1) destYs(1) destXs(2) destYs(2)];
            
            if isempty(self.bands)
                self.bands = height;
            end
            
            lockWidthPx = self.lockWidthDeg * HW.ppd;
            
            additive = true;
            
            amp = min(1-self.bgLum, self.bgLum); % maximum possible contrast
            
            stimImg(:,:,:,1) = amp * currContrasts(1) .* ...
                SinusoidImage(width, self.bands, self.phases(1), self.cycles, additive);
            stimImg(:,:,:,2) = amp * currContrasts(2) .* ...
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
                
                DrawFusionLock(center, 0.5*lockWidthPx, self.lockSquares);
            end
            
            HW.ScreenCustomStereo('Flip', HW.winPtr);
        end
        
        % === UI methods (implementing AdjustmentStimulus) ===
        function [] = goUp(self)
            % wants left eye (higher) to be brighter
            self.CurrValue = self.CurrValue + self.stepSize;
            self.clipValue();
%             disp(10^self.CurrValue);
        end
        
        function [] = goDown(self)
            self.CurrValue = self.CurrValue - self.stepSize;
            self.clipValue();
%             disp(10^self.CurrValue);
        end
        
        function [] = handleMouse(self, mouseVec)
            deltaY = mouseVec(2);
            valueChange = self.mouseValPerPx * deltaY;
            
            self.CurrValue = self.CurrValue + valueChange;
            self.clipValue();
            
%             if abs(valueChange) > 0.02
%                 disp(10^self.CurrValue);
%             end
        end
        
        function [] = clipValue(self)
            self.CurrValue = min(self.CurrValue, self.maxValue);
            self.CurrValue = max(self.CurrValue, self.minValue);
        end

        function [stop] = stopCheck(self)
            stop = true;
            fprintf('Stopping at: %f\n', self.CurrValue);
%             % For bracketing:
%             self.markStage = mod(self.markStage, length(self.markBracketsPx)) + 1;
%             stop = (self.markStage == 1); % back to start
%             if ~stop
%                 fprintf('Bracketed at: %f\n', self.value);
%             end
%             newVal = val;
        end
        
        function [results] = collectResults(task)
            results = task.Result;
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
