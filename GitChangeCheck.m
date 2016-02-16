function [ hasChanges, output ] = GitChangeCheck( )
%GITCHANGECHECK Checks whether there is uncommitted code in the pwd
%   This is intended to help catch accidental temporary edits that should
%   have been reverted.
%
%   Uses git commands (log, status, diff) and stores the output.
%   Will throw an error if git (command line) is not installed

% Active version of the code, as a git revision
[logStatusCode, headLogOutput] = system('git log HEAD -1');

assert(logStatusCode == 0, 'GitChangeCheck:gitNotInstalled', ...
    ['The command ''git log HEAD -1'' failed! ' ...
    ' Has git (command line) been installed on this machine?']);

% 'git status --porcelain' produces a short summary of what changes exist
% (i.e. files changed, added, removed...)
[~, statusOutput] = system('git status --porcelain');

hasChanges = ~isempty(statusOutput);

if hasChanges
    % 'git diff' produces the current differences in the pwd
    [~, diffOutput] = system('git diff');
    output = sprintf(['=== Active commit ===\n'...
                      '%s\n'...
                      '=== File statuses ===\n'...
                      '%s\n'...
                      '=== Differences ===\n'...
                      '%s\n'],...
                      headLogOutput, statusOutput, diffOutput);
else
    output = sprintf(['=== Active commit ===\n'...
                      '%s\n'...
                      '=== (No differences) ===\n'],...
                      headLogOutput);
end

end

