-- Please update version.sql too -- this keeps clean builds in sync
define version=3441
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.BASELINE_CONFIG
DROP CONSTRAINT uk_baseline_lookup_key;

ALTER TABLE csr.BASELINE_CONFIG
ADD CONSTRAINT uk_baseline_lookup_key UNIQUE (APP_SID, BASELINE_LOOKUP_KEY);

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
