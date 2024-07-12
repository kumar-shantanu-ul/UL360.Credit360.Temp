-- Please update version.sql too -- this keeps clean builds in sync
define version=3391
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT EXECUTE ON csr.dataview_pkg TO TOOL_USER;
GRANT EXECUTE ON csr.region_pkg TO TOOL_USER;
GRANT EXECUTE ON csr.img_chart_pkg TO TOOL_USER;
GRANT EXECUTE ON csr.templated_report_pkg TO TOOL_USER;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../img_chart_pkg
@../templated_report_pkg
@../enable_body
@../img_chart_body
@../sustain_essentials_body
@../templated_report_body

@update_tail
