-- Please update version.sql too -- this keeps clean builds in sync
define version=846
@update_header

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_CSR_USER (
	APP_SID							NUMBER(10) NOT NULL,
	CSR_USER_SID 					NUMBER(10) NOT NULL, 
	CONSTRAINT PK_TEMP_CSR_USER PRIMARY KEY (APP_SID, CSR_USER_SID)
)
ON COMMIT DELETE ROWS;

@..\alert_body

@update_tail
