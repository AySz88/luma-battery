classdef DataFile < handle
    %DATAFILE Helper class for data logging, intended to create CSVs
    
    properties
        data % matrix storing the data written to the file so far
        fileHandle
    end
    
    properties(Constant)
        % Folder for storing all data files
        DEFAULT_SUBFOLDER = ['data' filesep];
        DEFAULT_FILENAME = 'data.csv';
    end
    
    methods(Static)
        % Creates a sensible default path and filename
        % Will use a session subfolder w/ timestamp in it, by default
        function path = defaultPath(sessionID)
            if nargin < 1 || isempty(sessionID)
                curdate30 = datestr(now, 30);   % Current time in standard format: 'yyyymmddTHHMMSS' (ISO 8601)
                path = [DataFile.DEFAULT_SUBFOLDER curdate30 filesep DataFile.DEFAULT_FILENAME];
            else
                curdate = datestr(now, 'yyyy_mm_dd');   % 'yyyy-mm-dd' format. Used here for naming the data directory.
                path = [DataFile.DEFAULT_SUBFOLDER curdate filesep sessionID '.csv'];
            end
        end
    end
    
    methods
        % Constructor: Open and prepare a new data file
        function df = DataFile(path, columns, metadata)
            % Check inputs
            if isempty(path)
                path = DataFile.defaultPath();
            end
            
            if exist(path, 'file')
                warning('File %s already exists! Will append to end.', path);
            end
            
            % if isempty(columns) ... throw exception?
            
            if nargin < 3
                metadata = [];
            end
            % ensure metadata ends with a new-line (if it exists)
            newline = sprintf('\n');
            if ~isempty(metadata)
                if strcmpi(newline, metadata(end))
                    metadata(end+1) = newline;
                end
            end
            
            % Initialize internal storage of data
            df.data = [];
            
            % Initialize any required folders not yet created
            [folderName, ~, ~] = fileparts(path);
            if ~isempty(folderName)
                if ~exist(folderName, 'dir')
                    mkdir(folderName);
                end
            end
            
            % Open file and write header lines
            df.fileHandle = fopen(path, 'a');
            fprintf(df.fileHandle, metadata);
            if length(columns) > 1
                fprintf(df.fileHandle, '%s,', columns{1:end-1});
            end
            fprintf(df.fileHandle, '%s\n', columns{end});
        end
        
        % Add and save a new line of data (numeric vector)
        function append(df, newData)
            df.data = [df.data; newData];
            
            % Append commas after all but the last element in the line, and
            % then a newline afterwards
            if length(newData) > 1
                fprintf(df.fileHandle, '%f,', newData(1:end-1));
            end
            fprintf(df.fileHandle, '%f\n', newData(end));
        end
        
        % Destructor: close the file
        % (caution: any exceptions here will silently terminate the
        % function!)
        function delete(df) % for deleting this handle, not the file!
            fileName = fopen(df.fileHandle);
            if ~isempty(fileName) % if file is still open
                fclose(df.fileHandle);
            end
        end
    end
    
end

