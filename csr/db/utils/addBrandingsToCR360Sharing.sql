declare
	v_client_sids	security.T_SID_TABLE;
begin
	security.user_pkg.logonadmin('www.credit360.com');
	
	select client_sid bulk collect into v_client_sids from owl.owl_client where active = 1;

	user_pkg.logonadmin('cr360sharing.credit360.com');
	csr.enable_pkg.EnableChangeBranding;

	insert into csr.branding_availability (app_sid, client_folder_name)
		select security.security_pkg.getApp, client_folder_name 
		  from csr.branding 
         where client_folder_name in (
			select ltrim(rtrim(regexp_substr(default_stylesheet,'/[^/]*/'),'/'),'/') 
			  from aspen2.application 
			 where app_sid in (
				select column_value from table(v_client_sids)
			)
		)
		 and client_folder_name not in (
			select client_folder_name 
		      from csr.branding_availability
		     where app_sid = security.security_pkg.getApp
		);
end;
/
