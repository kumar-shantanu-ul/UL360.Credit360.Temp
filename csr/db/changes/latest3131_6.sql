-- Please update version.sql too -- this keeps clean builds in sync
define version=3131
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

GRANT SELECT, INSERT, UPDATE, DELETE ON csr.flow_alert_class TO chain;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO cms.col_type (col_type, description) VALUES (41, 'Flow company');
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\supplier_pkg
@..\supplier_body

@..\..\..\aspen2\cms\db\tab_pkg
@..\..\..\aspen2\cms\db\tab_body
@..\..\..\aspen2\cms\db\cms_tab_body
@..\..\..\aspen2\cms\db\filter_body

@..\flow_pkg
@..\flow_body

@..\chain\company_dedupe_body

@update_tail
