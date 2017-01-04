cd('/home/brodeujj/octave/VIVO');



fid = fopen('MCM_VIVO_ALL_FACULTY-46514.tsv','r');

tline = fgetl(fid);
%numcols = length(findstr(tline,'\t'))+1;
numcols2 = length(regexp(tline,'\t'))+1;
formatspec = repmat('%s',1,numcols2);

C = textscan(fid,formatspec,'Delimiter','\t');
fclose(fid);

for i = 1:1:numcols2
headers{i,1} = C{1,i}(1,1){1,1};
dw(:,i) = C{1,i}(2:end,1);
end

%Open a document so that we can track bad data:
fid_report = fopen('MCM_VIVO_ALL_FACULTY-46514-datareport.txt','w');

fname_col = find(strcmp(headers,'FirstName')==1);
lname_col = find(strcmp(headers,'LastName')==1);

% Task 1: Put First and Last Names into Sentence Case
% Exceptions for capitalization
%%% following a space
%%% following a hyphen
%%% following 'MC' and 'MAC' at the start of a name


%% First Names: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

%% Last Names: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
%%% Additional cleanup
fprintf(fid_report,'%s\n','IDs requiring last name cleanup')
% extra space on either side of hyphen:
extra_space = strfind(dw(:,4),' - ');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
fprintf(fid_report,'%s\n',dw{ind(i),1})
dw{ind(i),4} = strrep(dw{ind(i),4},' - ','-');
end
% extra space on left side of hyphen:
extra_space = strfind(dw(:,4),'- ');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
fprintf(fid_report,'%s\n',dw{ind(i),1})
dw{ind(i),4} = strrep(dw{ind(i),4},' - ','-');
end
% extra space on right side of hyphen:
extra_space = strfind(dw(:,4),' -');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
fprintf(fid_report,'%s\n',dw{ind(i),1})
dw{ind(i),4} = strrep(dw{ind(i),4},' - ','-');
end
% two spaces between names:
extra_space = strfind(dw(:,4),'  ');
ind=find(cellfun('isempty',extra_space)==0);
for i = 1:1:length(ind)
fprintf(fid_report,'%s\n',dw{ind(i),1})
dw{ind(i),4} = strrep(dw{ind(i),4},' - ','-');
end

%% Position Title %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
%% Find all unique strings 
unique_pos = unique(dw(:,pos_col));




fclose(fid_report);
