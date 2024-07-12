-- Please update version.sql too -- this keeps clean builds in sync
define version=2179
@update_header

CREATE INDEX CSR.IDX_AUDIT_LOG_AUDIT_DATE_DESC ON CSR.AUDIT_LOG(APP_SID, AUDIT_DATE DESC) ONLINE;

@../csr_data_body

@update_tail
