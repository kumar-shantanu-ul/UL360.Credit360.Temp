PROMPT please enter: 1. username [without the leading slashes], 2. full name, 3. friendly name and 4. email address
DECLARE
	v_act 	security.security_pkg.T_ACT_ID;
	v_sid 	security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticatedPath(
		in_parent_sid			=> 0,
		in_user_path			=> '//builtin/administrator',
		in_act_timeout			=> 500,
		out_act_id				=> v_act);

	csr.superadmin_api_pkg.CreateSuperAdmin(
		in_user_name			=> '&&1',
		in_full_name			=> '&&2',
		in_friendly_name		=> '&&3',
		in_email				=> '&&4');
END;
/
commit;
PROMPT If this is a new UK superadmin add them to gsk`s C360_SA_UK group 
exit
