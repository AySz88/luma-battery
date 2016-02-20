classdef RectSinusoidControlStimulus < RectSinusoidStimulus
    %RECTSINUSOIDCONTROLSTIMULUS Ding-Sperling-like demo stimulus
    %   A control stimulus where both eyes get the same image, but the
    %   actual phase (i.e. vertical location) of the stimulus changes
    
    % Override RectSinusoidStimulus default values in constructor
    methods
        function self = RectSinusoidControlStimulus()
            self = self@RectSinusoidStimulus();
            
            % Value is change of phase from pi (black band centered)
            self.initValue = (pi/6 * 0.5);
            self.stepSize = 0.125*(pi/6); % phase changes per keyboard press
            
            self.maxValue = pi/2;
            self.minValue = -pi/2;
            
            % phase change per mouse pixel
            % Note: positive phase change shifts stimulus in negative y
            % direction
            self.mouseValPerPx = - (self.stepSize / 20.0);
        end
    end
    
    properties
        zeroValPhase = [pi, pi]; % Phase to which value=0 corresponds
    end
    
    % === Flatfile handling functions ===
    methods(Static)
        function columns = getColumns(varargin)
            if nargin < 1
                units = 'radians';
            else
                units = varargin{1};
            end
            columns = getColumns@RectSinusoidStimulus(units);
        end
    end
    
    methods
        function data = collectFlatData(t)
            data = t.collectFlatData@RectSinusoidStimulus();
        end
    end
    
    % === Main methods ===
    methods
        function [] = draw(self)
            % Apply the phase offset to the stimulus
            value = self.CurrValue;
            self.phases = self.zeroValPhase + value;
            self.noSideEffectDraw();
        end
    end
    
end

