function [headers,c] = sheet2cell(fname_in,delim,num_header_rows)
% fname_in = full path to file to read
% delimiter ',' for comma; '\t' for tab (default = ',');
% num_header_rows = number of header rows
if nargin ==1
    delim = ',';
    num_header_rows = 1;
elseif nargin ==2
    num_header_rows = 1;
end


fid = fopen(fname_in,'r');

tline = fgetl(fid);
frewind(fid);

numcols = length(regexp(tline,delim))+1;
switch delim
    case ','
formatspec = repmat('%q',1,numcols);
    otherwise
formatspec = repmat('%s',1,numcols);
end

C = textscan(fid,formatspec,'Delimiter',delim);

% Extract headers and data:
for i = 1:1:numcols
    headers{i,1} = C{1,i}{1:num_header_rows,1};
    c(:,i) = C{1,i}(num_header_rows+1:end,1);
end
fclose(fid);