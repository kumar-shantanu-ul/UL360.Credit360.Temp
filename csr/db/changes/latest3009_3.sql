-- Please update version.sql too -- this keeps clean builds in sync
define version=3009
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.batch_job_type
   SET one_at_a_time = 1
 WHERE batch_job_type_id = 27;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
