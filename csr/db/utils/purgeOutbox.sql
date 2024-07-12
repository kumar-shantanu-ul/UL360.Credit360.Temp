declare
	v_cnt			NUMBER(10) := 0;
	v_mailbox_sid	security.security_pkg.T_SID_ID;
begin
	user_pkg.logonadmin('&&host');
	SELECT mailbox_sid
	  INTO v_mailbox_sid
      FROM mail.mailbox
     WHERE parent_sid = (
        SELECT root_mailbox_sid
          FROM mail.account
         WHERE email_address = (SELECT system_mail_address FROM customer)
     )
      AND mailbox_name = 'Outbox';
      
	for r in (
		select message_uid, mailbox_sid
		  from mail.message
		 where mailbox_sid = v_mailbox_sid
	)
	loop
		mail.mail_pkg.deleteMessage(r.mailbox_sid, r.message_uid);
		v_cnt := v_cnt + 1;
	end loop;
	
	dbms_output.put_line(v_cnt||' items deleted');
end;
/

