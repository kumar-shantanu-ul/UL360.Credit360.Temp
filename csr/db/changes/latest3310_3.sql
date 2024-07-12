-- Please update version.sql too -- this keeps clean builds in sync
define version=3310
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer
ADD (
	marked_for_zap NUMBER(1) DEFAULT 0 NOT NULL,
	zap_after_dtm DATE,
	batch_jobs_disabled NUMBER(1) DEFAULT 0 NOT NULL,
	calc_jobs_disabled NUMBER(1) DEFAULT 0 NOT NULL,
	scheduled_tasks_disabled NUMBER(1) DEFAULT 0 NOT NULL,
	alerts_disabled NUMBER(1) DEFAULT 0 NOT NULL,
	prevent_logon NUMBER(1) DEFAULT 0 NOT NULL
);

ALTER TABLE csr.customer
ADD (
	CONSTRAINT CK_ALLOW_MARKED_FOR_ZAP CHECK (MARKED_FOR_ZAP IN (0,1)),
	CONSTRAINT CK_ALLOW_BATCH_JOBS_DISABLED CHECK (BATCH_JOBS_DISABLED IN (0,1)),
	CONSTRAINT CK_ALLOW_CALC_JOBS_DISABLED CHECK (CALC_JOBS_DISABLED IN (0,1)),
	CONSTRAINT CK_ALLOW_SCHEDULED_TASKS_DISABLED CHECK (SCHEDULED_TASKS_DISABLED IN (0,1)),
	CONSTRAINT CK_ALLOW_ALERTS_DISABLED CHECK (ALERTS_DISABLED IN (0,1)),
	CONSTRAINT CK_ALLOW_PREVENT_LOGON CHECK (PREVENT_LOGON IN (0,1))
);

ALTER TABLE csrimp.customer
ADD (
	marked_for_zap NUMBER(1) DEFAULT 0 NOT NULL,
	zap_after_dtm DATE,
	batch_jobs_disabled NUMBER(1) DEFAULT 0 NOT NULL,
	calc_jobs_disabled NUMBER(1) DEFAULT 0 NOT NULL,
	scheduled_tasks_disabled NUMBER(1) DEFAULT 0 NOT NULL,
	alerts_disabled NUMBER(1) DEFAULT 0 NOT NULL,
	prevent_logon NUMBER(1) DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.customer
ADD (
	CONSTRAINT CK_ALLOW_MARKED_FOR_ZAP CHECK (MARKED_FOR_ZAP IN (0,1)),
	CONSTRAINT CK_ALLOW_BATCH_JOBS_DISABLED CHECK (BATCH_JOBS_DISABLED IN (0,1)),
	CONSTRAINT CK_ALLOW_CALC_JOBS_DISABLED CHECK (CALC_JOBS_DISABLED IN (0,1)),
	CONSTRAINT CK_ALLOW_SCHEDULED_TASKS_DISABLED CHECK (SCHEDULED_TASKS_DISABLED IN (0,1)),
	CONSTRAINT CK_ALLOW_ALERTS_DISABLED CHECK (ALERTS_DISABLED IN (0,1)),
	CONSTRAINT CK_ALLOW_PREVENT_LOGON CHECK (PREVENT_LOGON IN (0,1))
);

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
@../customer_pkg
@../customer_body
@../batch_job_body
@../stored_calc_datasource_body
@../schema_body
@../csrimp/imp_body

@update_tail
