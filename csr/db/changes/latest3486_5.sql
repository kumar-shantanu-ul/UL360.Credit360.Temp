-- Please update version.sql too -- this keeps clean builds in sync
define version=3486
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSRIMP.user_table ADD (
	JAVA_LOGIN_PASSWORD		 VARCHAR(1024),
	JAVA_AUTH_ENABLED		 NUMBER(1) DEFAULT 0 CHECK (JAVA_AUTH_ENABLED IN (0,1))
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
@../schema_body
@../csrimp/imp_body

@update_tail
