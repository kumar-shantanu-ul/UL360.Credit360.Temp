-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=39
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
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.NEXTVAL, 21, 'Permit actions tab', '/csr/site/compliance/controls/PermitActionsTab.js', 'Credit360.Compliance.Controls.PermitActionsTab', 'Credit360.Compliance.Plugins.PermitActionsTab', 'Shows permit actions.');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../permit_pkg

@../compliance_setup_body
@../enable_body
@../issue_report_body
@../permit_body
@../permit_report_body

@update_tail
