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

%% Write to FSdir_out_path
fid_out = fopen([FSdir_out_path '/FSDir-current.tsv'],'w');
for i = 1:1:size(raw,1)
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