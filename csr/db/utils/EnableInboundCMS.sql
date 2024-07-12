PROMPT 1) Host / 2) Workflow label / 3) Oracle schema / 4) Oracle table name
declare 
	v_host			varchar(255) := '&&1';
    v_inbound_addr 	varchar2(255) := REPLACE(v_host, '.credit360.com', '@forms.credit360.com');
    v_account_name 	varchar2(255) := 'Inbound Forms';
    v_flow_label	varchar2(255) := '&&2';
    v_oracle_schema	varchar2(255) := '&&3';
    v_oracle_table	varchar2(255) := '&&4';
    v_region_sid	security.security_pkg.T_SID_ID := null; 
    v_account_sid   security.security_pkg.T_SID_ID;
    v_inbox_sid	    security.security_pkg.T_SID_ID;
    v_flow_sid	    security.security_pkg.T_SID_ID;
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
      
	BEGIN
		SELECT flow_sid
		  INTO v_flow_sid
		  FROM csr.flow
		 WHERE label = v_flow_label;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'The workflow with label '||v_flow_label||' could not be found');
	END;
	
	-- configure form
	INSERT INTO csr.inbound_cms_account (app_sid, account_sid, tab_sid, flow_sid, default_region_sid)
		VALUES (security_pkg.getapp, v_account_sid, 
			cms.tab_pkg.GetTableSid(v_oracle_schema, v_oracle_table), v_flow_sid, v_region_sid);

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
