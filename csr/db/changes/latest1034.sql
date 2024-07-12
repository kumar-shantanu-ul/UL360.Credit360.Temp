-- Please update version.sql too -- this keeps clean builds in sync
define version=1034
@update_header


ALTER TABLE CSR.DELEGATION_CHANGE_ALERT
DROP CONSTRAINT UK_DELEGATION_CHANGE_ALERT;

@../sheet_body

@update_tail