begin
	security.user_pkg.logonadmin('&&1');
	update csr.region 
	   set link_to_region_sid = null 
	 where region_sid in (
		select region_Sid
		  from csr.region 
		  where link_to_region_sid in (select region_sid from csr.region start with parent_sid = (select trash_sid from csr.customer) connect by prior region_sid = parent_sid)
			    start with parent_sid = app_sid connect by prior region_sid  = parent_sid);
end;
/
