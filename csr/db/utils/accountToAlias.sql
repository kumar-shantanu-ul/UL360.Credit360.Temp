/*
	PLEASE NOTE THIS FILE NAME SUGGEST YOU ARE TURNING THE EMAIL ACCOUNT YOU PASS TO THIS SCRIPT INTO AN ALIAS.
	IT'S ACTUALLY THE OTHER WAY AROUND: PASS IT THE PRIMARY EMAIL ADDRESS AND IT WILL TURN ALL THE OTHER EMAIL ACCOUNTS WHICH "SHARE" THE SAME INBOX INTO ALIASES
*/
declare
	v_email_address varchar2(200) := '&&1';
	v_inbox_sid number;
	v_account_sid number;
	v_root_mailbox_sid number;
	v_root_mailbox_name varchar2(200);
begin
	security.user_pkg.logonadmin;
	
	begin
		select inbox_sid, account_sid, root_mailbox_sid
		  into v_inbox_sid, v_account_sid, v_root_mailbox_sid
		  from mail.account
		 where lower(email_address) = lower(v_email_address);
	exception
		when no_data_found then
			raise_application_error(-20001, 'No account found for '||v_email_address);
	end;
	 
	select mailbox_name
	  into v_root_mailbox_name
	  from mail.mailbox
	 where mailbox_sid = v_root_mailbox_sid;
	 
	if lower(v_root_mailbox_name) != lower(v_email_address) then
		raise_application_error(-20001,
			v_root_mailbox_name||' appears to be the primary mail address for the linked accounts, not '||v_email_address);
	end if;

	for r in (select account_sid, email_address
				from mail.account
			   where inbox_sid = v_inbox_sid and account_sid != v_account_sid) loop

		delete from mail.vacation_notified
		 where account_sid = r.account_sid;
		delete from mail.vacation
		 where account_sid = r.account_sid;
		delete from mail.user_account
		 where account_sid = r.account_sid;
		delete from mail.account
		 where account_sid = r.account_sid;
		delete from mail.account_alias
		 where account_sid = r.account_sid;
		 
		securableobject_pkg.deleteso(sys_context('security','act'), r.account_sid);

		insert into mail.account_alias (account_sid, email_address)
		values (v_account_sid, r.email_address);
		dbms_output.put_line('replaced '||r.email_address||' with an alias');
	end loop;
end;
/

