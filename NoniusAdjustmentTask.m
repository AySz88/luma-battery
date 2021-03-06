classdef NoniusAdjustmentTask < Task
    
    properties
        outerFuseSize = 6.0;                % length of side of outer fusion square (around simulus) in degrees
        outerFuseThickness = 0.3;           % thickness of outer fusion square lines in degrees
        innerFuseSize = 1.8;                % length of size of inner fusion square in degrees
        innerFuseThickness = 6 ;         	% thickness of inner fusion square lines in pixels
        innerFuseTargetThickness = 6 ;    	% thickness of nonius fusion target lines in pixels
        fuseLineLength = 0.4;               % length of nonius inner lines of fusion target in degrees
        fuseTargetBiasMax = 0.166;          % deviation max of the correct aligned position of the lines from the center in degrees
        fuseTargetJitterMax = 0.166;        % deviation max of the lines at the begining of a trial from the correct position
        adjustmentStep = 0.1;               % step of the adjustment lines in pixels
        
        background = 0.25;
        leftLuminance = 0.45;
        rightLuminance = 1.00;
        
        mouseMovementMult = 0.05; % How much lines should move per pixel of mouse movement
        
        %DrawFusionLock parameters:
        lockWidthDeg = 8.0; % full width of the lock box
        lockSquares = 16;
    end
    
    properties
        % FIXME no longer used; remove this variable
        nAdj = 1;  % number of adjustments tasks in each adjustment subsession
    end
    
    methods
        function [success, result] = runOnce(self)
            % History (oldest at top):
            %   Originally by Baptiste Caziot SUNYOpt 10/2010
            %       Usage: [posInit var] = NoniusAdjustmentTask(E,R,window);
            %           posInit: random positions of the lines at the begining of the
            %           trials
            %           posResp: position of the cursor at the end of the trials
            %           respTime: time to respond
            %           R: A structure holding all information needed to run current trial
            %           E:	A structure containing all parameters for running experiment
            %           window: pointer to window presenting stimuli
            %   Adapted to RDK framework 2013-07-15 by Alex
            %       function [HW, angDisp, fixDisp, bias, posInit, posResp, respTime] = NoniusAdjustmentTask(HW, P, AdjP)
            %       NoniusAdjustmentTask.m  Runs an adjustment task(s) with nonius lines, Adjself.nAdj times in a row.
            %   Adapted to object-oriented framework 2016-01-30 by Alex
            %       classdef NoniusAdjustmentTask < Task

            HWRef = HWReference();
            HW = HWRef.hw;
            
            bias = zeros(1,self.nAdj*2);
            posInit = zeros(1,self.nAdj*2);
            posResp = zeros(1,self.nAdj*2);
            respTime = zeros(1,self.nAdj*2);

            center = 0.5 .* (HW.screenRect([3 4]) - HW.screenRect([1 2]));
            lockWidthPx = self.lockWidthDeg * HW.ppd;

            monWidthPx = HW.screenRect(3) - HW.screenRect(1);
            pixelsPerCM = monWidthPx/HW.monWidth;

            outerW = HW.viewDist*pixelsPerCM*tan((pi/180)*self.outerFuseSize);
            fuseTargetOuter_L = [ center center ] + 0.5*outerW*[-1 -1 1 1];
            fuseTargetOuter_R = fuseTargetOuter_L;

            innerW = HW.viewDist*pixelsPerCM*tan((pi/180)*self.innerFuseSize);
            fuseTargetInner_L = [ center center ] + 0.5*innerW*[-1 -1 1 1];
            fuseTargetInner_R = fuseTargetInner_L;

            outerFuseThicknessPx = HW.viewDist*pixelsPerCM*tan((pi/180)*self.outerFuseThickness);   % thickness of outer fusion square
            fuseLineLengthPx = HW.viewDist*pixelsPerCM*tan((pi/180)*self.fuseLineLength);           % length of inner fusion target lines
            fuseTargetBiasMaxPx = HW.viewDist*pixelsPerCM*tan((pi/180)*self.fuseTargetBiasMax);
            fuseTargetJitterMaxPx = HW.viewDist*pixelsPerCM*tan((pi/180)*self.fuseTargetJitterMax);

            for aa=1:self.nAdj % iteration number
                for oo=1:2 % orientation
                    % set up arrays of squares, colors, pen sizes
                    RectPositions = [fuseTargetOuter_L' fuseTargetOuter_R' fuseTargetInner_L' fuseTargetInner_R'];
                    RectPens = [outerFuseThicknessPx outerFuseThicknessPx self.innerFuseThickness self.innerFuseThickness];

                    idx = 2*(aa-1)+oo;

                    bias(idx) = fuseTargetBiasMaxPx*(2*rand-1);
                    posInit(idx) = fuseTargetJitterMaxPx*(2*rand-1);

                    % set up arrays for inner lines
                    if oo==1
                        L1_x1 = fuseTargetInner_L(1);
                        L1_x2 = fuseTargetInner_L(1)+fuseLineLengthPx;
                        L1_y1 = (fuseTargetInner_L(2)+fuseTargetInner_L(4))/2 + bias(idx) + posInit(idx);
                        L1_y2 = L1_y1;

                        L3_x1 = fuseTargetInner_R(3) - fuseLineLengthPx;
                        L3_x2 = fuseTargetInner_R(3);
                        L3_y1 = (fuseTargetInner_L(2)+fuseTargetInner_L(4))/2 + bias(idx) - posInit(idx);
                        L3_y2 = L3_y1;
                    else
                        L2_x1 = (fuseTargetInner_L(1)+fuseTargetInner_L(3))/2 + bias(idx) + posInit(idx);
                        L2_x2 = L2_x1;
                        L2_y1 = fuseTargetInner_L(2);
                        L2_y2 = fuseTargetInner_L(2) + fuseLineLengthPx;

                        L4_x1 = (fuseTargetInner_R(1)+fuseTargetInner_R(3))/2 + bias(idx) - posInit(idx);
                        L4_x2 = L4_x1;
                        L4_y1 = fuseTargetInner_R(4) - fuseLineLengthPx;
                        L4_y2 = fuseTargetInner_R(4);
                    end
                    
                    % wait until all keys and mouse buttons are released
                    waiting = true;
                    while waiting
                        [~, ~, buttons] = GetMouse();
                        waiting = KbCheck || any(buttons);
                    end
                    
                    shift = 0;
                    timeStart = GetSecs();
                    
                    % Set cursor to (near) the center
                    mousePtr = HW.screenNum;
                    scrCenter = round(0.5*[HW.width HW.height]);
                    scrCtrX = scrCenter(1);
                    scrCtrY = scrCenter(2);
                    SetMouse(scrCtrX, scrCtrY, mousePtr);
                    
                    % Animation / UI loop
                    while 1
                        if oo==1
                            changePos = [0 0 ; shift shift];
                            LinePositionsL = [L1_x1 L1_x2 ; L1_y1 L1_y2] + changePos;
                            LinePositionsR = [L3_x1 L3_x2 ; L3_y1 L3_y2] - changePos;
                        else
                            changePos = [shift shift ; 0 0];
                            LinePositionsL = [L2_x1 L2_x2 ; L2_y1 L2_y2] + changePos;
                            LinePositionsR = [L4_x1 L4_x2 ; L4_y1 L4_y2] - changePos;
                        end

                        % Left eye
                        HW.ScreenCustomStereo('SelectStereoDrawBuffer', HW.winPtr, 0);
                        Screen('FillRect', HW.winPtr, self.background * HW.white);
                        leftLumRaw = HW.white * self.leftLuminance * [1 1 1];
                        Screen('FrameRect',HW.winPtr, leftLumRaw, RectPositions, RectPens);
                        Screen('DrawLines',HW.winPtr, LinePositionsL, self.innerFuseTargetThickness, leftLumRaw, [], 1);

                        % Right eye
                        HW.ScreenCustomStereo('SelectStereoDrawBuffer', HW.winPtr, 1);
                        Screen('FillRect', HW.winPtr, self.background * HW.white);
                        rightLumRaw = HW.white * self.rightLuminance * [1 1 1];
                        Screen('FrameRect',HW.winPtr, rightLumRaw, RectPositions, RectPens);
                        Screen('DrawLines',HW.winPtr, LinePositionsR, self.innerFuseTargetThickness, rightLumRaw, [], 1);

                        DrawFusionLock(center, 0.5*lockWidthPx, self.lockSquares);
                        HW.ScreenCustomStereo('Flip', HW.winPtr);
                        
                        % parse inputs
                        [keyIsDown, ~, keyCode] = KbCheck;
                        if keyIsDown
                            K = find(keyCode==1,1);
                            if K==KbName('return')
                                break
                            elseif oo==1 % vertical changes
                                if K==KbName('2')
                                    shift = shift-self.adjustmentStep;
                                elseif K==KbName('8')
                                    shift = shift+self.adjustmentStep;
                                end
                            elseif oo==2 % horizontal changes
                                if K==KbName('4')
                                    shift = shift-self.adjustmentStep;
                                elseif K==KbName('6')
                                    shift = shift+self.adjustmentStep;
                                end
                            end
                        end
                        
                        % Look for displacement in mouse, then reset it
                        [mouseX, mouseY, buttons] = GetMouse(mousePtr);
                        mouseVec = [mouseX - scrCtrX, mouseY - scrCtrY];
                        if buttons(1)==1
                            break
                        elseif oo==1 % vertical changes
                            shift = shift + mouseVec(2)*self.mouseMovementMult;
                        elseif oo==2 % horizontal changes
                            shift = shift + mouseVec(1)*self.mouseMovementMult;
                        end
                        SetMouse(scrCtrX, scrCtrY, mousePtr);
                    end

                    posResp(idx) = shift;
                    respTime(idx) = GetSecs() - timeStart;
                end
            end
            fixDisp = posInit + posResp;
            angDisp = 2.0 ./ HW.ppd .* fixDisp;
            
            for i = 1:length(fixDisp)
                fprintf('Fixation Disparity: %+6.2f px (%+5.2f�)\n', ...
                    fixDisp(i), angDisp(i));
            end
            success = true;
            result = [angDisp, fixDisp, bias, posInit, posResp, respTime];
            
            self.Completed = true;
            self.Result = result;

            self.runOnce@Task();
        end
        
        % Returns: a cell array of each result object, in the order they
        %   were run.
        function [results] = collectResults(task)
            error('Not yet implemented');
        end
    end
    
    % === Flatfile handling functions ===
    methods(Static)
        function columns = getColumns()
            columns = [getColumns@Task(), ...
                {'Fixation Disparity (deg) vertical', 'Fixation Disparity (deg) horizontal', ...
                'Fixation Disparity (px) vertical', 'Fixation Disparity (px) horizontal', ...
                'Off-center bias (px) vertical', 'Off-center bias (px) horizontal', ...
                'Initial Disparity Position (px) vertical', 'Initial Disparity Position (px) horizontal', ...
                'Response Position (px) vertical','Response Position (px) horizontal',...
                'Response Time (s) vertical', 'Response Time (s) horizontal'}];
        end
    end
    
    methods
        function data = collectFlatData(t)
            data = [t.collectFlatData@Task(), t.Result];
        end
    end

end
