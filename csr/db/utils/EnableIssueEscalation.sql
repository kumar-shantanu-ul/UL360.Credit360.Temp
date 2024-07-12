PROMPT please enter: host

BEGIN
	-- log on
	security.user_pkg.logonadmin('&&1');

	UPDATE csr.customer
	   SET issue_escalation_enabled = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	COMMIT;
END;
/
