function [ hasChanges, output ] = GitChangeCheck( )
%GITCHANGECHECK Checks whether code has been modified from
%   Detailed explanation goes here

[logStatusCode, headLogOutput] = system('git log HEAD -1');

[statusCode, statusOutput] = system('git status --porcelain');
[diffStatusCode, diffOutput] = system('git diff');

output = sprintf(['==== Active commit ====\n'...
                  '%s\n'...
                  '==== File statuses ====\n'...
                  '%s\n'...
                  '==== Differences ====\n'...
                  '%s\n'],...
                  headLogOutput, statusOutput, diffOutput);
statusCode
logStatusCode
diffStatusCode
output

hasChanges = true;

end

