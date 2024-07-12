-- Please update version.sql too -- this keeps clean builds in sync
define version=3009
define minor_version=30
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
values (csr.plugin_id_seq.nextval, 13, 'Actions', '/csr/site/audit/controls/ActionsTab.js', 'Audit.Controls.ActionsTab', 'Credit360.Audit.Plugins.ActionsTab', 'This tab shows a list of actions from findings against an audit', '', '');

-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_report_pkg
@../audit_report_body
@../chain/activity_report_pkg
@../chain/activity_report_body
@../chain/company_filter_pkg
@../chain/company_filter_body
@../chain/filter_pkg
@../chain/filter_body
@../comp_regulation_report_pkg
@../comp_regulation_report_body
@../comp_requirement_report_pkg
@../comp_requirement_report_body
@../initiative_report_pkg
@../initiative_report_body
@../issue_report_pkg
@../issue_report_body
@../meter_list_pkg
@../meter_list_body
@../meter_report_pkg
@../meter_report_body
@../non_compliance_report_pkg
@../non_compliance_report_body
@../property_pkg
@../property_body
@../property_report_pkg
@../property_report_body
@../region_report_pkg
@../region_report_body
@../supplier_pkg
@../supplier_body
@../user_report_pkg
@../user_report_body

@update_tail
