-- Please update version.sql too -- this keeps clean builds in sync
define version=3018
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter index CSR.UX_BATCH_JOB_ONE_AT_A_TIME rename to UX_BATCH_JOB_IN_ORDER;


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

@update_tail
