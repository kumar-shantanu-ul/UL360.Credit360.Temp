-- Please update version.sql too -- this keeps clean builds in sync
define version=3153
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.scenario_api_pkg
AS
END;
/
GRANT EXECUTE ON csr.scenario_api_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@..\scenario_api_pkg

@..\scenario_api_body

@update_tail
