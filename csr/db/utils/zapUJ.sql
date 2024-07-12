declare
	v_account_sid		NUMBER(10);
	v_tracker_sid		NUMBER(10);
	v_site_name			VARCHAR2(255) := substr('&&1', 1, instr('&&1', '.') - 1);
begin
	security.user_pkg.LogonAdmin('&&1');
	SELECT account_sid
	  INTO v_account_sid
	  FROM mail.account
	 WHERE lower(email_address) = lower(v_site_name || '@credit360.com');
	 
	SELECT account_sid
	  INTO v_tracker_sid
	  FROM mail.account
	 WHERE lower(email_address) = lower(v_site_name || '_tracker@credit360.com');
	
	mail.mail_pkg.deleteAccount(v_account_sid);
	mail.mail_pkg.deleteAccount(v_tracker_sid);
end;
/

@c:\cvs\csr\db\utils\zapCsr.sql &&1

EXIT