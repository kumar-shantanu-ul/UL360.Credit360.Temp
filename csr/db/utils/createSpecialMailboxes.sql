declare
	v_account_sid 		number;
	v_root_mailbox_sid 	number;
	v_folder_sid 		number;
begin
	security.user_pkg.logonadmin;

	select account_sid, root_mailbox_sid
	  into v_account_sid, v_root_mailbox_sid
	  from mail.account
	 where lower(email_address) = '&&1';

	begin
		mail.mailbox_pkg.createMailbox(v_root_mailbox_sid, 'Drafts', v_account_sid, v_folder_sid);
	exception
		when security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_folder_sid := mail.mail_pkg.getMailboxSIDFromPath(v_root_mailbox_sid, 'Drafts');
	end;
	update mail.mailbox 
	   set special_use = mail.mail_pkg.SU_Drafts
	 where mailbox_sid = v_folder_sid;

	begin
		mail.mailbox_pkg.createMailbox(v_root_mailbox_sid, 'Junk E-mail', v_account_sid, v_folder_sid);
	exception
		when security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_folder_sid := mail.mail_pkg.getMailboxSIDFromPath(v_root_mailbox_sid, 'Junk E-mail');
	end;
	update mail.mailbox 
	   set special_use = mail.mail_pkg.SU_Junk 
	 where mailbox_sid = v_folder_sid;

	begin
		mail.mailbox_pkg.createMailbox(v_root_mailbox_sid, 'Deleted Items', v_account_sid, v_folder_sid);
	exception
		when security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_folder_sid := mail.mail_pkg.getMailboxSIDFromPath(v_root_mailbox_sid, 'Deleted Items');
	end;
	update mail.mailbox 
	   set special_use = mail.mail_pkg.SU_Trash 
	 where mailbox_sid = v_folder_sid;

	begin
		mail.mailbox_pkg.createMailbox(v_root_mailbox_sid, 'Sent Items', v_account_sid, v_folder_sid);
	exception
		when security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_folder_sid := mail.mail_pkg.getMailboxSIDFromPath(v_root_mailbox_sid, 'Sent Items');
	end;
	update mail.mailbox 
	   set special_use = mail.mail_pkg.SU_Sent 
	 where mailbox_sid = v_folder_sid;
end;
/
