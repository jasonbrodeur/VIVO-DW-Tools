function [add_remove_flag] = vivo_HR_diff(v1, v2)
% vivo_HR_diff.m - Performs a differential comparison between two versions of MCM_HR_import_current files.
% usage: vivo_HR_diff(v1, v2), where v1 and v2 are version numbers (e.g. 66128, 73302). 
% v1 = 66128;
% v2 = 73302;
%% 
if ispc==1
    if exist('D:/Seafile/VIVO_Secure_Data/','dir')==7
        top_path = 'D:/Seafile/VIVO_Secure_Data/';
    elseif exist('C:\MacDrive\Seafile\VIVO_Secure_Data\','dir')==7      % Gabriela, you can add in your path here
        top_path = 'C:\MacDrive\Seafile\VIVO_Secure_Data\';                    % Gabriela, you can add in your path here
    else
        disp('Starting path not assigned. See line ~20 Exiting'); return;
    end
else
    top_path = '/home/brodeujj/Seafile/VIVO_Secure_Data/';
end

% lut_path = [top_path 'VIVO-DW-Tools/lookup_tables']; % lookup table path
% load_path = [top_path '02_DW_Cleaned']; % cleaned data path
load_path = [top_path '03_Processed_For_Elements']; % output path
% nonfac_path = [top_path '02_NonFacultyUsers']; % location of non-faculty-users list

%%% If a number is inputted (e.g. 66128) instead of a string, transform to string.
if ischar(v1)~=1
    v1 = num2str(v1);
end
if ischar(v2)~=1
    v2 = num2str(v2);
end

% arrange it so that v1 is always the older version (lower number).
if str2num(v1) > str2num(v2)
   tmp = v1;
   v1 = v2;
   v2 = tmp;
   clear tmp;
end

%% Load v1:
fid1 = fopen([load_path '/McM_HR_import-' v1 '.tsv'],'r');
tline = fgetl(fid1);
frewind(fid1);
numcols2 = length(regexp(tline,'\t'))+1;
formatspec = repmat('%s',1,numcols2);
C = textscan(fid1,formatspec,'Delimiter','\t');
fclose(fid1);

%%% Extract headers
for i = 1:1:numcols2
    % headers{i,1} = C{1,i}(1,1){1,1};
    headers{i,1} = C{1,i}{1,1};%{1,1};
    dw_v1(:,i) = C{1,i}(2:end,1);
end
clear C;

%% Load v2:
fid2 = fopen([load_path '/McM_HR_import-' v2 '.tsv'],'r');
tline = fgetl(fid2);
frewind(fid2);
numcols2 = length(regexp(tline,'\t'))+1;
formatspec = repmat('%s',1,numcols2);
C = textscan(fid2,formatspec,'Delimiter','\t');
fclose(fid2);

%%% Extract headers
for i = 1:1:numcols2
    % headers{i,1} = C{1,i}(1,1){1,1};
%     headers{i,1} = C{1,i}{1,1};%{1,1};
    dw_v2(:,i) = C{1,i}(2:end,1);
end
clear C;

%% Comparison of employee IDs
%%% Column containing proprietary ID
id_col = find(strcmp(headers(:,1),'[Proprietary_ID]')==1);

empl_id_v1 = dw_v1(:,id_col);
empl_id_v2 = dw_v2(:,id_col);

[C1,iv1] = setdiff(empl_id_v1,empl_id_v2);
[C2,iv2] = setdiff(empl_id_v2,empl_id_v1);

diff_v1 = dw_v1(iv1,:);
diff_v2 = dw_v2(iv2,:);

%% Investigate if there are individuals who have been added and removed from the files
add_remove_flag = 0;
for j = 1:1:size(diff_v2,1)
    match_fname = find(strcmp(diff_v2{j,3},diff_v1(:,3))==1);
    match_lname = find(strcmp(diff_v2{j,4},diff_v1(:,4))==1);
%     match_fac = find(strcmp(diff_v2{j,11},diff_v1(:,11))==1);
    
    if match_fname==match_lname && ~isempty(match_fname)==1 && strcmp(diff_v2{j,11},diff_v1(match_fname,11))==1 
        if strcmp(diff_v2{j,7},diff_v1(match_fname,7))==0 || strcmp(diff_v2{j,7},diff_v1(match_fname,7))==0
                    add_remove_flag = 1;

                disp(['Individual ' diff_v2{j,3} ' ' diff_v2{j,4} ' was deleted and re-added with different macIDs and/or email addresses.']);
        end
    end
end

if add_remove_flag == 1;
   disp([]) 
    
end

if size(diff_v1,1)>200 || size(diff_v2,1)>200
    add_remove_flag = add_remove_flag + 2;
    disp('additions and/or removals greater than 200 individuals. Investigate');
end
%% Export comparison results 

%%% Additions
fid_out1 =fopen([load_path '/McM_HR_diff-' v2 'vs' v1 '-additions.tsv'],'w');
tmp_out = sprintf('%s\t',headers{1:end-1});
tmp_out = [tmp_out headers{end}];
fprintf(fid_out1, '%s\n',tmp_out);

for tt = 1:1:size(diff_v2,1)
    fprintf(fid_out1,'%s\n',sprintf('%s\t',diff_v2{tt,:}));
end
fclose(fid_out1);

%%% Deletions
fid_out2 =fopen([load_path '/McM_HR_diff-' v2 'vs' v1 '-deletions.tsv'],'w');
tmp_out = sprintf('%s\t',headers{1:end-1});
tmp_out = [tmp_out headers{end}];
fprintf(fid_out2, '%s\n',tmp_out);

for tt = 1:1:size(diff_v1,1)
    fprintf(fid_out2,'%s\n',sprintf('%s\t',diff_v1{tt,:}));
end
fclose(fid_out2);
