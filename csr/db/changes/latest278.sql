-- Please update version.sql too -- this keeps clean builds in sync
define version=278
@update_header

ALTER TABLE customer ADD tracker_mail_address VARCHAR2(255);
ALTER TABLE customer ADD alert_mail_address VARCHAR2(255);
UPDATE customer SET tracker_mail_address = system_mail_address, alert_mail_address = system_mail_address;
ALTER TABLE customer MODIFY tracker_mail_address NOT NULL;
ALTER TABLE customer MODIFY alert_mail_address NOT NULL;
		
@..\csr_data_body
@..\schema_body
@..\csr_app_body

@update_tail
