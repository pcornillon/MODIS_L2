function varargout = ncinfovars(varargin)
    %#ok<*AGROW>

    % If no input args, pick example file shipped with MATLAB.
    if ~nargin
        varargin{1} = "example.nc";
    end
    
    assert(exist(varargin{1}, "file"), "File not found : %s", varargin{1});

    % Get ncinfo, flatten using recursive crawler, and conver to table.
    try
        info = ncinfo(varargin{:});
    catch ME
        error("ncinfo failed on file : %s\n%s", varargin{1}, ME.message);
    end
    flatInfo = crawler("", info);
    T = struct2table(flatInfo);

    % Convert content to categoricals for display purpose (no "", {}, ..).
    for k = 1 : numel(T.Properties.VariableNames)
        varName = T.Properties.VariableNames{k};
        T.(varName) = categorical(T.(varName));
    end
    
    % Display or output, depending on the presence of an output arg.
    if nargout
        varargout = {T};
    else
        varargout = cell(0);
        fprintf(newline);
        disp(T);
    end
end

function flatInfo = crawler(dataPath, info)
    %crawler Recursive info struct analyzer/flattener.

    flatInfo = struct("Path", {}, "Name", {}, "Datatype", {}, ...
        "Size", {}, "Dimensions", {});

    % Get specs of variables in current group.
    for varIx = 1 : numel(info.Variables)
        varData = info.Variables(varIx);
        S.Path = dataPath + info.Name;
        S.Name = string(varData.Name);
        S.Datatype= string(varData.Datatype);
        if isscalar(varData.Size)
            varData.Size = [varData.Size, 1];
        end
        S.Size = strjoin(string(varData.Size), "x");
        if isempty(varData.Dimensions)
            S.Dimensions = "";
        else
            S.Dimensions = strjoin(string({varData.Dimensions.Name}) + ...
                ":" + string({varData.Dimensions.Length}), ", ");
        end
        flatInfo(varIx) = S;
    end

    % Recurse over groups and append flat info.
    for grpIx = 1 : numel(info.Groups)
        flatInfo = [flatInfo, crawler(dataPath + "/", info.Groups(grpIx))];
    end    
end
