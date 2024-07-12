-- Please update version.sql too -- this keeps clean builds in sync
define version=2935
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
update dyntab.schema_column set ext_helper_prog_id=regexp_replace(ext_helper_prog_id, '^CSRDynTab\.', 'DynamicTables.')
where ext_helper_prog_id is not null;
commit;

-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
