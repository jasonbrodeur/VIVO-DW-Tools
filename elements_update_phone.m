function [response] = elements_update_phone(uname, phone_num,KeyValue,sys)
% uname = 'brodeujj';
% phone_num = '905-525-9140 x28043';

top_path = 'D:\Seafile\VIVO_Secure_Data\VIVO-DW-Tools\';
save_dir = [top_path 'Elements\'];

switch lower(sys)
    case 'prod'
api_path = 'https://expertsmanager.mcmaster.ca:8091/secure-api/v5.5';
    case 'dev'
api_path = 'https://expertsmanagerdev.mcmaster.ca:8091/secure-api/v5.5';
    otherwise
        disp('input argument sys needs to be either ''prod'' or ''dev''. Exiting');
        return;
end

% If the secrets file isn't included, load it.
% % % if exist('secrets','var')==1
% % %     try
% % %         KeyValue = secrets.API.KeyValue;
% % %     catch
% % %         disp('can''t load KeyValue from secrets file. Exiting');
% % %         return;
% % %     end
% % % else
% % %     disp('can''t find secrets file. Exiting');
% % %     return;
% % % end
%         KeyValue = secrets.API.KeyValue;
%     else
% else    
%     load([top_path 'secrets.mat'])
%     if isfield(secrets.API,'KeyValue')==1
%         KeyValue = secrets.API.KeyValue;
%     else
%         % if no KeyValue exists, generate the authentication string from username and password:
%         KeyValue = ['Basic ' base64encode([secrets.API.username ':' secrets.API.password])];
%         secrets.API.KeyValue = KeyValue;
%          save([top_path 'secrets.mat'],'secrets');
%     end
% end
%% Set weboptions for get and patch operations:
options_get = weboptions('Timeout',10,'KeyName','Authorization','KeyValue',KeyValue); %This works
options_patch = weboptions('Timeout',10,'KeyName','Authorization','KeyValue',KeyValue,'RequestMethod','patch',...
    'MediaType','text/xml','HeaderFields',{'ContentType' 'text/xml'});

%% Perform GET (to retrieve record-id), and then PATCH to update the phone number

% %%% These variables will disappear - for testing purposes only:

%%% Perform a GET to pull the user record:
websave([save_dir 'user-get-temp.xml'],[api_path '/users/username-' uname],options_get);
% user_get_temp = webread([el_dev_secure '/users/username-' uname],options_get);

%%% api:record has an attribute id-at-source="xxxxxxxx" <-- this needs
%%% to be extracted and then used in the PATCH command
% Pull out the value of attribute: id-at-source (e.g. mine in expertsdev is
% 82CE569E-0FBF-486F-9F2B-C2D2FCBAA5A9
s_tmp = xml2struct([save_dir 'user-get-temp.xml']); %converts xml to a structure array
record_id = s_tmp.feed.entry.apiu_colonu_object.apiu_colonu_records.apiu_colonu_record.Attributes.id_dash_at_dash_source; %extracts the attribute of interest

% Create the XML document that will be sent in the PATCH request to update the phone number: 
clear c;
c.update_record.Attributes.xmlns = 'http://www.symplectic.co.uk/publications/api';
c.update_record.Attributes.type_id = '1';
c.update_record.fields.field{1}.Attributes.name = 'phone-numbers';
c.update_record.fields.field{1}.Attributes.operation = 'set';
c.update_record.fields.field{1}.phone_numbers{1}.phone_number{1}.Attributes.privacy = 'public';
c.update_record.fields.field{1}.phone_numbers{1}.phone_number{1}.number.Text = phone_num;
c.update_record.fields.field{1}.phone_numbers{1}.phone_number{1}.type.Text = 'work';
xml = struct2xml(c);        % creates the xml from the structure array
xml = strrep(xml,'_','-');  % changes underscores to dashes in field names.

% PATCH operation to update phone number at /user/records/manual/<id-at-source>
response = webwrite([api_path '/user/records/manual/' record_id],xml,options_patch);

%% Earlier tests
%{
tmp = webread([el_prod_secure '/user-feed/users/username-brodeujj'],options);
websave([save_dir 'test.xml'],[el_prod_secure '/user-feed/users/username-brodeujj'],options);
websave([save_dir 'test.xml'],[el_prod_secure '/users?username=brodeujj'],options);
websave([save_dir 'test2.xml'],[el_prod_secure '/users/username-brodeujj'],options);
websave([save_dir 'test4-get.xml'],[el_dev_secure '/users/username-brodeujj'],options_get);
websave([save_dir 'test5-get.xml'],[el_dev_secure '/user-feed/users/username-brodeujj'],options_get);

%% 
%%% Get a list of types
websave([save_dir 'user-ops.xml'],[el_dev_secure '/user/types'],options_get);
websave([save_dir 'user-sources.xml'],[el_dev_secure '/user/sources'],options_get);
fid = fopen('test_cmd.txt','r');
data = fscanf(fid,'%s');
fclose(fid);
save('text_cmd.mat','data');


test = '<user-feed-entry xmlns="http://www.symplectic.co.uk/publications/api">
names = {'user-feed-entry' ; 'phone-number'};

clear s
s.userfeedentry.Attributes.xmlns = 'http://www.symplectic.co.uk/publications/api';
s.userfeedentry.phonenumber{1}.Attributes.privacy = 'public';
s.userfeedentry.phonenumber{1}.number.Text = '905-525-9140 x28043';
s.userfeedentry.phonenumber{1}.type.Text = 'work';
xml = struct2xml(s)

xml2 = strrep(xml,'userfeedentry','user-feed-entry');
xml2 = strrep(xml2,'phonenumber','phone-number');
disp(xml2)

response = webwrite([el_dev_secure '/user-feed/users/username-brodeujj'],xml2,options_put)
response = webwrite([el_dev_secure '/users/006004067'],xml2,options_put)

clear t;
t.userfeedentry.Attributes.xmlns = 'http://www.symplectic.co.uk/publications/api';
t.userfeedentry.knownas{1}.Text = 'JJ';
clear xml_t
xml_t = struct2xml(t)
xml_t = strrep(xml_t,'userfeedentry','user-feed-entry');
xml_t = strrep(xml_t,'knownas','known-as');
disp(xml_t)
response = webwrite([el_dev_secure '/user-feed/users/username-brodeujj'],xml_t,options_put)

clear c;
c.update_record.Attributes.xmlns = 'http://www.symplectic.co.uk/publications/api';
c.update_record.fields.field{1}.Attributes.name = 'phone-numbers';
c.update_record.fields.field{1}.Attributes.operation = 'set';
c.update_record.fields.field{1}.phone_number{1}.Attributes.privacy = 'public';
c.update_record.fields.field{1}.phone_number{1}.number.Text = '905-525-9140 x28043';
c.update_record.fields.field{1}.phone_number{1}.type.Text = 'work';
%%% Attempt 2
clear c;
c.update_record.Attributes.xmlns = 'http://www.symplectic.co.uk/publications/api';
c.update_record.fields.field{1}.Attributes.name = 'phone-numbers';
c.update_record.fields.field{1}.Attributes.operation = 'set';
c.update_record.fields.field{1}.phone_numbers{1}.phone_number{1}.Attributes.privacy = 'public';
c.update_record.fields.field{1}.phone_numbers{1}.phone_number{1}.number.Text = '905-525-9140 x28043';
c.update_record.fields.field{1}.phone_numbers{1}.phone_number{1}.type.Text = 'work';
%%% Attempt 3
clear c;
c.update_record.Attributes.xmlns = 'http://www.symplectic.co.uk/publications/api';
c.update_record.fields.field{1}.Attributes.name = 'phone-numbers';
% c.update_record.fields.field{1}.Attributes.operation = 'set';
c.update_record.fields.field{1}.phone_numbers{1}.Attributes.operation = 'set';
c.update_record.fields.field{1}.phone_numbers{1}.phone_number{1}.Attributes.privacy = 'public';
c.update_record.fields.field{1}.phone_numbers{1}.phone_number{1}.number.Text = '905-525-9140 x28043';
c.update_record.fields.field{1}.phone_numbers{1}.phone_number{1}.type.Text = 'work';
xml = struct2xml(c);
xml = strrep(xml,'_','-');
%}
