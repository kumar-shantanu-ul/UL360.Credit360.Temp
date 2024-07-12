-- Please update version.sql too -- this keeps clean builds in sync
define version=2970
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSRIMP.EMISSION_FACTOR_PROFILE DROP COLUMN ACTIVE;

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
@../schema_body
@../csrimp/imp_body


@update_tail
