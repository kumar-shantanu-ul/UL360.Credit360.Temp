-- Please update version.sql too -- this keeps clean builds in sync
define version=772
@update_header

CREATE GLOBAL TEMPORARY TABLE CSR.temp_alert_batch_details
(
	app_sid							NUMBER(10) NOT NULL,
	csr_user_sid					NUMBER(10) NOT NULL,
	full_name						VARCHAR2(256), 
	friendly_name					VARCHAR2(256) NOT NULL, 
	email							VARCHAR2(256),         	
	user_name						VARCHAR2(256) NOT NULL,
	sheet_id						NUMBER(10) NOT NULL,
	sheet_url						VARCHAR2(400) NOT NULL,
	deleg_assigned_to				VARCHAR2(1024),
	delegation_name					VARCHAR2(1023),
	delegation_interval				VARCHAR2(32),
	delegation_sid					NUMBER(10) NOT NULL,
	submission_dtm					DATE NOT NULL,
	reminder_dtm					DATE NOT NULL,
	start_dtm						DATE NOT NULL,
	end_dtm							DATE NOT NULL
) ON COMMIT DELETE ROWS;

CREATE INDEX CSR.IX_TEMP_ALERT_BATCH_DETAILS ON CSR.TEMP_ALERT_BATCH_DETAILS (app_sid, csr_user_sid);

@..\sheet_body

@update_tail
