-- Please update version.sql too -- this keeps clean builds in sync
define version=3233
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- convert the existing table into archive
ALTER TABLE CSR.FLOW_ITEM_GENERATED_ALERT RENAME TO FLOW_ITEM_GEN_ALERT_ARCHIVE;

EXEC security.user_pkg.logonadmin;

-- create a new table containing only the rows we want to keep
CREATE TABLE CSR.FLOW_ITEM_GEN_ALERT_TEMP
AS (
	SELECT *
	  FROM CSR.FLOW_ITEM_GEN_ALERT_ARCHIVE
	 WHERE processed_dtm IS NULL OR created_dtm > SYSDATE - 15
);

GRANT SELECT, INSERT, DELETE, UPDATE ON CSR.FLOW_ITEM_GEN_ALERT_TEMP TO CAMPAIGNS;
GRANT SELECT, INSERT ON CSR.FLOW_ITEM_GEN_ALERT_TEMP TO CHAIN;
GRANT SELECT, INSERT, DELETE, UPDATE ON CSR.FLOW_ITEM_GEN_ALERT_TEMP TO CMS;
GRANT INSERT ON CSR.FLOW_ITEM_GEN_ALERT_TEMP TO CSRIMP;

ALTER TABLE CSR.FLOW_ITEM_GEN_ALERT_ARCHIVE DROP CONSTRAINT FK_FL_ITM_GN_ALRT_FROM_USER;
ALTER TABLE CSR.FLOW_ITEM_GEN_ALERT_ARCHIVE DROP CONSTRAINT FK_FL_ITM_GN_ALRT_TO_USER;
ALTER TABLE CSR.FLOW_ITEM_GEN_ALERT_ARCHIVE DROP CONSTRAINT FK_FI_GEN_ALERT_FLOW_ST_LOG;
ALTER TABLE CSR.FLOW_ITEM_GEN_ALERT_ARCHIVE DROP CONSTRAINT FK_FL_ITM_GN_ALRT_TO_COL_SID;
ALTER TABLE CSR.FLOW_ITEM_GEN_ALERT_ARCHIVE DROP CONSTRAINT FK_FL_ITM_GN_ALRT_FL_TR_ALRT;
ALTER TABLE CSR.FLOW_ITEM_GEN_ALERT_ARCHIVE DROP CONSTRAINT UK_FLOW_ITEM_GENERATED_ALERT DROP INDEX;

DROP INDEX CSR.IX_FLOW_ITEM_GEN_TO_USER_SID;
DROP INDEX CSR.IX_FLOW_ITEM_GEN_TO_COL_SID;
DROP INDEX CSR.IX_FLOW_ITEM_GEN_PROC_DTM_FI;
DROP INDEX CSR.IX_FLOW_ITEM_GEN_FROM_USER_SID;
DROP INDEX CSR.IX_FLOW_ITEM_GEN_FLOW_TRANSITI;
DROP INDEX CSR.IX_FI_GEN_ALERT_FLOW_ST_LOG;

ALTER TABLE CSR.FLOW_ITEM_GEN_ALERT_ARCHIVE 
	RENAME CONSTRAINT PK_FLOW_ITEM_GENERATED_ALERT to PK_FLOW_ITEM_GEN_ALERT_ARCHIVE;

ALTER INDEX CSR.PK_FLOW_ITEM_GENERATED_ALERT RENAME to PK_FLOW_ITEM_GEN_ALERT_ARCHIVE;

-- apply constraints and indexes to the new table
ALTER TABLE CSR.FLOW_ITEM_GEN_ALERT_TEMP ADD CONSTRAINT PK_FLOW_ITEM_GENERATED_ALERT PRIMARY KEY (APP_SID, FLOW_ITEM_GENERATED_ALERT_ID);
ALTER TABLE CSR.FLOW_ITEM_GEN_ALERT_TEMP ADD CONSTRAINT UK_FLOW_ITEM_GENERATED_ALERT UNIQUE (APP_SID, FLOW_TRANSITION_ALERT_ID, FROM_USER_SID, TO_USER_SID, TO_COLUMN_SID, FLOW_STATE_LOG_ID);

CREATE INDEX CSR.IX_FLOW_ITEM_GEN_PROC_DTM_FI ON CSR.FLOW_ITEM_GEN_ALERT_TEMP(APP_SID, PROCESSED_DTM, FLOW_ITEM_ID)
;

CREATE INDEX CSR.IX_FLOW_ITEM_GEN_TO_COL_SID ON CSR.FLOW_ITEM_GEN_ALERT_TEMP(APP_SID, TO_COLUMN_SID)
;

CREATE INDEX CSR.IX_FI_GEN_ALERT_FLOW_ST_LOG ON CSR.FLOW_ITEM_GEN_ALERT_TEMP(APP_SID, FLOW_STATE_LOG_ID, FLOW_ITEM_ID);
CREATE INDEX CSR.IX_FLOW_ITEM_GEN_TO_USER_SID ON CSR.FLOW_ITEM_GEN_ALERT_TEMP (APP_SID, TO_USER_SID);
CREATE INDEX CSR.IX_FLOW_ITEM_GEN_FLOW_TRANSITI ON CSR.FLOW_ITEM_GEN_ALERT_TEMP (APP_SID, FLOW_TRANSITION_ALERT_ID);
CREATE INDEX CSR.IX_FLOW_ITEM_GEN_FROM_USER_SID ON CSR.FLOW_ITEM_GEN_ALERT_TEMP (APP_SID, FROM_USER_SID);

ALTER TABLE CSR.FLOW_ITEM_GEN_ALERT_TEMP ADD CONSTRAINT FK_FI_GEN_ALERT_FLOW_ST_LOG
    FOREIGN KEY (APP_SID, FLOW_STATE_LOG_ID, FLOW_ITEM_ID)
    REFERENCES CSR.FLOW_STATE_LOG(APP_SID, FLOW_STATE_LOG_ID, FLOW_ITEM_ID)
;

ALTER TABLE CSR.FLOW_ITEM_GEN_ALERT_TEMP ADD CONSTRAINT FK_FL_ITM_GN_ALRT_FL_TR_ALRT
    FOREIGN KEY (APP_SID, FLOW_TRANSITION_ALERT_ID)
    REFERENCES CSR.FLOW_TRANSITION_ALERT(APP_SID, FLOW_TRANSITION_ALERT_ID)
;

ALTER TABLE CSR.FLOW_ITEM_GEN_ALERT_TEMP ADD CONSTRAINT FK_FL_ITM_GN_ALRT_FROM_USER
    FOREIGN KEY (APP_SID, FROM_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.FLOW_ITEM_GEN_ALERT_TEMP ADD CONSTRAINT FK_FL_ITM_GN_ALRT_TO_USER
    FOREIGN KEY (APP_SID, TO_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.FLOW_ITEM_GEN_ALERT_TEMP
	ADD CONSTRAINT FK_FL_ITM_GN_ALRT_TO_COL_SID FOREIGN KEY (app_sid, to_column_sid) 
	REFERENCES cms.tab_column(app_sid, column_sid);

-- rename temp to actual table name
ALTER TABLE CSR.FLOW_ITEM_GEN_ALERT_TEMP RENAME TO FLOW_ITEM_GENERATED_ALERT;

-- the following delete takes 1-2 mins in devdb 
BEGIN
	DELETE FROM csr.flow_item_gen_alert_archive
	 WHERE (app_sid, flow_item_generated_alert_id) IN (
		 SELECT app_sid, flow_item_generated_alert_id
		   FROM csr.flow_item_generated_alert
	 );
END;
/

BEGIN
	dbms_scheduler.create_job (
		job_name		=> 'CSR.ARCHIVE_OLD_FL_IT_GEN_ALER',
		job_type		=> 'PLSQL_BLOCK',
		job_action		=> 'csr.flow_pkg.ArchiveOldFlowItemGenEntries;',
		job_class		=> 'low_priority_job',
		start_date		=> to_timestamp_tz('2019/03/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval	=> 'FREQ=DAILY;INTERVAL=1;BYDAY=SAT;', --every Saturday midnight
		enabled			=> TRUE,
		auto_drop		=> FALSE,
		comments		=> 'Archive processed flow item alert entries'
	);
END;
/

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../flow_pkg
@../flow_body
@../csr_app_body

@update_tail
