function [] = vivo_update_and_process()

%% Set the starting path:
if ispc==1
    VIVO_PROD_path = '\\ads.mcmaster.ca\mosaic\Docs\DWInterfaces\PRD\VIVO';
    top_path = 'D:/Seafile/VIVO_Secure_Data/';
else
end
copy_path = [top_path '01_DW_Extracted']; % location of 'raw' data file
class_path = [top_path '01_DW_Teaching'];

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

%% Run vivo_clean_dw
vivo_clean_dw(faculty_file_ver);
vivo_prepare_elementsHR(faculty_file_ver);