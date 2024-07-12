-- Please update version.sql too -- this keeps clean builds in sync
define version=3113
define minor_version=0
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

-- *** Conditional Packages ***

-- *** Packages ***
@../calc_body
@../doc_folder_body
@../factor_body
@../scenario_run_snapshot_body
@../sheet_body
@../stored_calc_datasource_body

@update_tail
