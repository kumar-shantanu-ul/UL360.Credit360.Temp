-- Please update version.sql too -- this keeps clean builds in sync
define version=3213
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

CREATE INDEX CSR.SCENARIO_RUN_VAL_AS ON CSR.SCENARIO_RUN_VAL(APP_SID);

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
