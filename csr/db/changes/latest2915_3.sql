-- Please update version.sql too -- this keeps clean builds in sync
define version=2915
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSRIMP.CUSTOMER ADD
(
	ADJ_FACTORSET_STARTMONTH		NUMBER(1)		NOT NULL,
	ALLOW_CUSTOM_ISSUE_TYPES		NUMBER(1, 0)	NOT NULL,
	ALLOW_SECTION_IN_MANY_CARTS		NUMBER(1, 0)	NOT NULL,
	CALC_JOB_NOTIFY_ADDRESS			VARCHAR2(512),
	CALC_JOB_NOTIFY_AFTER_ATTEMPTS	NUMBER(10),
	DEFAULT_COUNTRY					VARCHAR2(2),
	DYNAMIC_DELEG_PLANS_BATCHED		NUMBER(1, 0)	NOT NULL,
	EST_JOB_NOTIFY_ADDRESS			VARCHAR2(512),
	EST_JOB_NOTIFY_AFTER_ATTEMPTS	NUMBER(10),
	FAILED_CALC_JOB_RETRY_DELAY		NUMBER(10, 0)	NOT NULL,
	LEGACY_PERIOD_FORMATTING		NUMBER(1,0),
	LIVE_METERING_SHOW_GAPS			NUMBER(1)		NOT NULL,
	LOCK_PREVENTS_EDITING			NUMBER(1, 0)	NOT NULL,
	MAX_CONCURRENT_CALC_JOBS		NUMBER(10),
	METERING_GAPS_FROM_ACQUISITION	NUMBER(1)		NOT NULL,
	RESTRICT_ISSUE_VISIBILITY		NUMBER(1)		NOT NULL,
	SCRAG_QUEUE						VARCHAR2(100),
	STATUS_FROM_PARENT_ON_SUBDELEG	NUMBER(1, 0)	NOT NULL,
	TRANSLATION_CHECKBOX			NUMBER(1)		NOT NULL,
	USER_ADMIN_HELPER_PKG			VARCHAR2(255),
	USER_DIRECTORY_TYPE_ID			NUMBER(10, 0)	NOT NULL,
	CONSTRAINT CHK_CUSTOMER_ALLOW_CUSTOM_IT CHECK (ALLOW_CUSTOM_ISSUE_TYPES IN (0,1)),
	CONSTRAINT CK_CUSTOMER_DYN_DELEG_PLAN CHECK (DYNAMIC_DELEG_PLANS_BATCHED IN (0,1)),
	CONSTRAINT CK_CUSTOMER_ISSUE_VISIBILITY CHECK (RESTRICT_ISSUE_VISIBILITY IN (0,1))
);

-- point constraint at the right column instead of check_divisibility
ALTER TABLE CSR.CUSTOMER
DROP CONSTRAINT CK_CUSTOMER_ISSUE_VISIBILITY;

ALTER TABLE CSR.CUSTOMER
ADD CONSTRAINT ck_customer_issue_visibility CHECK (restrict_issue_visibility IN (0,1));

ALTER TABLE CSRIMP.DATAVIEW ADD
(
	ANONYMOUS_REGION_NAMES			NUMBER(1)		NOT NULL,
	INCLUDE_NOTES_IN_TABLE			NUMBER(1)		NOT NULL,
	SHOW_REGION_EVENTS				NUMBER(1)		NOT NULL
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\schema_body
@..\csrimp\imp_body

@update_tail
