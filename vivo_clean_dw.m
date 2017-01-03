cd('/home/brodeujj/octave/VIVO');

fid = fopen('MCM_VIVO_ALL_FACULTY-46514.tsv');

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

fname_col = find(strcmp(headers,'FirstName')==1);
lname_col = find(strcmp(headers,'LastName')==1);

% Task 1: Put First and Last Names into Sentence Case
% Exceptions for capitalization
%%% following a space
%%% following a hyphen
%%% following 'MC' and 'MAC' at the start of a name

% First Names
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

% Last Names
for i = 1:1:length(dw(:,lname_col))
tmp = lower(dw{i,lname_col});
to_upper = 1;

space = strfind(tmp, ' '); 
if length(space)>0; to_upper= [to_upper; space'+1]; end
hyphen = strfind(tmp, '-');
if length(hyphen)>0; to_upper= [to_upper; hyphen'+1]; end
tmp(to_upper) = upper(tmp(to_upper));
if strncmp(tmp(1:2),'mc',2)==1; to_upper = [to_upper; 3];end
if strncmp(tmp(1:2),'mac',2)==1; to_upper = [to_upper; 4];end
tmp(to_upper) = upper(tmp(to_upper));
dw{i,lname_col}= tmp;
end