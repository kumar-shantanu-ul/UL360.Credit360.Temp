BEGIN
	security.user_pkg.LogonAdmin('&&host');
	
	UPDATE csr.internal_audit
	   SET flow_item_id = NULL
	 WHERE internal_audit_sid IN (
		SELECT internal_audit_sid
		  FROM csr.migrated_audit
	 );
END;
/
