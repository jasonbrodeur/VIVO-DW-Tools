function [] = vivo_clean_dw(fname_in)
% fname_in = 'MCM_VIVO_ALL_FACULTY-62847.csv';
%%% vivo_clean_dw.m
% This function performs cleaning and data normalization procedured for
% Mosaic DW data exports.
%%% Input:
% The required input is a comma-separated version of the data extract.
% The filename (as a string) is used as an input argument.
% example: vivo_clean_dw('MCM_VIVO_ALL_FACULTY-46514.csv');
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
lut_path = [top_path 'VIVO-DW-Tools/lookup_tables']; % lookup table path
load_path = [top_path '01_DW_Extracted']; % location of 'raw' data file
output_path = [top_path '02_DW_Cleaned']; % location of 'raw' data file

% Separate filename into differnt parts:
[pathstr,fname,ext] = fileparts(fname_in);
if isempty(pathstr)==1
    pathstr = load_path;
end

%% Open the DW data export, read it and organize data into a cell array
%%fid = fopen(fname_in,'r');
%%tline = fgetl(fid);
%%%numcols2 = length(regexp(tline,'\t'))+1;
%%numcols2 = length(regexp(tline,'"'))/2;
%%%formatspec = repmat('%s',1,numcols2);
%%%%C = textscan(fid,formatspec,'Delimiter',',');
%%%C = textscan(fid,formatspec,'Delimiter',',','Whitespace','"');
%%formatspec = repmat('%s',1,numcols2);
%%%C = textscan(fid,formatspec,'Delimiter','","','MultipleDelimsAsOne',1);
%%C = textscan(fid,formatspec,'Delimiter','",','MultipleDelimsAsOne',1);
%%fclose(fid);

%%% Figure out if we're loading a tsv or csv file:
fid = fopen([pathstr '/' fname_in],'r');
tline = fgetl(fid);
frewind(fid);
switch ext
    case '.tsv'
        numcols2 = length(regexp(tline,'\t'))+1;
        formatspec = repmat('%s',1,numcols2);
        C = textscan(fid,formatspec,'Delimiter','\t');
        fclose(fid);
    case '.csv'
        numcols2 = length(regexp(tline,','))+1;
        formatspec = repmat('%q',1,numcols2);
        C = textscan(fid,formatspec,'Delimiter',',');
        fclose(fid);
    otherwise
        disp('extension not recognized (looking for .csv or .tsv). Check that you have the correct file selected and that it''s using the correct delimeter. Rename if necessary.');
        return;
end 


% fid = fopen([pathstr '/' fname_in],'r');
% tline = fgetl(fid);
% frewind(fid);
% numcols2 = length(regexp(tline,'\t'))+1;
% formatspec = repmat('%s',1,numcols2);
% C = textscan(fid,formatspec,'Delimiter','\t');
% fclose(fid);

%% Extract headers
for i = 1:1:numcols2
    % headers{i,1} = C{1,i}(1,1){1,1};
    headers{i,1} = C{1,i}{1,1};%{1,1};
    dw(:,i) = C{1,i}(2:end,1);
end

%%%Open a document so that we can track bad data. Mark it with a timestamp:
fid_report = fopen([output_path '/' fname '-datareport_' datestr(now,30) '.txt'],'w');

% Find columns for macid, first and last names:
macid_col = find(strcmp(headers,'MAC ID')==1);
fname_col = find(strcmp(headers,'FirstName')==1);
lname_col = find(strcmp(headers,'LastName')==1);
mname_col = find(strcmp(headers,'Middle Name')==1);
if isempty(mname_col)
    mname_col = find(strcmp(headers,'MiddleName')==1);
end
prefix_col = find(strcmp(headers,'Prefix')==1);
initials_col = find(strcmp(headers,'Initials')==1); 
knownas_col = find(strcmp(headers,'KnownAs')==1);
if isempty(knownas_col)
   dw = [dw cell(length(dw),1)];   knownas_col = size(dw,2);   headers{knownas_col,1}='KnownAs';
end
suffix_col = find(strcmp(headers,'Suffix')==1);
if isempty(suffix_col)
   dw = [dw cell(length(dw),1)];   suffix_col = size(dw,2);   headers{suffix_col,1}='Suffix';
end

%% Task 0: Open up a manually-maintained lookup table that will do corrections that are currently not programmed into this function:
%%% Structure of the name correction file:
% col1 = macid; col2 = old fname; col3 = old mname; col4 = old lname;
% col5 = new fname; col6 = new mname; col7 = new lname;
fprintf(fid_report,'%s\n','IDs requiring first name / middle name / last name cleanup:')

[fid_fixes, errmsg] = fopen([lut_path '/name_corrections.tsv'],'r');
tline = fgetl(fid_fixes);
numcols = length(regexp(tline,'\t'))+1;
        formatspec = repmat('%s',1,numcols);
        D = textscan(fid_fixes,formatspec,'Delimiter','\t');
        % Remove quotation marks.
        for pp = 1:1:size(D,2)
        isString = cellfun('isclass', D{1,pp}, 'char');
        D{1,pp}(isString) = strrep(D{1,pp}(isString), '"', '');
        end
fclose(fid_fixes);   
for t = 1:1:size(D{1,1},1)
   ind_repl = find(strcmp(D{1,1}{t,1},dw(:,macid_col))==1); 
      for t2 = 1:1:length(ind_repl)
      dw{ind_repl(t2),fname_col} = D{1,5}{t,1};
      dw{ind_repl(t2),mname_col} = D{1,6}{t,1};
      dw{ind_repl(t2),lname_col} = D{1,7}{t,1};
      end
      fprintf(fid_report,'%s\n',dw{ind_repl(1),1});
end

clear D;        
        
%% Task 1: Put First, Middle, and Last Names + Prefix into Sentence Case; macIDs into lower case;

%%% MAC IDs to lowercase: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:1:length(dw(:,macid_col))
    tmp = lower(dw{i,macid_col});
    
    dw{i,macid_col}= tmp;
    
    %tmp2{i,1} = regexprep(tmp,'(\<[a-z])','${upper($1)}');
    %dw{i,fname_col} = regexprep(tmp,'(\<[a-z])','${upper($1)}')
end

% % %%% Check for people with no MAC ID: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % ind = find(strcmp(dw(:,macid_col),'-')==1 | strcmp(dw(:,macid_col),'')==1);
% % if size(ind,1)>0
% %     fprintf(fid_report,'%s\n','IDs with no MAC IDs');
% %     for i = 1:1:length(ind)
% %         fprintf(fid_report,'%s\n',dw{ind(i),1});
% %     end
% % end

%% First Names to Sentence case: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Exceptions for capitalization
%%% following a space
%%% following a hyphen

%%% Cleanup for first names
fprintf(fid_report,'%s\n','IDs requiring first name cleanup:');

% period to space:
period = strfind(dw(:,fname_col),'.');
ind=find(cellfun('isempty',period)==0);
for i = 1:1:length(ind)
    fprintf(fid_report,'%s\n',[dw{ind(i),1} ' - remove period']);
    dw{ind(i),fname_col} = strrep(dw{ind(i),fname_col},'.',' ');
end

% extra space on either side of hyphen:
extra_space = strfind(dw(:,fname_col),' - ');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
    fprintf(fid_report,'%s\n',dw{ind(i),1});
    dw{ind(i),fname_col} = strrep(dw{ind(i),fname_col},' - ','-');
end
% remove extra space on left side of hyphen:
extra_space = strfind(dw(:,fname_col),'- ');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
    fprintf(fid_report,'%s\n',dw{ind(i),1});
    dw{ind(i),fname_col} = strrep(dw{ind(i),fname_col},'- ','-');
end
% remove extra space on right side of hyphen:
extra_space = strfind(dw(:,fname_col),' -');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
    fprintf(fid_report,'%s\n',dw{ind(i),1});
    dw{ind(i),fname_col} = strrep(dw{ind(i),fname_col},' -','-');
end
% remove two spaces between names:
extra_space = strfind(dw(:,fname_col),'  ');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
    fprintf(fid_report,'%s\n',dw{ind(i),1});
    dw{ind(i),fname_col} = strrep(dw{ind(i),fname_col},'  ',' ');
end


%%% Flag any first name with a hyphen for later:
hyphens = strfind(dw(:,fname_col),'-');
ind_hyphen=find(cellfun('isempty',hyphens)==0);

%%% To sentence case:
ind_mncheck = [];
suffixes = {' jr' 'Jr';' sr' 'Sr'; ' iii' 'III'; ' iv' 'IV'};
for i = 1:1:length(dw(:,fname_col))
    tmp = lower(dw{i,fname_col});
    to_upper = 1;
    
    %%% Pull out "KnownAs" from the first name (assuming that parentheses are used to indicate this).
    paren = strfind(tmp,'(');
    if ~isempty(paren) 
       paren_end = strfind(tmp,')');
       if isempty(paren_end);
           if strcmp(tmp(end),' ')==1; 
               dw{i,knownas_col} = tmp(paren+1:paren_end-1);
           else
               dw{i,knownas_col} = tmp(paren+1:paren_end);
           end
       else
           dw{i,knownas_col} = tmp(paren+1:paren_end-1);
       end
       tmp = tmp(1:paren-1);
    end
    
    %%% We've also seen that "" are used to indicate KnownAs. Repeat the Process:
    quote = strfind(tmp,'"');
    if ~isempty(quote) 
       if numel(quote)==1   
           if strcmp(tmp(end),' ')==1; 
               dw{i,knownas_col} = tmp(quote(1)+1:end-1);
           else
               dw{i,knownas_col} = tmp(quote(1)+1:end);
           end
       elseif numel(quote) ==2
           dw{i,knownas_col} = tmp(quote(1)+1:quote(2)-1);
           
       else
           fprintf(fid_report,'%s\n',['More than two quotation marks in first name string for ' dw{ind(i),1}]);
       end  
       tmp = tmp(1:quote(1)-1);
    end

    %%% Pull out Suffixes - write them to the "Suffix" field. Remove them
    %%% from the first name.
    for sfx_ctr = 1:1:size(suffixes,1)
       if ~isempty(strfind(tmp,suffixes{sfx_ctr,1}))
           ind_sfx = strfind(tmp,suffixes{sfx_ctr,1});
          dw{i,suffix_col} = suffixes{sfx_ctr,2};% tmp(ind_sfx+1:ind_sfx+length(suffixes{sfx_ctr})-1);          
           tmp = tmp(1:ind_sfx-1);
       else
       end
    end
   
    % Remove any trailing white space. 
    if strcmp(tmp(end),' ')==1; tmp = tmp(1:end-1); end 
  
    % Capitalize after a space
    space = strfind(tmp, ' ');
    if length(space)>0; 
        to_upper= [to_upper; space'+1]; 
        %%% Also, flag this row for review, to see if the middle name might
        %%% be included in with the first name;
        ind_mncheck = [ind_mncheck; i];
    end 
    
    % Capitalize after a hyphen
    hyphen = strfind(tmp, '-');
    if length(hyphen)>0; to_upper= [to_upper; hyphen'+1]; end 
    tmp(to_upper) = upper(tmp(to_upper));
    dw{i,fname_col}= tmp;
end


%% Middle Names to sentence case : %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% To sentence case
% remove periods (turn '.' into ' ')
% remove spaces around hyphens
% ensure a single space between different words (turn '  ' into ' ')

fprintf(fid_report,'%s\n','IDs requiring middle name cleanup:');

% period to space:
period = strfind(dw(:,mname_col),'.');
ind=find(cellfun('isempty',period)==0);
for i = 1:1:length(ind)
    fprintf(fid_report,'%s\n',[dw{ind(i),1} ' - remove period']);
    dw{ind(i),mname_col} = strrep(dw{ind(i),mname_col},'.',' ');
end

% extra space on either side of hyphen:
extra_space = strfind(dw(:,mname_col),' - ');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
    fprintf(fid_report,'%s\n',[dw{ind(i),1} ' - remove spaces around hyphen.']);
    dw{ind(i),mname_col} = strrep(dw{ind(i),mname_col},' - ','-');
end

% remove extra space on left side of hyphen:
extra_space = strfind(dw(:,mname_col),'- ');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
    fprintf(fid_report,'%s\n',[dw{ind(i),1} ' - remove spaces around hyphen.']);
    dw{ind(i),mname_col} = strrep(dw{ind(i),mname_col},'- ','-');
end

% remove extra space on right side of hyphen:
extra_space = strfind(dw(:,mname_col),' -');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
    fprintf(fid_report,'%s\n',[dw{ind(i),1} ' - remove spaces around hyphen.']);
    dw{ind(i),mname_col} = strrep(dw{ind(i),mname_col},' -','-');
end
% remove two spaces between names:
extra_space = strfind(dw(:,mname_col),'  ');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
    fprintf(fid_report,'%s\n',[dw{ind(i),1} ' - remove extra blank space']);
    dw{ind(i),mname_col} = strrep(dw{ind(i),mname_col},'  ',' ');
end

%%% To sentence case:
for i = 1:1:length(dw(:,mname_col))
    tmp = lower(dw{i,mname_col});
    if isempty(tmp)==1; continue; end;
    to_upper = 1;
    %tmp2{i,1} = regexprep(tmp,'(\<[a-z])','${upper($1)}');
    %dw{i,fname_col} = regexprep(tmp,'(\<[a-z])','${upper($1)}')
    % Remove any trailing white space. 
    if strcmp(tmp(end),' ')==1; tmp = tmp(1:end-1); end 
    
    % Capitalize after a space
    space = strfind(tmp, ' ');
    if length(space)>0; 
        to_upper= [to_upper; space'+1]; 
    end 
    
    % Capitalize after a hyphen
    hyphen = strfind(tmp, '-');
    if length(hyphen)>0; to_upper= [to_upper; hyphen'+1]; end 
    
    tmp(to_upper) = upper(tmp(to_upper));
    
    dw{i,mname_col}= tmp;
end
%% Last Names to sentence case : %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Exceptions for capitalization
%%% following a space
%%% following a hyphen
%%% following 'MC' and 'MAC' at the start of a name

%%% Additional cleanup for last names
fprintf(fid_report,'%s\n','IDs requiring last name cleanup');

% extra space on either side of hyphen:
extra_space = strfind(dw(:,lname_col),' - ');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
    fprintf(fid_report,'%s\n',dw{ind(i),1});
    dw{ind(i),lname_col} = strrep(dw{ind(i),lname_col},' - ','-');
end
% remove extra space on left side of hyphen:
extra_space = strfind(dw(:,lname_col),'- ');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
    fprintf(fid_report,'%s\n',dw{ind(i),1});
    dw{ind(i),lname_col} = strrep(dw{ind(i),lname_col},'- ','-');
end
% remove extra space on right side of hyphen:
extra_space = strfind(dw(:,lname_col),' -');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
    fprintf(fid_report,'%s\n',dw{ind(i),1});
    dw{ind(i),lname_col} = strrep(dw{ind(i),lname_col},' -','-');
end
% remove two spaces between names:
extra_space = strfind(dw(:,lname_col),'  ');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
    fprintf(fid_report,'%s\n',dw{ind(i),1});
    dw{ind(i),lname_col} = strrep(dw{ind(i),lname_col},'  ',' ');
end

%%% To sentence case:
for i = 1:1:length(dw(:,lname_col))
    tmp = lower(dw{i,lname_col});
    to_upper = 1;
    if strcmp(tmp(end),' ')==1; tmp = tmp(1:end-1); end % Remove any trailing white space.
    space = strfind(tmp, ' ');
    if length(space)>0; to_upper= [to_upper; space'+1]; end
    hyphen = strfind(tmp, '-');
    if length(hyphen)>0; to_upper= [to_upper; hyphen'+1]; end
    if strncmp(tmp,'mc',2)==1; to_upper = [to_upper; 3];end
    if strncmp(tmp,'mac',3)==1; to_upper = [to_upper; 4];end
    if strncmp(tmp,'o''',2)==1; to_upper = [to_upper; 3];end
    tmp(to_upper) = upper(tmp(to_upper));
    dw{i,lname_col}= tmp;
end

%% KnownAs to Sentence Case: 
for i = 1:1:length(dw(:,knownas_col))
    tmp = lower(dw{i,knownas_col});
    if ~isempty(tmp)
    to_upper = 1;
     % Remove any trailing white space. 
    if strcmp(tmp(end),' ')==1; tmp = tmp(1:end-1); end 
    space = strfind(tmp, ' ');
    if length(space)>0; to_upper= [to_upper; space'+1]; end
    hyphen = strfind(tmp, '-');
    if length(hyphen)>0; to_upper= [to_upper; hyphen'+1]; end
    tmp(to_upper) = upper(tmp(to_upper));
    dw{i,knownas_col}= tmp;
    end
end

%% Prefix to Sentence Case
%%% & Remove any spaces:

for i = 1:1:length(dw(:,prefix_col))
    dw{i,prefix_col} = strrep(dw{i,prefix_col},' ','');
    tmp = lower(dw{i,prefix_col});
    if isempty(tmp)
        tmp = '';
    else
        tmp(1) = upper(tmp(1));
        if strcmpi(tmp,'Miss')~=1
            %         tmp = [tmp '.'];
            tmp(end+1) = '.';
        end
    end
    dw{i,prefix_col} = tmp;
end

%% Generate Initials
for i = 1:1:length(dw(:,initials_col))
    tmp_fname = dw{i,fname_col};
    tmp_fname_space = strrep(tmp_fname,'-',' ');

    tmp_inits = '';
    %%% Process the first name first: 
    tmp_inits(1) = tmp_fname(1);
    spaces = strfind(tmp_fname_space,' ');
    for spc_ctr = 1:1:length(spaces)
        switch tmp_fname(spaces(spc_ctr))
            case ' '
                tmp_inits = [tmp_inits tmp_fname(spaces(spc_ctr)+1)];
            case '-'
                tmp_inits = [tmp_inits '-' tmp_fname(spaces(spc_ctr)+1)];
        end
    end
    
    %%% Add initials from middle name only if not flagged as multiple-name
    %%% first names
    tmp_mname = dw{i,mname_col};
    if sum(i == ind_mncheck)==0 && ~isempty(tmp_mname) % if it's a person NOT with two first names
        tmp_mname_space = strrep(tmp_mname,'-',' ');
        tmp_inits = [tmp_inits tmp_mname(1)];
        
        spaces = strfind(tmp_mname_space,' ');
        for spc_ctr = 1:1:length(spaces)
            switch tmp_mname(spaces(spc_ctr))
                case ' '
                    tmp_inits = [tmp_inits tmp_mname(spaces(spc_ctr)+1)];
                case '-'
                    tmp_inits = [tmp_inits '-' tmp_mname(spaces(spc_ctr)+1)];
            end
        end
        
    end
dw{i,initials_col} = tmp_inits;
end
%%
% %% Identify potential cases where middle names have been included in the first name field, and need to be broken apart.
% %%% Test 1--Looking for two or more first names was accomplished in an earlier loop.
% tmp_dw = dw(ind_mncheck,:);
% 
% 

%% Clean Position Titles -- use lookup table to perform find/replace %%%%%%%%%%%%%
% load the positions lookup table
fid_pos = fopen([lut_path '/vivo_lookup_positions.tsv'],'r');
hdr_pos = fgetl(fid_pos);
num_cols = length(regexp(hdr_pos,'\t'))+1;
formatspec = repmat('%s',1,num_cols);
% D = strrep(D,'"','');
D = textscan(fid_pos,formatspec,'Delimiter','\t');
%%% Remove quotation marks (that Excel likes to do to 'help out')
isString = cellfun('isclass', D{1,1}, 'char');
D{1,1}(isString) = strrep(D{1,1}(isString), '"', '');
isString = cellfun('isclass', D{1,2}, 'char');
D{1,2}(isString) = strrep(D{1,2}(isString), '"', '');
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
        fprintf(fid_report,'%s\n','Positions to add to lookup table:');
        fprintf(fid_report,'%s\n',unique_pos{i,1});
    else
        ind = find(strcmp(dw(:,pos_col),unique_pos{i,1})==1);
        %%%substitute all positions of this type with the proper title
        %%%(in column 2 of the lookup table)
        dw(ind,pos_col) = D{1,2}(lookup_match,1);
    end
end

%% Faculty Name - lookup table replace %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load the faculties lookup table
fid_fac = fopen([lut_path '/vivo_lookup_faculties.tsv'],'r');
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
        fprintf(fid_report,'%s\n','Faculties to add to lookup table:');
        fprintf(fid_report,'%s\n',unique_fac{i,1});
    else
        ind = find(strcmp(dw(:,fac_col),unique_fac{i,1})==1);
        %%%substitute all positions of this type with the proper title
        %%%(in column 2 of the lookup table)
        dw(ind,fac_col) = D{1,2}(lookup_match,1);
    end
end

%% Department Name - lookup table replace %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load the departments lookup table
fid_dept = fopen([lut_path '/vivo_lookup_departments.tsv'],'r');
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
        fprintf(fid_report,'%s\n','Departments to add to lookup table:');
        fprintf(fid_report,'%s\n',unique_dept{i,1});
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
fid_bldg = fopen([lut_path '/vivo_lookup_buildings.tsv'],'r');
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

%% If any records have a MacID of '-', remove them from the data, write them to a new file, and list them in the problem report:
ind_nomacid = find(strcmp('-',dw(:,macid_col))==1);
fid_nomacid = fopen([output_path '/' fname '_noMacID.tsv'],'w');
tmp = sprintf('%s\t',headers{:});
fprintf(fid_nomacid,'%s\n',tmp);
fprintf(fid_report,'%s\n','Users with no MacID (removed from further processing):')

for i = 1:1:length(ind_nomacid)
    fprintf(fid_nomacid,'%s\n',sprintf('%s\t',dw{ind_nomacid(i),:}));
    fprintf(fid_report,'%s\n',dw{ind_nomacid(i),1});
end
fclose(fid_nomacid);
dw(ind_nomacid,:) = [];

%% Close the report, Write the Final Output:
fclose(fid_report);

fid_out = fopen([output_path '/' fname '-clean.tsv'],'w');
tmp = sprintf('%s\t',headers{:});
fprintf(fid_out,'%s\n',tmp);
for i = 1:1:length(dw)
    fprintf(fid_out,'%s\n',sprintf('%s\t',dw{i,:}));
end
fclose(fid_out);