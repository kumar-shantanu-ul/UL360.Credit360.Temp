-- Please update version.sql too -- this keeps clean builds in sync
define version=2212
@update_header

DROP INDEX CSR.IDX_AUDIT_LOG_AUDIT_DATE_DESC;
DROP INDEX CSR.IDX_AUDIT_LOG_USER_SID;
CREATE INDEX CSR.IDX_AUDIT_LOG_DATE_APP_USER ON CSR.AUDIT_LOG (APP_SID, USER_SID, AUDIT_DATE DESC) ONLINE;

@../csr_data_body

@update_tail
