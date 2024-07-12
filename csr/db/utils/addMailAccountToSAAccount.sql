prompt enter sa account, mail address
declare
	v_account_sid 		security.security_pkg.t_sid_id;
	v_root_mailbox_sid	security.security_pkg.t_sid_id;
	v_sa_sid 			security.security_pkg.t_sid_id;
begin
	security.user_pkg.logonadmin;
	v_sa_sid := security.securableobject_pkg.getsidfrompath(null,0,'&&1');
	select account_sid, root_mailbox_sid
	  into v_account_sid, v_root_mailbox_sid
	  from mail.account 
	 where email_address='&&2';
	insert into mail.user_account (user_sid, account_sid) 
	values (v_sa_sid, v_account_sid);
	security.acl_pkg.AddACE(sys_context('security', 'act'), 
		security.acl_pkg.GetDACLIDForSID(v_account_sid),
		security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_account_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(sys_context('security', 'act'), 
		security.acl_pkg.GetDACLIDForSID(v_root_mailbox_sid),
		security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_root_mailbox_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
end;
/
