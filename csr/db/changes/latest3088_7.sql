-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=7
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
@../period_span_pattern_pkg
@../automated_export_pkg

@../period_span_pattern_body
@../automated_export_body
@update_tail
