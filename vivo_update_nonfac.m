function [status] = vivo_update_nonfac()

if ispc==1
    if exist('D:/Seafile/VIVO_Secure_Data/','dir')==7
        top_path = 'D:\Seafile\VIVO_Secure_Data\';
        load_path = 'D:\OneDrive\OneDrive - McMaster University\';
    elseif exist('C:\MacDrive\Seafile\VIVO_Secure_Data\','dir')==7      % Gabriela, you can add in your path here
        top_path = 'C:\MacDrive\Seafile\VIVO_Secure_Data\';                    % Gabriela, you can add in your path here
    else
        disp('Starting path not assigned. See line ~20 Exiting'); return;
    end
else
    top_path = '/home/brodeujj/Seafile/VIVO_Secure_Data/';
end

nonfac_path = [top_path '02_NonFacultyUsers\']; % location of non-faculty-users list

%% Step 1: Load the non-faculty users file and the excel sheet of submitted information:

%%%% users file
[headers_nf,dw_nf] = sheet2cell([nonfac_path 'NonFacultyUsers-current.tsv'],'\t',1);
% Remove quotation marks (causes issues):
dw_nf = strrep(dw_nf,'"','');
headers_nf = strrep(headers_nf,'"','');

% %%% Make a numeric list of all employee numbers in the non-faculty list
% % for i = 1:1:size(dw_nf,1)
% %     nf_ids(i,1) = str2num(dw_nf{i,1});
% % end
% nf_ids = cellfun(@str2num,dw_nf(:,strcmp(headers_nf(:,1),'ID')==1));

%% Step 2: Load the submissions file
%%% Make a temporary copy of the submissions file:
copyfile([load_path 'Elements_NonFaculty_Accounts.xlsx'],[nonfac_path 'tmp.xlsx']);
%%% Use a VB script to convert the xlsx to a csv file. This is necessary
%%% because the xlsx file contains special markup, which has something to
%%% do with the fact that it's connected to an online form.
% see here: https://stackoverflow.com/questions/1858195/convert-xls-to-csv-on-command-line
cd([top_path 'VIVO-DW-Tools\matlab_libraries\']);
[status,cmdout] = dos(['XlsToCsv.vbs "' nonfac_path 'tmp.xlsx" "' nonfac_path 'tmp.csv"']);

%%% Load the submitted data:
[headers_form,formdata] = sheet2cell([nonfac_path 'tmp.csv'],',',1);
formdata = strrep(formdata,'"','');
headers_form = strrep(headers_form,'"','');
%%% Delete the temp files:
dos(['del "' nonfac_path 'tmp.xlsx"']);
dos(['del "' nonfac_path 'tmp.csv"']);

%%% Identify columns
fname_col = find(strncmp(headers_form(:,1),'First Name',length('First Name'))==1);
lname_col = find(strncmp(headers_form(:,1),'Last Name',length('Last Name'))==1);
macid_col = find(strncmp(headers_form(:,1),'MAC ID',length('MAC ID'))==1);
email_col = find(strncmp(headers_form(:,1),'McMaster email address',length('McMaster email address'))==1);
emplnum_col = find(strncmp(headers_form(:,1),'McMaster Employee number',length('McMaster Employee number'))==1);
fac_col = find(strncmp(headers_form(:,1),'Please indicate the Faculty',length('Please indicate the Faculty'))==1);
profile_col = find(strncmp(headers_form(:,1),'In addition to creating an account',length('In addition to creating an account'))==1);
title_col = find(strncmp(headers_form(:,1),'Your position title (optional)',length('Your position title (optional)'))==1);


%% Clean up the data from submissions file, add it to the non-faculty users file
% dw_nf_row = size(dw_nf,1)+1;
for i = 1:1:size(formdata,1)
    emplnum_tmp = str2num(formdata{i,emplnum_col});
    % %%% Make a numeric list of all employee numbers in the non-faculty list
    clear nf_ids;    nf_ids = cellfun(@str2num,dw_nf(:,strcmp(headers_nf(:,1),'ID')==1));

    try
        %%% Continue of there is information for macid, email and employee
        %%% number
        if isempty(formdata{i,macid_col})==0 && isempty(formdata{i,email_col})==0 && isempty(formdata{i,emplnum_col})==0
        
        % Check MAC ID for a valid format (no '@')
            is_at = strfind(formdata{i,macid_col},'@');
            if ~isempty(is_at)==1
                tmp = formdata{i,macid_col};
                tmp = tmp(1:is_at-1);
                formdata{i,macid_col} = tmp;
            end
        
        %%% Check for match with existing non-faculty file:
        ind_match = find(nf_ids==emplnum_tmp);
        if isempty(find(nf_ids==emplnum_tmp))==1 % if there is no ID number match in the current NF file then write to a new row
            dw_nf_row = size(dw_nf,1)+1;
            action = ' added to ';
        else % if it does exist, we'll be editing the existing row:
            dw_nf_row = ind_match;
            action = ' updated in ';
        end

            %%%%% % Write it to our non-faculty list
            % Ensure that employee ID is 9-digits
            tmp3 = formdata{i,emplnum_col};
            if  numel(tmp3) < 9
                formdata{i,emplnum_col} = [repmat('0',1,9-numel(tmp3)) tmp3];
                disp(['Corrected non-faculty employee id ' tmp3 ' to ' formdata{i,emplnum_col}]);
            end
            dw_nf{dw_nf_row,strcmp(headers_nf(:,1),'ID')==1} = formdata{i,emplnum_col};
            dw_nf{dw_nf_row,strcmp(headers_nf(:,1),'MAC ID')==1} = formdata{i,macid_col};
            dw_nf{dw_nf_row,strcmp(headers_nf(:,1),'PRF First Name')==1} = formdata{i,fname_col};
            dw_nf{dw_nf_row,strcmp(headers_nf(:,1),'PRF Last Name')==1} = formdata{i,lname_col};
            %%% Check to see if the individual has asked for a profile to
            %%% be created. If yes, put them in their faculty. If not,
            %%% place them in "ExcludeFromVIVO"
            if strncmp(formdata{i,profile_col},'Yes',3)==1
            dw_nf{dw_nf_row,strcmp(headers_nf(:,1),'Faculty')==1} = formdata{i,fac_col};
            else
            dw_nf{dw_nf_row,strcmp(headers_nf(:,1),'Faculty')==1} = 'ExcludeFromVIVO';
            end
            dw_nf{dw_nf_row,strcmp(headers_nf(:,1),'Email addr')==1} = formdata{i,email_col};
            dw_nf{dw_nf_row,strcmp(headers_nf(:,1),'Position')==1} = formdata{i,title_col}; % Position Title
            
            disp(['Individual ' formdata{i,lname_col} ', ' formdata{i,fname_col} action 'non-faculty file.']);
%             dw_nf_row = dw_nf_row +1;
        else
            disp(['Individual ' formdata{i,lname_col} ', ' formdata{i,fname_col} ' NOT added to non-faculty file.']);
        end
    catch
    end
end

%% Save the non-faculty file:

%%% Make a backup copy
copyfile([nonfac_path 'NonFacultyUsers-current.tsv'],[nonfac_path 'NonFacultyUsers-backup-' datestr(now,30) '.tsv'])

%%% Save (overwrite the non-fac file)
fid_out = fopen([nonfac_path 'NonFacultyUsers-current.tsv'],'w');
tmp = sprintf('%s\t',headers_nf{:});
fprintf(fid_out,'%s\n',tmp);
for i = 1:1:size(dw_nf,1)
    fprintf(fid_out,'%s\n',sprintf('%s\t',dw_nf{i,:}));
end
fclose(fid_out);




