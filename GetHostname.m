function [ host ] = GetHostname()
%GETHOSTNAME produces the computer's hostname
% contains some cross-platform checks

[status, host] = system('hostname');

if status > 0 % failure
    if ispc(), host = getenv('COMPUTERNAME');
    else host = getenv('HOSTNAME');
    end
end

host = strtrim(host);

end

