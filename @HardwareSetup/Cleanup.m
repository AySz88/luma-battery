function [ ] = Cleanup( HW )
%CLEANUP Cleans up screens and re-enables keyboard in MATLAB


%   If you call InitializeHardware, it is your responsibility to call this
%   this function before you exit, even there were errors!

    assert(nargin >= 1, 'Cleanup:NoParameter', ...
        'Need a hardware parameter struct, but none passed in!');
    
    %TODO not guaranteed that the HW passed out from here will actually be
    %   properly saved and passed back up, and in such a case this warning
    %   won't be triggered!
    %   Use ref's/pointers (make HW a class deriving from handle) to fix?
%     assert(isfield(HW, 'initialized') && HW.initialized, ...
%         'CleanupHardware:NoInitializedHW', ...
%         ['An initialized HW struct was not passed in! The real error'...
%         ' is probably that some other function called me when it'...
%         ' shouldn''t have done so.  *** Please ONLY have a function' ...
%         ' call CleanupHardware if the SAME function initialized' ...
%         ' it earlier (and gets didHWInit == true). *** Other functions' ...
%         ' might still need the hardware to be ready!']);
    
    Screen('CloseAll');
    ListenChar(0);
    
    try PsychPortAudio('Close'); catch, end;
    
    ShowCursor();
    
    HW.initialized = false;
end

