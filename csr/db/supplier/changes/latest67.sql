-- Please update version.sql too -- this keeps clean builds in sync
define version=67
@update_header
	
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, AUDIT_TYPE_GROUP_ID) VALUES (77 , 'GT questionnaire copied', 3);





@update_tail
