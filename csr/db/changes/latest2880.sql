-- Please update version.sql too -- this keeps clean builds in sync
define version=2880
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

--csr/db/create_views.sql

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../../../aspen2/cms/db/tab_body

@update_tail
