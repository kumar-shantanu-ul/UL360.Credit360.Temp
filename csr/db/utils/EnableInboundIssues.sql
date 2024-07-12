PROMPT 1) Host
declare 
	v_host			varchar(255) := '&&1';
    v_inbound_addr 	varchar2(255) := REPLACE(v_host, '.credit360.com', '@issues.credit360.com');
    v_account_name 	varchar2(255) := 'Issues';
    v_account_sid   security.security_pkg.T_SID_ID;
    v_inbox_sid	    security.security_pkg.T_SID_ID;
    v_mailbox_sid   security.security_pkg.T_SID_ID;
    v_root_mailbox_sid security.security_pkg.T_SID_ID;
begin
    user_pkg.logonadmin;
    -- create email account (the @xxx part must be configured in Yam\smtpd.pl to forward to Oracle)
    mail.mail_pkg.createAccount(v_inbound_addr, 'sdn3!fed_gwJWWgPWa', v_account_name, v_account_sid, v_root_mailbox_sid);
    v_inbox_sid := securableobject_pkg.getsidfrompath(security_pkg.getact, v_root_mailbox_sid, 'Inbox');
    mail.mailbox_pkg.createMailbox(v_inbox_sid, 'Invalid e-mails', v_account_sid, v_mailbox_sid);
    
    -- pull ids
    user_pkg.logonadmin(v_host);

	-- configure form
	INSERT INTO csr.inbound_issue_account (app_sid, account_sid, issue_type_id)
		VALUES (security_pkg.getapp, v_account_sid, csr.csr_data_pkg.ISSUE_ENQUIRY);

	UPDATE csr.issue_type 
	   SET alert_mail_address = v_inbound_addr, 
		alert_mail_name= v_account_name 
	WHERE issue_type_id = csr.csr_data_pkg.ISSUE_ENQUIRY
	  AND app_sid = security_pkg.getapp;

	-- alerts
	INSERT INTO csr.customer_alert_type (customer_alert_type_id, std_alert_type_id) 
		SELECT csr.customer_alert_type_id_seq.nextval, std_alert_type_id
		  FROM (
			SELECT std_alert_type_id 
			  FROM csr.std_alert_type 
			 WHERE std_alert_type_id IN (41, 42)
			  MINUS
			SELECT std_alert_type_id 
			  FROM csr.customer_alert_type
		 );
	
end;
/
