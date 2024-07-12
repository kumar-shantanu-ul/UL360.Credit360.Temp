-- Please update version.sql too -- this keeps clean builds in sync
define version=3409
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE aspen2.application ADD (
	display_cookie_policy NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT ck_display_cookie_policy CHECK (display_cookie_policy IN (0,1,2))
);

UPDATE aspen2.application a
   SET display_cookie_policy = (SELECT display_cookie_policy FROM csr.customer c WHERE c.app_sid = a.app_sid);
   
ALTER TABLE csr.customer DROP COLUMN display_cookie_policy;

ALTER TABLE csrimp.aspen2_application ADD (
	display_cookie_policy NUMBER(1) NULL,
	CONSTRAINT ck_display_cookie_policy CHECK (display_cookie_policy IN (0,1,2))
);

UPDATE csrimp.aspen2_application a
   SET display_cookie_policy = (SELECT display_cookie_policy FROM csrimp.customer c WHERE c.csrimp_session_id = a.csrimp_session_id);

ALTER TABLE csrimp.customer DROP COLUMN display_cookie_policy;

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
@../../../aspen2/db/aspenapp_body

@../customer_body
@../schema_body
@../util_script_body

@../csrimp/imp_body

@update_tail
