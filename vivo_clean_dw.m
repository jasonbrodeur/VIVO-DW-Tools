function [] = vivo_clean_dw(fname_in);

%%% vivo_clean_dw.m
% This function performs cleaning and data normalization procedured for
% Mosaic DW data exports. 
%%% Input: 
% The required input is a tab-separated version of the data extract (no other changes made).
% This requires for the DW-created .xls sheet to be transformed to tsv.
% The filename (as a string) is used as an input argument.
% example: vivo_clean_dw('MCM_VIVO_ALL_FACULTY-46514.tsv');
% The script also loads in tab-separated lookup table files for faculty
% positions, departments, faculties and buildings.
%%% Outputs: 
% The outputs include a 'cleaned' (ready-for-VIVO-integration) version of
% the DW data, as well as a data processing report, which indicates
% specific entries where an inconsistency has been found.
%
% Created January 2017 by JJB.

%%% Set the starting path:
if ispc==1
start_path = 'D:/Local/VIVO-DW-Tools';
else
start_path = '/home/brodeujj/octave/VIVO';
end
cd(start_path);

[pathstr,fname,ext] = fileparts(fname_in);


%% Open the DW data export, read it and organize data into a cell array
fid = fopen(fname_in,'r');
tline = fgetl(fid);
numcols2 = length(regexp(tline,'\t'))+1;
formatspec = repmat('%s',1,numcols2);
C = textscan(fid,formatspec,'Delimiter','\t');
fclose(fid);

%%% Extract headers
for i = 1:1:numcols2
% headers{i,1} = C{1,i}(1,1){1,1};
headers{i,1} = C{1,i}{1,1};%{1,1};
dw(:,i) = C{1,i}(2:end,1);
end

%%%Open a document so that we can track bad data. Mark it with a timestamp:
fid_report = fopen([fname '-datareport_' datestr(now,30) '.txt'],'w');

% Find columns for macid, first and last names:
macid_col = find(strcmp(headers,'MAC ID')==1);
fname_col = find(strcmp(headers,'FirstName')==1);
lname_col = find(strcmp(headers,'LastName')==1);

%% Task 1: Put First and Last Names into Sentence Case; macIDs into lower case

%%% MAC IDs to lowercase: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:1:length(dw(:,macid_col))
tmp = lower(dw{i,macid_col});

dw{i,macid_col}= tmp;

%tmp2{i,1} = regexprep(tmp,'(\<[a-z])','${upper($1)}');
%dw{i,fname_col} = regexprep(tmp,'(\<[a-z])','${upper($1)}')
end

%%% First Names to Sentence case: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Exceptions for capitalization
%%% following a space
%%% following a hyphen

for i = 1:1:length(dw(:,fname_col))
tmp = lower(dw{i,fname_col});
to_upper = 1;

space = strfind(tmp, ' '); 
if length(space)>0; to_upper= [to_upper; space'+1]; end
hyphen = strfind(tmp, '-');
if length(hyphen)>0; to_upper= [to_upper; hyphen'+1]; end
tmp(to_upper) = upper(tmp(to_upper));
dw{i,fname_col}= tmp;

%tmp2{i,1} = regexprep(tmp,'(\<[a-z])','${upper($1)}');
%dw{i,fname_col} = regexprep(tmp,'(\<[a-z])','${upper($1)}')
end

%%% Last Names to sentence case : %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Exceptions for capitalization
%%% following a space
%%% following a hyphen
%%% following 'MC' and 'MAC' at the start of a name

for i = 1:1:length(dw(:,lname_col))
tmp = lower(dw{i,lname_col});
to_upper = 1;

space = strfind(tmp, ' '); 
if length(space)>0; to_upper= [to_upper; space'+1]; end
hyphen = strfind(tmp, '-');
if length(hyphen)>0; to_upper= [to_upper; hyphen'+1]; end
if strncmp(tmp,'mc',2)==1; to_upper = [to_upper; 3];end
if strncmp(tmp,'mac',3)==1; to_upper = [to_upper; 4];end
tmp(to_upper) = upper(tmp(to_upper));
dw{i,lname_col}= tmp;
end

%%% Additional cleanup for last names
fprintf(fid_report,'%s\n','IDs requiring last name cleanup')
% extra space on either side of hyphen:
extra_space = strfind(dw(:,4),' - ');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
fprintf(fid_report,'%s\n',dw{ind(i),1})
dw{ind(i),4} = strrep(dw{ind(i),4},' - ','-');
end
% remove extra space on left side of hyphen:
extra_space = strfind(dw(:,4),'- ');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
fprintf(fid_report,'%s\n',dw{ind(i),1})
dw{ind(i),4} = strrep(dw{ind(i),4},' - ','-');
end
% remove extra space on right side of hyphen:
extra_space = strfind(dw(:,4),' -');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
fprintf(fid_report,'%s\n',dw{ind(i),1})
dw{ind(i),4} = strrep(dw{ind(i),4},' - ','-');
end
% remove two spaces between names:
extra_space = strfind(dw(:,4),'  ');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
fprintf(fid_report,'%s\n',dw{ind(i),1})
dw{ind(i),4} = strrep(dw{ind(i),4},' - ','-');
end

%% Clean Position Titles -- use lookup table to perform find/replace %%%%%%%%%%%%%
% load the positions lookup table
fid_pos = fopen('vivo_lookup_positions.tsv','r');
hdr_pos = fgetl(fid_pos);
num_cols = length(regexp(hdr_pos,'\t'))+1;
formatspec = repmat('%s',1,num_cols);
D = textscan(fid_pos,formatspec,'Delimiter','\t');
fclose(fid_pos);
%for i = 1:1:num_cols
%pos_list(:,i) = D{1,i}(:,1);
%end

pos_col = find(strcmp(headers,'Position')==1);

%%% Find all unique strings; search for each unique string in the lookup
%%% table. If it doesn't exist, make a note in the report. If it does
%%% exist, replace the item with the proper text.
unique_pos = unique(dw(:,pos_col));
for i = 1:1:length(unique_pos)
lookup_match = find(strcmp(D{1,1}(:,1),unique_pos{i,1})==1);
    if isempty(lookup_match)==1
    fprintf(fid_report,'%s\n','Positions to add to lookup table:')
    fprintf(fid_report,'%s\n',unique_pos{i,1})
    else
    ind = find(strcmp(dw(:,pos_col),unique_pos{i,1})==1);
    %%%substitute all positions of this type with the proper title 
    %%%(in column 2 of the lookup table)
    dw(ind,pos_col) = D{1,2}(lookup_match,1);
    end
end

%% Faculty Name - lookup table replace %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load the faculties lookup table
fid_fac = fopen('vivo_lookup_faculties.tsv','r');
hdr_pos = fgetl(fid_fac);
num_cols = length(regexp(hdr_pos,'\t'))+1;
formatspec = repmat('%s',1,num_cols);
D = textscan(fid_fac,formatspec,'Delimiter','\t');
fclose(fid_fac);
%for i = 1:1:num_cols
%pos_list(:,i) = D{1,i}(:,1);
%end

fac_col = find(strcmp(headers,'Faculty')==1);

%%% Find all unique strings; search for each unique string in the lookup
%%% table. If it doesn't exist, make a note in the report. If it does
%%% exist, replace the item with the proper text.
unique_fac = unique(dw(:,fac_col));
for i = 1:1:length(unique_fac)
lookup_match = find(strcmp(D{1,1}(:,1),unique_fac{i,1})==1);
    if isempty(lookup_match)==1
    fprintf(fid_report,'%s\n','Faculties to add to lookup table:')
    fprintf(fid_report,'%s\n',unique_fac{i,1})
    else
    ind = find(strcmp(dw(:,fac_col),unique_fac{i,1})==1);
    %%%substitute all positions of this type with the proper title 
    %%%(in column 2 of the lookup table)
    dw(ind,fac_col) = D{1,2}(lookup_match,1);
    end
end

%% Department Name - lookup table replace %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load the departments lookup table
fid_dept = fopen('vivo_lookup_departments.tsv','r');
hdr_pos = fgetl(fid_dept);
num_cols = length(regexp(hdr_pos,'\t'))+1;
formatspec = repmat('%s',1,num_cols);
D = textscan(fid_dept,formatspec,'Delimiter','\t');
fclose(fid_dept);
%for i = 1:1:num_cols
%pos_list(:,i) = D{1,i}(:,1);
%end

dept_col = find(strcmp(headers,'Department')==1);

%%% Find all unique strings; search for each unique string in the lookup
%%% table. If it doesn't exist, make a note in the report. If it does
%%% exist, replace the item with the proper text.
unique_dept = unique(dw(:,dept_col));
for i = 1:1:length(unique_dept)
lookup_match = find(strcmp(D{1,1}(:,1),unique_dept{i,1})==1);
    if isempty(lookup_match)==1
    fprintf(fid_report,'%s\n','Departments to add to lookup table:')
    fprintf(fid_report,'%s\n',unique_dept{i,1})
    else
    ind = find(strcmp(dw(:,dept_col),unique_dept{i,1})==1);
    %%%substitute all positions of this type with the proper title 
    %%%(in column 2 of the lookup table)
    dw(ind,dept_col) = D{1,2}(lookup_match,1);
    end
end

%% replace the "Camp Building" column text with text generated from column 21 and the 
%%% buildings lookup table. I think ultimately we'll want to replace these
%%% items with the VIVO url for each building. 
%%% Not all of these are entered yet into VIVO -- perhaps we could use the
%%% lookup table itself to generate these items?
% load the campus buildings lookup table
fid_bldg = fopen('vivo_lookup_buildings.tsv','r');
hdr_pos = fgetl(fid_bldg);
num_cols = length(regexp(hdr_pos,'\t'))+1;
formatspec = repmat('%s',1,num_cols);
D = textscan(fid_bldg,formatspec,'Delimiter','\t');
fclose(fid_bldg);
%for i = 1:1:num_cols
%pos_list(:,i) = D{1,i}(:,1);
%end

bldg_col = find(strcmp(headers,'Camp Building')==1);
bldg_code_col = find(strcmp(headers,'Building Code')==1);

for i = 1:1:size(dw,1)
    tmp = dw{i,bldg_code_col};
    ind_dash = strfind(tmp,'-');
    if isempty(ind_dash)==1
        continue;
    else
        bldg_code = tmp(1:ind_dash(1)-1);
        room = tmp(ind_dash(1)+1:end);
        ind = find(strcmp(D{1,1}(:,1),bldg_code)==1);
        if isempty(ind)==1
            continue
        else
            tmp2 = [D{1,2}{ind,1} ', Rm ' room ];
            dw{i,bldg_col} = tmp2;
        end
    end
end

%%% Close the report:
fclose(fid_report);

%% Write the Final Output:

fid_out = fopen([fname '-clean.tsv'],'w');
tmp = sprintf('%s\t',headers{:});
fprintf(fid_out,'%s\n',tmp);
for i = 1:1:length(dw)
fprintf(fid_out,'%s\n',sprintf('%s\t',dw{i,:}));
end
fclose(fid_out);