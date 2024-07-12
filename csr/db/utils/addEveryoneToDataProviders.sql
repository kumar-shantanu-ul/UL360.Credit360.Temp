DECLARE
	v_act				security_pkg.T_ACT_ID;
	v_app_sid			security_pkg.T_SID_ID;
	v_dp_group_sid		security_pkg.T_SID_ID;
BEGIN
	user_pkg.LogonAuthenticatedPath(0, '//csr/users/richard', 10000, v_act);
	SELECT app_sid
	  INTO v_app_sid
	  FROM customer
	 WHERE host = 'ica.credit360.com';
	v_dp_group_sid := securableobject_pkg.getsidfrompath(v_act, v_app_sid, 'Groups/Data Providers');
	begin
		insert into security.group_table (sid_id, group_type) values (v_dp_group_sid, 1);
	exception
		when dup_val_on_index then
			null;
	end;
	-- make everyone a member of dataproviders
	for r in (select csr_user_sid from csr_user where app_sid = v_app_sid)
	loop
		group_pkg.addmember(v_act, r.csr_user_sid, v_dp_group_sid);
	end loop;
END;
/
