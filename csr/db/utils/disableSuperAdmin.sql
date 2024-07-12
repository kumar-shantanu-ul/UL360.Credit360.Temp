SET SERVEROUTPUT ON

PROMPT please enter: username (without the slashes) then email
DEFINE usr = '&&1'
DEFINE email = '&&2'

DECLARE
	v_act 				security.security_pkg.T_ACT_ID;
	v_user_sid 			security.security_pkg.T_SID_ID;
	v_group_sid			security.security_pkg.T_ACT_ID;
	v_account_sid 		security.security_pkg.T_SID_ID;
	v_random_pwd		VARCHAR2(20);
	v_exists			NUMBER;
BEGIN
	security.user_pkg.LogonAuthenticatedPath(0, '//builtin/administrator', 500, v_act);
	v_group_sid := security.securableobject_pkg.GetSIDFromPath(v_act, 0, 'Csr/SuperAdmins');
	
	BEGIN
		v_user_sid := security.securableobject_pkg.GetSIDFromPath(v_act, 0, 'Csr/Users/&&usr');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			-- www.credit360.com user
			v_user_sid := security.securableobject_pkg.GetSIDFromPath(v_act, 0, '//aspen/applications/www.credit360.com/Users/&&usr');
	END;

	-- Remove from superadmin group
	security.group_pkg.DeleteMember(v_act, v_user_sid, v_group_sid);

	-- Disable account
	security.user_pkg.DisableAccount(v_act, v_user_sid);
	dbms_output.put_line('Disabled account(s) for user SID ' || v_user_sid);

	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_tables
	 WHERE owner = 'OWL' AND table_name = 'EMPLOYEE';

	IF v_exists = 1 THEN
		EXECUTE IMMEDIATE 'UPDATE owl.employee SET employed = 0 WHERE csr_user_sid = :v_user_sid'
		USING v_user_sid;
	END IF;

	-- scramble email password.
	BEGIN
		v_account_sid := security.securableobject_pkg.GetSIDFromPath(v_act, 0, '//Mail/Accounts/&&email');
		UPDATE mail.account
		   SET password = NULL
		 WHERE account_sid = v_account_sid;
		dbms_output.put_line('Email account &&email disabled');

	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			dbms_output.put_line('Email account for &&email not found');
	END;

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

	-- Remove existing sessions
	DELETE FROM security.act WHERE sid_id = v_user_sid;
END;
/

COMMIT;
EXIT
