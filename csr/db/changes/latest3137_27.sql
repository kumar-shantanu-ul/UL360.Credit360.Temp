-- Please update version.sql too -- this keeps clean builds in sync
define version=3137
define minor_version=27
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
create index surveys.ix_audit_detail_audit on surveys.audit_log_detail (app_sid, audit_log_id);

ALTER TABLE SURVEYS.AUDIT_LOG_DETAIL DROP CONSTRAINT FK_AUDIT_DETAIL_AUDIT;

ALTER TABLE SURVEYS.AUDIT_LOG_DETAIL ADD CONSTRAINT FK_AUDIT_DETAIL_AUDIT
	FOREIGN KEY (APP_SID, AUDIT_LOG_ID)
	REFERENCES SURVEYS.AUDIT_LOG(APP_SID, AUDIT_LOG_ID);

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
