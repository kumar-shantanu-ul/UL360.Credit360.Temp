-- Please update version.sql too -- this keeps clean builds in sync
define version=3489
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
BEGIN
	FOR r IN (
		SELECT il.issue_id, ial.issue_action_log_id
		  FROM csr.issue_action_log ial
		  JOIN csr.issue_log il ON ial.issue_log_id = il.issue_log_id
		 WHERE il.issue_id <> ial.issue_id
	)
	LOOP
		UPDATE csr.issue_action_log
		   SET issue_id = r.issue_id
		 WHERE issue_action_log_id = r.issue_action_log_id;
	END LOOP;
END;
/

ALTER TABLE CSR.ISSUE_LOG ADD CONSTRAINT UK_ISSUE_LOG_ISSUE UNIQUE (APP_SID, ISSUE_LOG_ID, ISSUE_ID);

CREATE INDEX csr.ix_issue_action__issue_log_id_ on csr.issue_action_log (app_sid, issue_log_id, issue_id);

ALTER TABLE CSR.ISSUE_ACTION_LOG ADD CONSTRAINT FK_ILI_IALI
	FOREIGN KEY (APP_SID, ISSUE_LOG_ID, ISSUE_ID)
	REFERENCES CSR.ISSUE_LOG(APP_SID, ISSUE_LOG_ID, ISSUE_ID);

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

@update_tail
