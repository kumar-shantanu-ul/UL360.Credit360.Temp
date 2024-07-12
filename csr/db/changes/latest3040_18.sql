-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.compliance_options
ADD (rollout_option NUMBER(10) DEFAULT 0 NOT NULL);

ALTER TABLE csrimp.compliance_options
ADD (rollout_option NUMBER(10) NOT NULL);

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
@@..\compliance_pkg
@@..\compliance_body

@update_tail
