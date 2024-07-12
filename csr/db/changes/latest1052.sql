-- Please update version.sql too -- this keeps clean builds in sync
define version=1052
@update_header

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_ALERT_BATCH_ISSUES 
(
	APP_SID							NUMBER(10), 
	ISSUE_LOG_ID					NUMBER(10), 
	CSR_USER_SID					NUMBER(10), 
	FRIENDLY_NAME					VARCHAR2(255),
	FULL_NAME						VARCHAR2(256),
	EMAIL							VARCHAR2(256)
) ON COMMIT DELETE ROWS;

@../issue_body

@update_tail
