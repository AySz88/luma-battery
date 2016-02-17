classdef HardwareSetup < handle
    %HARDWARESETUP Summary of this class goes here
    %   To grab the unique instance, call HardwareSetup.instance();
    %
    % The intention is that the class will automatically clean up hardware
    % when there are no (outside) references to the instance remaining.
    % However:
    % TODO does the persistent singleInstance reference here count as a
    % cyclic one?? Text from documentation:
    %
    % MATLAB will automatically clean up when the last reference
    % to its handle falls out of scope.  (MATLAB ignores the cyclic
    % reference.)
    %
    %  Consider a set of objects that reference other objects of the set such
    %  that the references form a cyclic graph. In this case, MATLAB:
    %
    %   Destroys the objects if they are referenced only within the cycle.
    %   Does not destroy the objects as long as there is an external
    %   reference to any of the objects from a MATLAB variable outside the
    %   cycle
    
    properties
        room
        screenNum
        
        viewDist
        monWidth
        
        useStereoscope
        stereoMode
        stereoTexWidth
        stereoTexOffset
        
        initPause
        
        lumCalib
        lumChannelContrib
        usePTBPerPxCorrection
        
        upKey
        downKey
        leftKey
        rightKey
        haltKey
        validKeys
        
        rightSound % filename
        wrongSound
        failSound
        rightSoundHandle % to PsychPortAudio
        wrongSoundHandle
        failSoundHandle
        
        randSeed
        randStream
        
        defaultFigureRect
        
        initialized
        
        white % TODO Dependent?
        fps % TODO Dependent?
        
        winPtr
        screenRect
        
        realWinPtr
        realRect
        % TODO realWinPtr should be Private, and winPtr should be Dependent
        % and same for realRect and screenRect
    end
    
    properties(Dependent)
        ppd
        width
        height
    end
    
    % Caching for faster LumToColor
    % TODO should be cleared on changes to
    %     HW.lumChannelContrib and/or HW.lumCalib
    properties(Access=private)
        stealPP
        nearestLumPP
        finalStepSizePP
        lumToRawPP
        rawToLumPP
    end
    
    % For ScreenCustomStereo
    properties(Access=private)
        texturePtrs
        textureRects
        currentStereoBuffer
    end
    
    methods(Static, Access={?HWReference})
        function obj = instance()
            persistent singleInstance
            if isempty(singleInstance) || ~isvalid(singleInstance)
                obj = HardwareSetup();
                singleInstance = obj;
            else
                obj = singleInstance;
            end
        end
    end
    
    methods(Access=private) % Ensure control over creation of these objects
        function self = HardwareSetup()
            DefaultParameters(self);
            Initialize(self);
        end
    end
    
    methods
        function ppd = get.ppd(HW)
            radtodeg = @(rad) rad*180/pi;
            
            monWidthPx = HW.screenRect(3)-HW.screenRect(1);
            monWidthDeg = radtodeg(2*atan(HW.monWidth/HW.viewDist/2));
            
            ppd = monWidthPx / monWidthDeg;
        end
        
        function width = get.width(HW)
            width = HW.screenRect(3)-HW.screenRect(1);
        end
        
        function height = get.height(HW)
            height = HW.screenRect(4)-HW.screenRect(2);
        end
        
%         function ppd = set.ppd(HW)
%             error
%         end
    end
    
    methods
        function delete(self)
            Cleanup(self);
        end
    end
    
end

