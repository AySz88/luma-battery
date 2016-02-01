classdef NoniusAdjustmentTask < Task
    
    properties
        nAdj = 3;                   % number of adjustments tasks in each adjustment subsession
        outerFuseSize = 6.0;                % length of side of outer fusion square (around simulus) in degrees
        outerFuseThickness = 0.3;           % thickness of outer fusion square lines in degrees
        innerFuseSize = 1.8;                % length of size of inner fusion square in degrees
        innerFuseThickness = 6 ;         	% thickness of inner fusion square lines in pixels
        innerFuseTargetThickness = 6 ;    	% thickness of nonius fusion target lines in pixels
        fuseLineLength = 0.4;               % length of nonius inner lines of fusion target in degrees
        fuseTargetBiasMax = 0.166;          % deviation max of the correct aligned position of the lines from the center in degrees
        fuseTargetJitterMax = 0.166;        % deviation max of the lines at the begining of a trial from the correct position
        adjustmentStep = 0.1;               % step of the adjustment lines in pixels
    end

    methods
        function [success, result] = runOnce(self)
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
            %       NoniusAdjustmentTask.m  Runs an adjustment task(s) with nonius lines, AdjP.nAdj times in a row.
            %   Adapted to object-oriented framework 2016-01-30 by Alex
            %       classdef NoniusAdjustmentTask < Task

            HWRef = HWReference();
            HW = HWRef.hw;
            
            bias = zeros(1,self.nAdj*2);
            posInit = zeros(1,self.nAdj*2);
            posResp = zeros(1,self.nAdj*2);
            respTime = zeros(1,self.nAdj*2);

            center = 0.5 .* (HW.screenRect([3 4]) - HW.screenRect([1 2]));
            lockWidthPx = P.lockWidthDeg * HW.ppd;

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

                    while KbCheck; end % wait until no key pressed
                    shift = 0;
                    timeStart = GetSecs();

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
                        HW = ScreenCustomStereo(HW, 'SelectStereoDrawBuffer', HW.winPtr, 0);
                        Screen('FillRect', HW.winPtr, P.background);
                        Screen('FrameRect',HW.winPtr, P.leftLuminance*[1 1 1], RectPositions, RectPens);
                        Screen('DrawLines',HW.winPtr, LinePositionsL, self.innerFuseTargetThickness, P.leftLuminance*[1 1 1], [], 1);

                        % Right eye
                        HW = ScreenCustomStereo(HW, 'SelectStereoDrawBuffer', HW.winPtr, 1);
                        Screen('FillRect', HW.winPtr, P.background);
                        Screen('FrameRect',HW.winPtr, P.rightLuminance*[1 1 1], RectPositions, RectPens);
                        Screen('DrawLines',HW.winPtr, LinePositionsR, self.innerFuseTargetThickness, P.rightLuminance*[1 1 1], [], 1);

                        %HW = DrawFusionLock(HW, center, 0.5*lockWidthPx, P.lockSquares);
                        HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr);

                        [keyIsDown, ~, keyCode] = KbCheck;
                        if keyIsDown
                            K = find(keyCode==1,1);
                            if K==KbName('return')
                                break
                            elseif oo==1 
                                if K==KbName('2')
                                    shift = shift-self.adjustmentStep;
                                elseif K==KbName('8')
                                    shift = shift+self.adjustmentStep;
                                end
                            elseif oo==2
                               if K==KbName('4')
                                    shift = shift-self.adjustmentStep;
                               elseif K==KbName('6')
                                    shift = shift+self.adjustmentStep;
                               end
                            end
                        end
                    end

                    posResp(idx) = shift;
                    respTime(idx) = GetSecs() - timeStart;
                end
            end
            fixDisp = posInit + posResp
            angDisp = 2.0 ./ HW.ppd .* fixDisp

            success = true;
            result = [angDisp, fixDisp, bias, posInit, posResp, respTime];
        end
        
        % Returns whether the task(s) have been completed
        function value = completed(task)
        end
        
        % Returns: a cell array of each result object, in the order they
        %   were run.
        function [results] = collectResults(task)
        end
    end

end