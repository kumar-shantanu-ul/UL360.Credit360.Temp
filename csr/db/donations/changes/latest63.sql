-- Please update version.sql too -- this keeps clean builds in sync
define version=63
@update_header

Insert into CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) values (85,'Recipient',1);

@update_tail
