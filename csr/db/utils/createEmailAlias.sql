declare
	v_email_alias varchar2(200) := '&&1';
	v_email_address varchar2(200) := '&&2';
	v_account_sid number;
begin
	security.user_pkg.logonadmin;
	
	begin
		select account_sid
		  into v_account_sid
		  from mail.account
		 where lower(email_address) = lower(trim(v_email_address));
	exception
		when no_data_found then
			raise_application_error(-20001, 'No account found for ' || v_email_address);
	end;

	mail.mail_pkg.addAccountAlias(v_account_sid, trim(v_email_alias)); -- Catches duplicate addresses

	dbms_output.put_line('Alias ' || v_email_alias || ' set up for account ' || v_email_address || '. Commit or rollback.');
end;
/
