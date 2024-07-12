PROMPT Enter website host name for which you want to disable SSL
begin
	update security.website 
	   set secure_only = 0 
	 where website_name = '&&1';
	 
	update security.web_resource  
	   set ip_rule_id = null 
     where web_root_Sid_id in (
		select web_root_sid_id 
		  from security.website 
		 where website_name='&&1'
	);
	commit;
end;
/
exit

PROMPT You will now need to IISReset the webserver

