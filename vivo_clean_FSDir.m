function [] = vivo_clean_FSDir(fname_in)

% Set path depending on whether PC or linux:
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

FSdir_in_path = [top_path '01_UTS_Extracted'];
FSdir_out_path = [top_path '02_UTS_Cleaned'];

%%% If appropriate filename not provided, allow for interactive selection
if nargin==0
    uiflag = 1;
else
    if nargin == 1 && isempty(fname_in)==1
        uiflag = 1;
    else
        uiflag = 0;
    end
end

if uiflag == 1
    tmp_dir = pwd;
    cd(FSdir_in_path);
    fname_in = uigetfile({'*.xlsx';'*.xls';'*.*'},'F&S Directory File to Process');
end

file_path = [FSdir_in_path '/' fname_in];

%% Use xlsread to load the F&S Directory file:
[num,txt,raw]=xlsread(file_path);
phone_num_col = find(strcmp(raw(1,:),'Extension')==1);
% Remove tabs from the file (creates problems when writing it):
raw(:,2:end) = regexprep(raw(:,2:end),'\t','');
raw(:,phone_num_col) = strrep(raw(:,phone_num_col),'ext.','x');
raw(:,phone_num_col) = strrep(raw(:,phone_num_col),'ext','x');
raw(:,phone_num_col) = strrep(raw(:,phone_num_col),'X','x');

%% Write to FSdir_out_path
fid_out = fopen([FSdir_out_path '/FSDir-current.tsv'],'w');

%Write headers:
fprintf(fid_out,'%s\n',sprintf('%s\t',raw{1,:}));
disp_flag = 0;
for i = 2:1:size(raw,1)
    %%% Added 2017-10-24: Clean the F&S Dir phone number information, so
    %%% that all entries are formatted 905-xxx-xxx ext. xxxxx
    tmp = raw{i,phone_num_col};
    % Ensure we're working completely in strings:
    if ischar(tmp)~=1
        tmp = double2str(tmp);
    end
    tmp2 = tmp;
    %%% Pull out the extension
    if numel(tmp)>0 && numel(tmp)<7
        tmp = strrep(tmp,'x',''); % Remove leading 'x' (few cases)
        ext = tmp;
        phone_num = '905-525-9140';
        disp_flag = 0;
    elseif numel(tmp)>7
        ind = strfind(tmp,'x');
        if ~isempty(ind)==1
            ext = tmp(ind(end)+1:end);
            ext =strrep(ext,' ',''); % remove spaces
            phone_num = tmp(1:ind(end)-1);
        else
            ext = '';
            phone_num = tmp;
        end
        %%%Clean up phone number (if needed)
        phone_num = strrep(phone_num,'(','');
        phone_num = strrep(phone_num,')','');
        phone_num = regexprep(phone_num,'[a-z]','');
        phone_num = regexprep(phone_num,'[A-Z]','');
        phone_num = strrep(phone_num,' ','');
        if numel(phone_num)==10 %if there are no hyphens
            try
                phone_num = [phone_num(1:3) '-' phone_num(4:6) '-' phone_num(7:10)];
            catch
                disp('pause')
            end
        elseif numel(phone_num)==5 && strcmpi(tmp(1),'p')~=1
            ext = phone_num;
            phone_num = '905-525-9140';
        elseif numel(phone_num)==11 % Case where one hyphen is missing:
            if strcmp(phone_num(4),'-')==1
               % put hyphen before final 4 numbers
               phone_num = [phone_num(1:7) '-' phone_num(8:11)];
            else
                % put hyphen after area code
               phone_num = [phone_num(1:3) '-' phone_num(4:11)];
            end
        elseif numel(phone_num)<5
            phone_num = '';
        end
        disp_flag = 1;
    end
    
    % Replace existing value with updated one:
    if isempty(ext)==1 % If there's no extension, just use the phone number
        raw{i,phone_num_col} = phone_num;
    else    % if extension exists
        raw{i,phone_num_col} = [phone_num ' ext. ' ext];
    end
    
    if disp_flag == 1
        disp(['Original number: ' tmp2 ' New number: ' raw{i,phone_num_col}]);
    end
    fprintf(fid_out,'%s\n',sprintf('%s\t',raw{i,:}));
end
fclose(fid_out);
disp(['Cleaned version saved to ' FSdir_out_path '/FSDir-current.tsv']);

%%% update the tracker:
fid_tracker = fopen([FSdir_out_path '/current_tracker.txt'],'w');
fprintf(fid_tracker,'%s', ['Current version: ' fname_in]);
fclose(fid_tracker);

%%% Change directory back to original
cd(tmp_dir);