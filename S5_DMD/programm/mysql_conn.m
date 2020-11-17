function conna = mysql_conn()

conna = database('futuredata','root','352471Cf','com.mysql.jdbc.Driver',...
    'jdbc:mysql://localhost:3306/futuredata?useSSL=false&');