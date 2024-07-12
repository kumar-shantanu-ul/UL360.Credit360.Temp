-- Expires all standard user passwords (excluding superusers) for a given site.
SET SERVEROUTPUT ON

DECLARE
    v_host					VARCHAR2(255) := '&&1';
    v_pass_expire_val		NUMBER;	-- Current set pass expire val.
    v_pass_last_set_val		NUMBER;	-- When user last changed password.
	
	no_expiry_time_set		EXCEPTION;
BEGIN
	security.user_pkg.LogonAdmin(v_host);

    SELECT ap.max_password_age INTO v_pass_expire_val
	  FROM security.account_policy ap
	  JOIN csr.customer c ON ap.sid_id = c.account_policy_sid;
	
	-- Check if a password expiry time has been set.
    IF v_pass_expire_val IS NULL THEN
		RAISE no_expiry_time_set;
    END IF;
	
    v_pass_last_set_val := v_pass_expire_val + 1;

    -- Now expire all user's passwords (not including super admins and daemon users) by setting
    -- their last password change longer than the password expiry time.
	UPDATE security.user_table
	   SET last_password_change = SYSDATE - v_pass_last_set_val
	 WHERE sid_id NOT IN (SELECT csr_user_sid FROM csr.superadmin)
	   AND sid_id IN (SELECT csr_user_sid FROM csr.csr_user)
	   AND sid_id IN (
	          SELECT sid_id FROM security.securable_object
	           START WITH application_sid_id = security.security_pkg.GetApp
	         CONNECT BY PRIOR sid_id = parent_sid_id
	   )
	   AND sid_id NOT IN (SELECT csr_user_sid FROM csr.csr_user WHERE hidden = 0)
	   AND login_password IS NOT NULL;
	   
	   dbms_output.put_line(sql%rowcount || ' users reset');
EXCEPTION
	-- Thrown if no password expiry time has been set in ACCOUNT_POLICY table.
	WHEN no_expiry_time_set THEN
		dbms_output.put_line('***ERROR: No password expiry time has been set for the site.***');
END;
/