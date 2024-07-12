declare
	v_act	security_pkg.T_ACT_ID;
	in_user_sid	security_pkg.T_SID_ID;
begin
	in_user_sid := securableobject_pkg.GetSidFromPath(v_act, 0, '/csr/users/&&1');
	user_pkg.LogonAuthenticatedPath(0, '//builtin/administrator', 10000, v_act);
	user_pkg.EnableAccount(v_act, in_user_sid);
	update csr_user set failed_logon_attempts = 0 where csr_user_sid = in_user_sid;
end;
/
commit;
