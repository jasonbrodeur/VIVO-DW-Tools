% function [] = vivo_prepare_elementsHR(fname_in)
fname_in = 'MCM_VIVO_ALL_FACULTY-62847-clean.tsv';
% % fname_in = 'MCM_VIVO_ALL_FACULTY-62847.csv';

%%% Required operations:
% - identify primary positions
% - create
if ispc==1
    top_path = 'D:/Seafile/VIVO_Secure_Data/';
else
    top_path = '/home/brodeujj/Seafile/VIVO_Secure_Data/';
end
lut_path = [top_path 'VIVO-DW-Tools/lookup_tables'];
load_path = [top_path '02_DW_Cleaned'];
output_path = [top_path '03_Processed_For_Elements'];

%% Load additional files
%%% Load the positions lookup table
fid_pos = fopen([lut_path '/vivo_lookup_positions.tsv'],'r');
hdr_pos = fgetl(fid_pos);
num_cols = length(regexp(hdr_pos,'\t'))+1;
formatspec = repmat('%s',1,num_cols);
D = textscan(fid_pos,formatspec,'Delimiter','\t');
fclose(fid_pos);
% reformulate cell array
for i = 1:1:num_cols
    % headers{i,1} = D{1,i}{1,1};%{1,1};
    pos_lut(:,i) = D{1,i}(1:end,1);
end
%%% Remove quotation marks (that Excel likes to do to 'help out'
isString = cellfun('isclass', pos_lut, 'char');
pos_lut(isString) = strrep(pos_lut(isString), '"', '');
clear D num_cols hdr_pos;

%%% Load the DW to Elements HR mapping:
fid_dw2hr = fopen([lut_path '/DW_to_Elements_mapping.tsv'],'r');
hdr_pos = fgetl(fid_dw2hr);
%elements fieldname is col1 ; DW fieldname is col2
num_cols = length(regexp(hdr_pos,'\t'))+1;
formatspec = repmat('%s',1,num_cols);
D = textscan(fid_dw2hr,formatspec,'Delimiter','\t');
fclose(fid_dw2hr);
% reformulate cell array
for i = 1:1:num_cols
    % headers{i,1} = D{1,i}{1,1};%{1,1};
    dw2hr(:,i) = D{1,i}(1:end,1);
end

clear D num_cols hdr_pos;


%% Load the cleaned DW file:
fid = fopen([load_path '/' fname_in],'r');
tline = fgetl(fid);
frewind(fid);
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

%%% column numbers in dw
posid_col = find(strcmp('Position ID',headers(:,1))==1);
emailtype_col = find(strcmp('Email Type',headers(:,1))==1);
id_col = find(strcmp('ID',headers(:,1))==1);
macid_col = find(strcmp('MAC ID',headers(:,1))==1);
fname_col = find(strcmp('FirstName',headers(:,1))==1);
lname_col = find(strcmp('LastName',headers(:,1))==1);
pos_col = find(strcmp('Position',headers(:,1))==1);
prefix_col = find(strcmp(headers,'Prefix')==1);
initials_col = find(strcmp(headers,'Initials')==1);
knownas_col = find(strcmp(headers,'KnownAs')==1);
suffix_col = find(strcmp(headers,'Suffix')==1);
dept_col = find(strcmp(headers,'Department')==1);

secpos_col = [size(dw,2)+1:2:size(dw,2)+10]';
secdept_col = [size(dw,2)+2:2:size(dw,2)+11]';
for j = 1:1:5
    headers{size(headers,1)+1,1} = ['secpos' num2str(j)];
    dw(:,size(headers,1)) = cell(size(dw,1),1);
    headers{size(headers,1)+1,1} = ['secdept' num2str(j)];
    dw(:,size(headers,1)) = cell(size(dw,1),1);
    eval(['secpos_col' num2str(j) ' = secpos_col(j,1);'])
    eval(['secdept_col' num2str(j) ' = secdept_col(j,1);'])
end
% clear secpos_col secdept_col;

%% Load the output file:
fid_out =fopen([output_path '/Elements_HR.tsv'],'w');
hr_headers = dw2hr(:,1);
tmp_out = sprintf('%s\t',hr_headers{:});
fprintf(fid_out, '%s\n',tmp_out);

fid_out2 =fopen([output_path '/Elements_HR.csv'],'w');
hr_headers = dw2hr(:,1);
tmp_out = sprintf('%s,',hr_headers{:});
fprintf(fid_out2, '%s\n',tmp_out);

%%% Also create an output file to record problem records:
fid_issues = fopen([output_path '/Elements_export_issues.tsv'],'w');
tmp_out = sprintf('%s\t',headers{:});
fprintf(fid_issues, '%s\n',tmp_out);


%% First cleanup -- remove any rows where position rank is -999
dw_ranks = NaN.*ones(size(dw,1),1);
for k = 1:1:size(pos_lut,1)
    ind = find(strcmp(dw(:,pos_col),pos_lut{k,2})==1);
    dw_ranks(ind,1) = str2double(pos_lut{k,3});
end
% Look for NaNs in this list
if sum(isnan(dw_ranks))>0
    %     ind = find(isnan(dw_ranks));
    disp('Warning: unranked positions in dw_ranks. Investigate this error');
end
% Remove rows where rank is -999 (should not be included)
dw(dw_ranks==-999,:)= [];
dw_ranks(dw_ranks==-999,:)= [];

%% sort dw according to employee number
emplnum = str2double(dw(:,id_col));
[emplnum_sort, ind] = sort(emplnum,'ascend');
dw_sort = dw(ind,:);
dw_ranks = dw_ranks(ind,:);
% if a row returns with a diff of 0, it means that row and the next are
% duplicates
% diff_emplnum = [round(diff(emplnum_sort)); 0];
[unique_emplnum,ia,ic] = unique(emplnum_sort);

%%% Run through each unique employee number deduplicate, pull out primary
%%% position.
for i = 1:1:length(unique_emplnum);
    clear tmp pos_rank;
    tmp_output = {};
    ind = find(emplnum_sort==unique_emplnum(i)); % list of rows in dw_sort where identical IDs are found
    if size(ind,1)==1 %%%% If there's only one entry, then we're deduped already.
        tmp_output = dw_sort(ind,:);
    else
        %%%% If there's more than one entry, then we follow this approach:
        % 1) Remove any duplicate rows (that differ only by email address) -- take the McMaster address and discard the rest
        % 2) Rank the rest of the positions using the position lookup table
        % 3) The first in the list is the primary; all the rest are written to Generic columns as AutoGroups
        
        tmp = dw_sort(ind,:); % pulls out all rows where ID equals the next unique ID in the iterative list
        tmp_ranks = dw_ranks(ind,1); % pulls out ranks for each position associated with each employee ID
        [unique_posid,ia,ic]= unique(tmp(:,posid_col));
        %     if length(ic)> length(ia) % if there are more rows in the original list than unique values, then we have likely a duplicated entry.
        for ind_pos = 1:1:size(unique_posid,1)
            ind2 = find(strcmp(tmp(:,posid_col),unique_posid{ind_pos,1})==1);
            if size(ind2,1)>1
                ind3 = strcmp('McMaster',tmp(ind2,emailtype_col)); % look for a match in the "Email Type" column
                if sum(ind3)==1 %if there's one row with a match, we're all set.
                    tmp(ind2(ind3==0),:) = [];
                    tmp_ranks(ind2(ind3==0),:) = [];
                elseif sum(ind3)>1
                    tmp(ind2(ind3==0),:) = [];
                    tmp_ranks(ind2(ind3==0),:) = [];
                    disp(['Multiple rows with McMaster email address and same position number for: ' tmp{1,id_col} ', ' tmp{1,fname_col} ' ' tmp{1,lname_col}]);
                else %
                    disp(['Could not find McMaster email address for: ' tmp{1,id_col} ', ' tmp{1,fname_col} ' ' tmp{1,lname_col}]);
                end
            end
        end
        %%% The primary position is that with the highest rank
        [ranks_sort, ind_ranks] = sort(tmp_ranks,'ascend');
        tmp_output = tmp(ind_ranks(1),:);
        %%% Place all other remaining position information into Generic Columns
        for jj = 2:1:min(length(tmp_ranks),6)
            tmp_output{1,secpos_col(jj-1,1)} = tmp{ind_ranks(jj),pos_col};
            tmp_output{1,secdept_col(jj-1,1)} = tmp{ind_ranks(jj),dept_col};
        end
        
        %         %%%% Pull out primary position information if there are multiple appointments
        %         %%% Remove any position ranks flagged with -999 *should not be displayed*
        %         pos_rank(pos_rank(:,1)==-999,:) = [];
        %         tmp_pos = tmp(:,pos_col); %pull out all of the positions
        %         % Iterate through the listed positions - pull out the hierarchical rank.
        %         for j = 1:1:length(tmp_pos)
        %             %                 right_col = find(strcmp(tmp_pos{j,1},pos_lut(:,2))==1,1,'first')
        %             pos_rank(j,1) = str2double(pos_lut{find(strcmp(tmp_pos{j,1},pos_lut(:,2))==1,1,'first'),3});
        %             % tmp_pos{j,2} = pos_lut{find(strcmp(tmp_pos{j,1},pos_lut(:,2))==1,1,'first'),3};
        %         end
        
        
        %         % The highest-ranked (i.e. closest to 1) is our winner.
        %         %ind3=find(pos_rank(:,1)==min(pos_rank(:,1)));
        %
        %         if size(pos_rank,1)==1 % if there's one position left, we're done
        %             tmp_output = tmp(ind3,:);
        %         else % if there's more than one "top-rank" position, we need to run more filtering
        %
        %             %                 disp(['Multiple top rank positions found for: ' tmp{1,id_col} ', ' tmp{1,fname_col} ' ' tmp{1,lname_col}]);
        %             tmp_output = {};
        %             tmp = tmp(ind3,:);
        %             %%% Test 2: if only 1 unique position code exists, see if we can pull out the
        %             %%% McMaster email -- if so, then our work is done and we've
        %             %%% deduped.
        %
        %             % Pull out all unique position ids for an individual:
        %             unique_posid = unique(tmp(:,posid_col));
        %             if length(unique_posid)==1; % if only 1 position id, we should be able to pull out entry that has mcmaster email.
        %                 ind2 = find(strcmp('McMaster',tmp(:,emailtype_col))==1); % look for a match in the "Email Type" column
        %                 if size(ind2,1)==1 %if there's one row with a match, we're all set.
        %                     tmp_output = tmp(ind2,:);
        %                 elseif size(ind2,1)>1
        %                     disp(['Multiple rows with McMaster email address and same position number for: ' tmp{1,id_col} ', ' tmp{1,fname_col} ' ' tmp{1,lname_col}]);
        %                 else %
        %                     disp(['Could not find McMaster email address for: ' tmp{1,id_col} ', ' tmp{1,fname_col} ' ' tmp{1,lname_col}]);
        %
        %                 end
        %
        %             end
        %         end
    end
    
    %%%%%% Write data to the HR file:
    if isempty(tmp_output)~=1
        
        for k = 1:1:size(dw2hr,1)
            if k < size(dw2hr,1); formatspec = '%s\t';formatspec2 = '%s,'; else formatspec = '%s\n'; formatspec2 = '%s\n';end
            
            if isempty(dw2hr{k,2})==1 % if there's no matching field in DW, this elements field is blank
                fprintf(fid_out,formatspec,'');
                fprintf(fid_out2,formatspec2,'');
            elseif strcmp(dw2hr{k,2}(1),'<')==1
                tmp_print = dw2hr{k,2}(2:end-1);
                fprintf(fid_out,formatspec,tmp_print);
                fprintf(fid_out2,formatspec2,tmp_print);
                
            else
                dw_colname = dw2hr{k,2};
                tmp_print = tmp_output{1,find(strcmp(dw_colname,headers(:,1))==1)};
                if strcmp(dw2hr{k,1},'[Position]')==1 || strcmp(dw2hr{k,1},'[Department]')==1 || strncmp(dw2hr{k,1},'[Generic',8)==1
                    tmp_print = ['"' tmp_print '"'];
                end
                fprintf(fid_out,formatspec,tmp_print);
                fprintf(fid_out2,formatspec2,tmp_print);
                clear tmp_print;
            end
        end
    else
        disp(['No output for: ' tmp{1,id_col} ', ' tmp{1,fname_col} ' ' tmp{1,lname_col}]);
        for m = 1:1:size(tmp,1);
            fprintf(fid_issues,'%s\n',sprintf('%s\t',tmp{m,:}));
        end
    end
end
fclose(fid_out);
fclose(fid_out2);
fclose(fid_issues);