CREATE OR REPLACE PACKAGE BODY csr.superadmin_api_pkg AS

PROCEDURE CreateSuperAdmin(
	in_user_name			csr_user.user_name%TYPE,
	in_full_name			csr_user.full_name%TYPE,
	in_friendly_name		csr_user.friendly_name%TYPE,
	in_email				csr_user.email%TYPE
)
AS
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;

	csr_user_pkg.createSuperAdmin(
		in_act				=> security.security_pkg.GetACT,
		in_user_name		=> in_user_name,
		in_password			=> NULL,
		in_full_name		=> in_full_name,
		in_friendly_name	=> in_friendly_name,
		in_email			=> in_email,
		out_user_sid		=> v_user_sid
	);
END;

PROCEDURE GetPasswordResetACT(
	in_user_name			IN	csr_user.user_name%TYPE,
	in_host					IN  security.website.website_name%TYPE,
	out_user_act			OUT	security.security_pkg.T_ACT_ID
)
AS
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin(
		host			=> in_host
	);
	
	v_user_sid := security.securableobject_pkg.GetSIDFromPath(
		in_act				=> security.security_pkg.GetACT,
		in_parent_sid_id	=> 0,
		in_path				=> '//csr/users/'||in_user_name
	);

	security.user_pkg.LogonAuthenticated(
		in_sid_id		=> v_user_sid,
		in_act_timeout	=> 3600,
		in_app_sid		=> security.security_pkg.GetApp,
		out_act_id		=> out_user_act
	);
END;


PROCEDURE DisableSuperAdmin(
	in_user_name			csr_user.user_name%TYPE
)
AS
	v_act 				security.security_pkg.T_ACT_ID;
	v_user_sid 			security.security_pkg.T_SID_ID;
	v_group_sid			security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAdmin;

	v_act := security.security_pkg.GetACT;

	v_user_sid := security.securableobject_pkg.GetSIDFromPath(v_act, 0, 'Csr/Users/'||in_user_name);
	v_group_sid := security.securableobject_pkg.GetSIDFromPath(v_act, 0, 'Csr/SuperAdmins');

	-- Remove from superadmin group
	security.group_pkg.DeleteMember(v_act, v_user_sid, v_group_sid);

	-- Disable account
	security.user_pkg.DisableAccount(v_act, v_user_sid);
	dbms_output.put_line('Disabled account(s) for user SID ' || v_user_sid);

	-- Update OWL.EMPLOYEE record where it exists.
	FOR r IN (
		SELECT 1
		  FROM all_tables
		 WHERE owner = 'OWL' AND table_name = 'EMPLOYEE'
	) LOOP
		EXECUTE IMMEDIATE 'UPDATE owl.employee SET employed = 0 WHERE csr_user_sid = :v_user_sid'
		USING v_user_sid;
	END LOOP;

	-- Audit log entry to all sites
	FOR r IN (
		SELECT app_sid
		  FROM csr.csr_user
		 WHERE csr_user_sid = v_user_sid
	)
	LOOP
		csr.csr_data_pkg.WriteAuditLogEntry(
			in_act_id			=> v_act,
			in_audit_type_id	=> csr.csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT,
			in_app_sid			=> r.app_sid,
			in_object_sid		=> v_user_sid,
			in_description		=> 'Deactivated'
		);
	END LOOP;
END;

END;
/