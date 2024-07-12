-- when you use csrimp, users can get trashed if their accounts have expired etc
DECLARE
	v_act				security_pkg.T_ACT_ID;
	v_app_sid			security_pkg.T_SID_ID;
BEGIN
	user_pkg.LogonAuthenticatedPath(0, '//csr/users/richard', 10000, v_act);
	SELECT app_sid 
	  INTO v_app_sid 
	  FROM customer
	 WHERE host = 'eontest.credit360.com';
	for r in (
		select ut.sid_id from csr_user cu, security.user_table ut 
		 where app_sid = v_app_sid
		   and cu.csr_user_sid = ut.sid_id
		   and ut.account_enabled = 0
	)
	loop
		trash_pkg.RestoreObject(v_act, r.sid_id);
		csr_user_pkg.activateUser(v_act, r.sid_id);
	end loop;
END;
/
