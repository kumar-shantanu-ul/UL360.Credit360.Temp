PROMPT Enter superadmin username, email address
PROMPT e.g. joe joe.bloggs@credit360.com

DECLARE
	v_user_sid		Security_Pkg.T_SID_ID;
	v_folder_sid	Security_Pkg.T_SID_ID;
	v_account_sid	Security_Pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonAdmin;
	v_user_sid := security.securableobject_pkg.getsidfrompath(security_pkg.getact, 0, '//csr/Users/&&1');
	v_account_sid := security.securableobject_pkg.getsidfrompath(security_pkg.getact, 0, '//Mail/Accounts/&&2');
	v_folder_sid := security.securableobject_pkg.getsidfrompath(security_pkg.getact, 0, '//Mail/Folders/&&2');

	INSERT INTO mail.user_account (user_sid, account_sid) VALUES (v_user_sid, v_account_sid);
	
	-- Give superadmin permissions on email account
	security.acl_pkg.AddACE(security.security_pkg.getact, security.acl_pkg.GetDACLIDForSID(v_account_sid), -1, 
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_user_sid, 
		security.security_pkg.PERMISSION_STANDARD_ALL);

	-- Give superadmin permissions on the folders
	security.acl_pkg.AddACE(security.security_pkg.getact, security.acl_pkg.GetDACLIDForSID(v_folder_sid), -1, 
		security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_user_sid, 
		security.security_pkg.PERMISSION_STANDARD_ALL);
END;
/