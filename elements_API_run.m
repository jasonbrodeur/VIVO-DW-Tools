function [] = elements_API_run(sys)
% elements_API_run.m 
% This function pushes updated information to Elements using the API.
% Currently, this function only pushes phone number information, but could
% be expanded to push across other information. 
% Input arguments:
% sys ('DEV' or 'PROD') -- indicates the system for upload.
%
%
% Relevant Documentation:
% https://support.symplectic.co.uk/support/solutions/articles/6000050010-api-user-guide
% https://support.symplectic.co.uk/support/solutions/articles/6000170777-api-v5-5-resources-and-operations
% https://support.symplectic.co.uk/support/solutions/articles/6000170776-api-v5-5-requests-and-responses


%%% verify that proper input argument is provided
sys = upper(sys);
switch sys
    case {'PROD','DEV'}
        disp(['Updating information to system: ' sys]);
    otherwise
        disp('Input argument of either ''DEV'' or ''PROD'' required. Exiting.');
        return;
end
%% Set paths
if ispc==1
    if exist('D:/Seafile/VIVO_Secure_Data/','dir')==7
        top_path = 'D:/Seafile/VIVO_Secure_Data/';
        HRadd_path = 'D:\Seafile\VIVO_Pilot_Project\Elements\Weekly_Faculty_Additions\';
    elseif exist('C:\MacDrive\Seafile\VIVO_Secure_Data\','dir')==7      % Gabriela, you can add in your path here
        top_path = 'C:\MacDrive\Seafile\VIVO_Secure_Data\';                    % Gabriela, you can add in your path here
        HRadd_path = '';%'D:\Seafile\VIVO_Pilot_Project\Elements\Weekly_Faculty_Additions\';% Gabriela, you can add in your path here
    else
        disp('Starting path not assigned. See line ~20 Exiting'); return;
    end
else
    top_path = '/home/brodeujj/Seafile/VIVO_Secure_Data/';
end

% lut_path = [top_path 'VIVO-DW-Tools/lookup_tables']; % lookup table path
% load_path = [top_path '02_DW_Cleaned']; % cleaned data path
load_path = [top_path '03_Processed_For_Elements']; % output path
output_path = [top_path 'Elements_API_upload_logs']; % location of 'raw' data file

%%% Open Report:
fid_report = fopen([output_path '/API-' upper(sys) '-upload-report' datestr(now,30) '.txt'],'w');

%% Load secrets file:
load([top_path 'VIVO-DW-Tools/secrets.mat']);
KeyValue = secrets.API.KeyValue;


%% Load and format the current HR import data:
fid1 = fopen([load_path '/McM_HR_import_current.tsv'],'r');
tline = fgetl(fid1);
frewind(fid1);
numcols2 = length(regexp(tline,'\t'))+1;
formatspec = repmat('%s',1,numcols2);
C = textscan(fid1,formatspec,'Delimiter','\t');
fclose(fid1);

% Remove quotation marks:
for pp = 1:1:size(C,2)
    isString = cellfun('isclass', C{1,pp}, 'char');
    C{1,pp}(isString) = strrep(C{1,pp}(isString), '"', '');
end

%%% Extract headers
for i = 1:1:numcols2
    % headers{i,1} = C{1,i}(1,1){1,1};
    headers{i,1} = C{1,i}{1,1};%{1,1};
    dw(:,i) = C{1,i}(2:end,1);
end
clear C;

%% Ingest phone numbers using elements_update_phone.m
% phone numbers are in [Generic12]
phone_num_col = find(strcmp('[Generic12]',headers(:,1))==1);
macid_col = find(strcmp('[Username]',headers(:,1))==1);

for i = 1:1:size(dw,1)
    phone_num = dw{i,phone_num_col};
    uname = dw{i,macid_col};
    if ~isempty(phone_num)
        %         phone_num = strrep(phone_num,'"','');
        try
            [response] = elements_update_phone(uname, phone_num,KeyValue,sys);
            disp(['Phone number updated for user: ' uname]);
            fprintf(fid_report,'%s\n',['Phone number updated for user: ' uname]);
            pause(0.2);
        catch
            disp(['Error updating phone number for user: ' uname]);
            fprintf(fid_report,'%s\n',['Phone number updated for user: ' uname]);
            pause(0.5);
        end
    else
        disp(['Phone number NOT updated for user: ' uname]);
    end
end
fclose(fid_report);
