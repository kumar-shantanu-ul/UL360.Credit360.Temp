DECLARE
	v_host			csr.customer.host%TYPE;
	v_emailaddress	mail.account.email_address%TYPE;
	v_password		VARCHAR2(30);
	v_mailbox_sid	security_pkg.T_SID_ID;
	v_admins_sid	security_pkg.T_SID_ID;
BEGIN
	v_host := '&&host';
	v_emailaddress := '&&emailaddress';
	v_password := '&&password';
	
	-- Logon to host
	user_pkg.logonadmin(v_host);

	-- Create the mail account
	mail.mail_pkg.createAccount(
		v_emailaddress, 
		v_password, 
		v_mailbox_sid
	);
	
	-- Get hold of the host's adminstrators group sid
	v_admins_sid := securableobject_pkg.GetSidFromPath(
		security_pkg.getACT, 
		securableobject_pkg.GetSidFromPath(
			security_pkg.getACT, 
			security_pkg.getAPP, 
			'Groups'
		), 
		'Administrators'
	);
	
	-- Set permissions on the root folder and propagate
	acl_pkg.AddACE(
		security_pkg.GetACT, 
		acl_pkg.GetDACLIDForSID(v_mailbox_sid), 
		-1, 
		security_pkg.ACE_TYPE_ALLOW, 
		security_pkg.ACE_FLAG_DEFAULT, 
		v_admins_sid,
		security_pkg.PERMISSION_STANDARD_READ
	);
	
	acl_pkg.PropogateACEs(
		security_pkg.GetACT, 
		v_mailbox_sid
	);

	COMMIT;
	
END;
/

