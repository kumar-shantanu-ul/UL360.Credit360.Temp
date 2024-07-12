PROMPT Enter website host name for which you want to enable SSL
begin
	update security.website 
	   set secure_only = 1
	 where website_name = '&&1';
	
	commit;
end;
/
exit

PROMPT You will now need to IISReset the webserver

