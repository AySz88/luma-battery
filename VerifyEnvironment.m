%% Ensure environment is as expected
% TODO put this into HardwareSetup?

if ~exist('Screen', 'file')
    fprintf('No PTB installed!');
end
PTBInfo = Screen('Version');
PTBCompInfo = Screen('Computer');
fprintf('=== PTB/Matlab Environment Information ===\n');
fprintf('%s %s\n', PTBInfo.date, PTBInfo.time);
fprintf('Running PTB project %s\n', PTBInfo.project);
fprintf('Running PTB version %s\n', PTBInfo.version);
fprintf('Operating system: %s : %s\n', PTBInfo.os, PTBCompInfo.system);
fprintf('PTB support level is: %s\n', PTBCompInfo.supported);
fprintf('M-file interpreter: %s\n', PTBInfo.language);
fprintf('\n');
    
try
    [ hasChanges, output ] = GitChangeCheck( );

    if hasChanges
        contConfirmed = false;
        fprintf('===== Git repository status output =====\n');
        fprintf('%s\n\n', output);
        
        while ~contConfirmed
            contStr = input(['Untracked code changes detected! \n'...
                'Details above. This may indicate that temporary or\n' ...
                ' test changes have been accidentally left in this\n'...
                ' copy of the code.\n'...
                ' Continue anyway? '], 's');
            switch contStr
                case {'n', 'no'}
                    return % stop script!
                case {'y', 'yes'}
                    contConfirmed = true;
                otherwise
                    fprintf('**Huh? Try ''y'' or ''n''...\n');
            end
        end
    end
catch e
    switch e.identifier
        case 'GitChangeCheck:gitNotInstalled'
            warning(['Could not verify with git that code has ' ...
                ' not been changed from expected!']);
            fprintf(['Please make sure any temporary changes have'...
                ' been removed.  Press Ctrl-C to stop, or any other key'...
                ' to continue...\n']);
            pause();
        otherwise
            rethrow(e)
    end
end
