-- Please update version.sql too -- this keeps clean builds in sync
define version=294
@update_header

--Fix the mime type on existing email templates
UPDATE alert_template 
SET mime_type='text/html'
WHERE (dbms_lob.instr(mail_body, '<div>')>0 
OR dbms_lob.instr(mail_body, '<body>')>0 
OR dbms_lob.instr(mail_body, '<html>')>0
OR dbms_lob.instr(mail_body, '<p>')>0 ) 
AND mime_type = 'text/plain' ;

COMMIT;

@update_tail
