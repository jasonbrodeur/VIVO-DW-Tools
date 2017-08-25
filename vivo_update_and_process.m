function [] = vivo_update_and_process(automated_flag)
if nargin<1
    automated_flag = 0; %sets the automated flag to 0 
end

%% Set the starting path:
if ispc==1
    VIVO_PROD_path = '\\ads.mcmaster.ca\mosaic\Docs\DWInterfaces\PRD\VIVO';
    top_path = 'D:/Seafile/VIVO_Secure_Data/';
else
end
copy_path = [top_path '01_DW_Extracted']; % location of 'raw' data file
class_path = [top_path '01_DW_Teaching'];
output_path = [top_path '03_Processed_For_Elements']; % output path

%% Try and copy the newest FACULTY file to the 01_DW_Extracted directory
d_prod = dir(VIVO_PROD_path);
tmp = (struct2cell(d_prod))';

%%%%%%%%%%%%%%%%%%%% Establish the most recent version of the FACULTY file:
% tmp2 = tmp(
file_vers = nan.*ones(size(tmp,1),1);
ind1 = find(strncmp('MCM_VIVO_ALL_FACULTY-',tmp(:,1),length('MCM_VIVO_ALL_FACULTY-'))==1);
for i = 1:1:size(ind1,1)
    tmp2 = tmp{ind1(i),1};
    file_vers(ind1(i),1) = str2num(tmp2(strfind(tmp2,'-')+1:strfind(tmp2,'.')-1));
    tmp{ind1(i),6} = str2num(tmp2(strfind(tmp2,'-')+1:strfind(tmp2,'.')-1));
end

ind_right_file = find(file_vers(:,1)==max(file_vers(:,1)));
faculty_file_ver = file_vers(ind_right_file,1);
%%%%%%%%%%%%%%%%%%%%% Move the files over to copy_path
if ~isempty(ind_right_file)==1
    [status] = copyfile([VIVO_PROD_path '\' tmp{ind_right_file,1}],[copy_path '\' tmp{ind_right_file,1}]);
    if status == 1
        disp(['copied over file: ' tmp{ind_right_file,1} ' to ' copy_path]);
    else
        disp(['ERROR copying file: ' tmp{ind_right_file,1} ' to ' copy_path]);
    end
else
    disp('File transfer didn''t work -- can''t find the most recent FACULTY file.')
end

clear ind_right_file tmp2 file_vers ind*
%% Try and copy the newest CLASS file to the 01_DW_Teaching directory

%%%%%%%%%%%%%%%%%%%% Establish the most recent version of the FACULTY file:
% tmp2 = tmp(
file_vers = nan.*ones(size(tmp,1),1);
ind1 = find(strncmp('MCM_VIVO_CLASS-',tmp(:,1),length('MCM_VIVO_CLASS-'))==1);
for i = 1:1:size(ind1,1)
    tmp2 = tmp{ind1(i),1};
    file_vers(ind1(i),1) = str2num(tmp2(strfind(tmp2,'-')+1:strfind(tmp2,'.')-1));
    tmp{ind1(i),6} = str2num(tmp2(strfind(tmp2,'-')+1:strfind(tmp2,'.')-1));
end

ind_right_file = find(file_vers(:,1)==max(file_vers(:,1)));

%%%%%%%%%%%%%%%%%%%%% Move the files over to copy_path
if ~isempty(ind_right_file)==1
    [status] = copyfile([VIVO_PROD_path '\' tmp{ind_right_file,1}],[class_path '\' tmp{ind_right_file,1}]);
    if status == 1
        disp(['copied over file: ' tmp{ind_right_file,1} ' to ' class_path]);
    else
        disp(['ERROR copying file: ' tmp{ind_right_file,1} ' to ' class_path]);
    end
else
    disp('File transfer didn''t work -- can''t find the most recent CLASS file.')
end

clear tmp
%% Run vivo_clean_dw and vivo_prepare_elementsHR
disp('Running vivo_clean_dw')
vivo_clean_dw(faculty_file_ver);
disp('Running vivo_prepare_elementsHR')
vivo_prepare_elementsHR(faculty_file_ver,automated_flag);

%% Figure out which is the next to most recent version that has been created; run diff
disp('Running vivo_HR_diff')

d_out = dir(output_path);
tmp_out = (struct2cell(d_out))';

file_vers = nan.*ones(size(tmp_out,1),1);
ind1 = find(strncmp('McM_HR_import-',tmp_out(:,1),length('McM_HR_import-'))==1);
for i = 1:1:size(ind1,1)
    tmp2 = tmp_out{ind1(i),1};
    try
    file_vers(ind1(i),1) = str2num(tmp2(strfind(tmp2,'-')+1:strfind(tmp2,'.csv')-1));
    tmp_out{ind1(i),6} = str2num(tmp2(strfind(tmp2,'-')+1:strfind(tmp2,'.')-1));
    catch
    file_vers(ind1(i),1) = NaN;
    tmp_out{ind1(i),6} = NaN;
    end
end

file_vers = sort(file_vers(~isnan(file_vers)),'descend');
faculty_file_ver_old = file_vers(2);
faculty_file_ver = file_vers(1);
add_remove_flag = vivo_HR_diff(faculty_file_ver,faculty_file_ver_old);
%% Send an email to the project data team
% to = {'brodeujj@mcmaster.ca','mirceag@mcmaster.ca'};
recipients = {'brodeujj@mcmaster.ca';'mirceag@mcmaster.ca'};
subject = 'DW HR data processing for Elements - report';
body = ['The HR data processing has run. A new file with version ' num2str(faculty_file_ver) ' has been created. ' sprintf('\n')...
    'Please investigate the data report in /02_DW_cleaned/ and the diff files in /03_Prepared_For_Elements/.' sprintf('\n')];

if automated_flag ==1
   switch add_remove_flag
       case 1
    body = [body 'WARNING: An individual was removed and re-added to the HR file with different MacIDs or employee numbers. Investigate.' sprintf('\n')];
       case 2
       body = [body 'WARNING: More than 200 individuals were added and/or removed. Investigate.' sprintf('\n')];
       case 3
       body = [body 'WARNING: An individual was removed and re-added to the HR file with different MacIDs or employee numbers AND more than 200 individuals were added and/or removed. Investigate.' sprintf('\n')];
   end
   for i = 1:1:size(recipients,1)
   sendolmail(recipients{i,1},subject,body);
   end
end