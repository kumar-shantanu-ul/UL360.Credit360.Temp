-- Please update version.sql too -- this keeps clean builds in sync
define version=2917
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
grant delete on csr.approval_dashboard_tpl_tag to cms;
grant delete on csr.tpl_report_tag to cms;
grant delete on csr.tpl_report_tag_logging_form to cms;

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
@../../../aspen2/cms/db/tab_body
@../csr_app_body
@../chain/chain_body

@update_tail
