PROMPT Enter the email address to create the link for
declare
	v_email_address		varchar2(255) := '&&1';
	v_root_mailbox_sid	number;
	v_new_mailbox_sid	number;
begin
	user_pkg.logonadmin;
	
	select distinct root_mailbox_sid
	  into v_root_mailbox_sid
	  from mail.account
	  left join mail.account_alias on mail.account.account_sid = mail.account_alias.account_sid
	 where lower(account.email_address) = lower(v_email_address) or lower(account_alias.email_address) = lower(v_email_address);

	mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Technical Support (Shared)', v_new_mailbox_sid);
	update mail.mailbox 
	   set link_to_mailbox_sid = 16726160
	 where mailbox_sid = v_new_mailbox_sid;
end;
/

quit;
