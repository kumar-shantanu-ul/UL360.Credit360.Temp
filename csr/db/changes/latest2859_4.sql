-- Please update version.sql too -- this keeps clean builds in sync
define version=2859
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- @..\chain\create_views.sql
@latest2859_4_views_chain

-- @..\supplier\greenTick\create_views.sql
@latest2859_4_views_suppliergreentick

-- *** Data changes ***
-- RLS

-- Data
DELETE FROM csr.branding_availability
 WHERE client_folder_name = 'halcrow';

DELETE FROM csr.branding
 WHERE client_folder_name = 'halcrow';

-- ** New package grants **

-- *** Packages ***

BEGIN
	EXECUTE IMMEDIATE 'DROP PACKAGE csr.gas_pkg';
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/

BEGIN
	EXECUTE IMMEDIATE 'DROP PACKAGE csr.hsbc_pkg';
EXCEPTION
	WHEN OTHERS THEN
		NULL; -- will not exist for on-site installs, for example, because it gets stripped
END;
/

@..\..\..\aspen2\db\filecache_body
@..\..\..\aspen2\db\form_transaction_body
@..\..\..\aspen2\db\fp_user_body
@..\..\..\aspen2\db\mdComment_body
@..\..\..\aspen2\db\supportTicket_body
@..\..\..\aspen2\db\trash_body
@..\..\..\aspen2\db\utils_body
@..\..\..\aspen2\cms\db\calc_xml_body
@..\..\..\aspen2\cms\db\col_link_body
@..\..\..\aspen2\cms\db\form_body
@..\..\..\aspen2\cms\db\image_body
@..\..\..\aspen2\cms\db\imp_body
@..\..\..\aspen2\cms\db\menu_body
@..\..\..\aspen2\cms\db\tab_body
@..\..\..\aspen2\cms\db\upload_body
@..\..\..\aspen2\cms\db\web_publication_body
@..\..\..\aspen2\DynamicTables\db\schema_pkg
@..\..\..\aspen2\DynamicTables\db\schema_body
@..\accuracy_pkg
@..\accuracy_body
@..\activity_pkg
@..\activity_body
@..\aggregate_ind_body
@..\alert_pkg
@..\alert_body
@..\approval_dashboard_pkg
@..\approval_dashboard_body
@..\approval_step_range_body
@..\audit_pkg
@..\audit_body
@..\auto_approve_pkg
@..\auto_approve_body
@..\automated_import_body
@..\branding_body
@..\calc_pkg
@..\calc_body
@..\calendar_pkg
@..\calendar_body
@..\campaign_body
@..\csr_app_body
@..\csr_data_pkg
@..\csr_data_body
@..\csr_user_pkg
@..\csr_user_body
@..\dataview_pkg
@..\dataview_body
@..\delegation_pkg
@..\delegation_body
@..\deleg_plan_pkg
@..\deleg_plan_body
@..\doc_body
@..\doc_helper_body
@..\donations\donation_body
@..\doc_lib_body
@..\enable_body
@..\energy_star_pkg
@..\energy_star_body
@..\energy_star_job_body
@..\enhesa_body
@..\excel_pkg
@..\excel_body
@..\export_feed_pkg
@..\export_feed_body
@..\factor_pkg
@..\factor_body
@..\fileupload_body
@..\flow_pkg
@..\flow_body
@..\help_pkg
@..\help_body
@..\help_image_body
@..\img_chart_body
@..\imp_pkg
@..\imp_body
@..\import_feed_pkg
@..\import_feed_body
@..\indicator_pkg
@..\indicator_body
@..\indicator_set_body
@..\initiative_pkg
@..\initiative_body
@..\initiative_doc_pkg
@..\initiative_doc_body
@..\issue_body
@..\logistics_pkg
@..\logistics_body
@..\measure_body
@..\meter_body
@..\meter_monitor_body
@..\metric_dashboard_pkg
@..\metric_dashboard_body
@..\model_pkg
@..\model_body
@..\pending_body
@..\pending_datasource_body
@..\plugin_body
@..\portal_dashboard_pkg
@..\portal_dashboard_body
@..\portlet_body
@..\property_body
@..\quick_survey_body
@..\region_body
@..\region_metric_body
@..\role_body
@..\scenario_body
@..\scenario_run_body
@..\section_pkg
@..\section_body
@..\section_root_body
@..\section_search_pkg
@..\section_search_body
@..\section_status_pkg
@..\section_status_body
@..\section_transition_pkg
@..\section_transition_body
@..\session_extra_body
@..\sheet_pkg
@..\sheet_body
@..\snapshot_body
@..\structure_import_body
@..\sqlreport_pkg
@..\sqlreport_body
@..\supplier_body
@..\tag_body
@..\teamroom_body
@..\templated_report_pkg
@..\templated_report_body
@..\training_pkg
@..\training_body
@..\unit_test_body
@..\user_cover_body
@..\user_setting_body
@..\val_datasource_pkg
@..\val_datasource_body
@..\vb_legacy_pkg
@..\vb_legacy_body
@..\actions\aggr_dependency_body
@..\actions\dependency_body
@..\actions\ind_template_body
@..\actions\setup_body
@..\actions\task_body
@..\chain\admin_helper_body
@..\chain\activity_body
@..\chain\alert_helper_body
@..\chain\audit_request_body
@..\chain\capability_body
@..\chain\card_body
@..\chain\company_body
@..\chain\company_user_body
@..\chain\company_type_body
@..\chain\component_body
@..\chain\dev_body
@..\chain\filter_body
@..\chain\helper_body
@..\chain\invitation_body
@..\chain\newsflash_body
@..\chain\plugin_body
@..\chain\product_body
@..\chain\purchased_component_body
@..\chain\questionnaire_body
@..\chain\scheduled_alert_body
@..\chain\setup_body
@..\chain\supplier_audit_body
@..\chain\task_body
@..\chain\type_capability_body
@..\chain\uninvited_body
@..\chain\upload_body
@..\chem\substance_pkg
@..\chem\substance_body
@..\ct\hotspot_body
@..\ct\setup_body
@..\ct\value_chain_report_body
@..\donations\funding_commitment_body
@..\donations\tag_pkg
@..\donations\tag_body
@..\donations\helpers\bae_helper_body
@..\donations\transition_body
@..\supplier\audit_body
@..\supplier\company_body
@..\supplier\chain\chain_questionnaire_body
@..\supplier\chain\company_group_body
@..\supplier\chain\company_user_body
@..\supplier\chain\contact_body
@..\supplier\chain\invite_body
@..\supplier\greenTick\gt_packaging_body
@..\supplier\greenTick\product_info_body
@..\supplier\greenTick\report_gt_body
@..\supplier\greenTick\revision_body
@..\supplier\greenTick\score_log_body
@..\supplier\product_body
@..\supplier\supplier_user_body

-- conditional compilation if the relevant non-client schemas exist
UNDEFINE ex_if
COLUMN ex_if NEW_VALUE ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\..\..\aspen2\WebFerret\db\WebFerret_pkg' END AS ex_if FROM all_users WHERE username = 'WEBFERRET';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\..\..\aspen2\WebFerret\db\WebFerret_body' END AS ex_if FROM all_users WHERE username = 'WEBFERRET';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\company_user_body' END AS ex_if FROM all_users WHERE username = 'ETHICS';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\demo_body' END AS ex_if FROM all_users WHERE username = 'ETHICS';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\participant_pkg' END AS ex_if FROM all_users WHERE username = 'ETHICS';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\participant_body' END AS ex_if FROM all_users WHERE username = 'ETHICS';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\question_body' END AS ex_if FROM all_users WHERE username = 'ETHICS';
@&ex_if

UNDEFINE ex_if

@update_tail
