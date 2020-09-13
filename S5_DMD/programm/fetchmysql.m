function [x,OK] = fetchmysql(sqlquery,format,dN,usr,pass)
if nargin < 2
    format = 1;
end
if nargin<3
    conna = database('futuredata','root','352471Cf','com.mysql.jdbc.Driver','jdbc:mysql://localhost:3306/futuredata?useSSL=false&');
else
    conna = database(dN,usr,pass);
end
% if nargin < 3
%     dN = 'mysql57';
% end
% if nargin < 4
%     usr = 'adair';
% end
% if nargin < 5
%     pass = 'lianghua2016';
% end


if eq(format,1)
    setdbprefs('DataReturnFormat','numeric');
else
    setdbprefs('DataReturnFormat','cellarray');
end
try
    if iscell(sqlquery)
        exec(conna,sqlquery{1});
        x = fetch(conna,sqlquery{2});
    else
        x = fetch(conna,sqlquery);
    end
    OK = true;
catch
    close(conna);
    OK = false;
    x = [];
end
close(conna);
