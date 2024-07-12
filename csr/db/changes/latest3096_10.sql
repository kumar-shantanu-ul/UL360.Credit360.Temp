-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
grant execute on chain.setup_pkg to web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***
	
-- *** Packages ***
@../batch_job_pkg
@../batch_job_body

@update_tail
