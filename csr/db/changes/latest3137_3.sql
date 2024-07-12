-- Please update version.sql too -- this keeps clean builds in sync
define version=3137
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

-- ** New package grants **

grant execute on csr.like_for_like_pkg to web_user;

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
