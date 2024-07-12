-- Please update version.sql too -- this keeps clean builds in sync
define version=3210
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.USER_PROFILE_STAGED_RECORD_LOG (
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRIMARY_KEY						VARCHAR2(128) NOT NULL,
	LAST_INSTANCE_STEP_ID			NUMBER(10),
	ACTION_DTM						DATE,
	ACTION_USER_SID					NUMBER(10),
	ACTION_DESCRIPTION				VARCHAR(256)
)
;


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
@../user_profile_pkg
@../user_profile_body

@update_tail
