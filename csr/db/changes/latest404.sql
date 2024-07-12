-- Please update version.sql too -- this keeps clean builds in sync
define version=404
@update_header


BEGIN
    FOR r IN (
        SELECT alt.app_sid, alert_Type_id, 
            REPLACE(
                REPLACE(mail_body, 'https://'||c.host||'#SHEET_URL#', '#SHEET_URL#'),
                'http://'||c.host||'#SHEET_URL#', '#SHEET_URL#') mail_body
          FROM alert_template alt 
            INNER JOIN customer c ON alt.app_sid = c.app_sid
         WHERE dbms_lob.instr(mail_body,c.host||'#SHEET_URL#') > 0
         UNION ALL
        SELECT alt.app_sid, alert_Type_id, 
            REPLACE(
                REPLACE(mail_body, 'https://'||c.host||'/#SHEET_URL#', '#SHEET_URL#'),
                'http://'||c.host||'/#SHEET_URL#', '#SHEET_URL#') mail_body
          FROM alert_template alt
            INNER JOIN customer c ON alt.app_sid = c.app_sid
         WHERE dbms_lob.instr(mail_body,c.host||'/#SHEET_URL#') > 0
    )
    LOOP
        UPDATE alert_template 
           SET mail_body = r.mail_body
         WHERE alert_type_id = r.alert_type_id
           AND app_sid = r.app_sid;
    END LOOP;
END;
/


@../alert_body

@update_tail
