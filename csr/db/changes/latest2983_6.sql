-- Please update version.sql too -- this keeps clean builds in sync
define version=2983
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CHAIN.CUSTOMER_OPTIONS
ADD (
	FORCE_LOGIN_AS_COMPANY			NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_FORCE_LOGIN_AS_CO CHECK (FORCE_LOGIN_AS_COMPANY IN (0,1))
);

ALTER TABLE CSRIMP.CHAIN_CUSTOMER_OPTIONS
ADD (
	FORCE_LOGIN_AS_COMPANY			NUMBER(1) NULL
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

@..\chain\helper_pkg

@..\schema_body
@..\chain\helper_body
@..\csrimp\imp_body

@update_tail
