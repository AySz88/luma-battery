function DrawFusionLock(center, halfLockWidPx, lockSquares, lockColors)
%DRAWFUSIONLOCK Draws fusion lock into the current window
% Fusion lock is a checkered frame of 'lockSquares' squares on each side,
% centered at 'center' with width 2*halfLockWdPx.

% TODO maybe faster to draw into a tiny texture with alpha channel?
% size: lockSquares on each side
% each square is just a pixel
% then draw texture at proper width and location

    HWRef = HWReference();
    HW = HWRef.hw;

    if lockSquares == 0 || halfLockWidPx <= 0
        return % skip
    end
    
    if nargin < 5 || isempty(lockColors)
        lockColors = HW.white * [0 1; 0 1];
    end
    
    squareSize = 2.0/lockSquares * halfLockWidPx;
    topLeftCenter = center ...
                    - [halfLockWidPx, halfLockWidPx] ...
                    + 0.5*[squareSize squareSize];
    setWidth = (lockSquares-1.0) * squareSize;
    
    % tttr % t = top set, r = right set, etc.
    % l  r
    % l  r
    % lbbb
    top = (0:lockSquares-2)' * [squareSize 0];
    left = (1:lockSquares-1)' * [0 squareSize];
    right = left + repmat([setWidth, -squareSize], lockSquares-1, 1);
    bottom = top + repmat([squareSize, setWidth], lockSquares-1, 1);
    
    % every square's center, clockwise from top-left, relative to top-left
    coords = [top; right; bottom(end:-1:1,:); left(end:-1:1,:)];
    
    for i=0:1
        HW.ScreenCustomStereo('SelectStereoDrawBuffer', HW.winPtr, i);
        
        darkerColor = lockColors(i+1, 1);
        lighterColor = lockColors(i+1, 2);
        
        dark = false;
        for coordIdx = 1:(4*(lockSquares-1))
            currCoord = topLeftCenter + coords(coordIdx, :);
            if dark
                color = darkerColor;
            else
                color = lighterColor;
            end
            rect = [currCoord-0.5*squareSize, currCoord+0.5*squareSize];
            Screen('FillRect', HW.winPtr, color, rect);
            dark = ~dark;
        end
    end
end
