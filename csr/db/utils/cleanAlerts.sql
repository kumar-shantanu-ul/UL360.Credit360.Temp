declare
    v_mailbox_sid   security.security_pkg.T_SID_ID;
    v_uids          security.security_pkg.T_SID_IDS;
begin
    security.user_pkg.logonadmin('&&usr');
    dbms_output.put_line('Deleting bounces...');
    delete from alert_bounce where app_sid = security_pkg.getapp;
    
    -- Outbox
    v_mailbox_sid := csr.alert_pkg.GetSystemMailbox('Outbox');
    
    SELECT message_uid 
      BULK COLLECT INTO v_uids
      FROM mail.message
     WHERE mailbox_sid = v_mailbox_sid; 

    dbms_output.put_line(v_uids.count()||' to be deleted from Outbox...');
    mail.webmail_pkg.deletemessages(v_mailbox_sid, v_uids);

    -- Sent
    v_mailbox_sid := csr.alert_pkg.GetSystemMailbox('Sent');
    
    SELECT message_uid 
      BULK COLLECT INTO v_uids
      FROM mail.message
     WHERE mailbox_sid = v_mailbox_sid; 

    dbms_output.put_line(v_uids.count()||' to be deleted from Sent items...');
    mail.webmail_pkg.deletemessages(v_mailbox_sid, v_uids);
end;
/
