-- Please update version.sql too -- this keeps clean builds in sync
define version=2859
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\actions\project_pkg
@..\actions\project_body
@..\actions\task_pkg
@..\actions\task_body
@..\approval_dashboard_pkg
@..\approval_dashboard_body
@..\audit_pkg
@..\audit_body
@..\automated_export_pkg
@..\automated_export_body
@..\automated_import_pkg
@..\automated_import_body
@..\benchmarking_dashboard_pkg
@..\benchmarking_dashboard_body
@..\calendar_pkg
@..\calendar_body
@..\campaign_pkg
@..\campaign_body
@..\chain\company_pkg
@..\chain\company_body
@..\chain\filter_pkg
@..\chain\filter_body
@..\chain\uninvited_pkg
@..\chain\uninvited_body
@..\chain\upload_pkg
@..\chain\upload_body
@..\portal_dashboard_pkg
@..\csr_app_pkg
@..\csr_app_body
@..\csr_user_pkg
@..\csr_user_body
@..\dashboard_pkg
@..\dashboard_body
@..\dataview_pkg
@..\dataview_body
@..\deleg_plan_pkg
@..\deleg_plan_body
@..\deleg_report_pkg
@..\deleg_report_body
@..\delegation_pkg
@..\delegation_body
@..\diary_pkg
@..\diary_body
@..\doc_folder_pkg
@..\doc_folder_body
@..\doc_lib_pkg
@..\doc_lib_body
@..\donations\funding_commitment_pkg
@..\donations\funding_commitment_body
@..\donations\recipient_pkg
@..\donations\recipient_body
@..\donations\region_group_pkg
@..\donations\region_group_body
@..\donations\scheme_pkg
@..\donations\scheme_body
@..\donations\status_pkg
@..\donations\status_body
@..\donations\tag_pkg
@..\donations\tag_body
@..\donations\transition_pkg
@..\donations\transition_body
@..\export_feed_pkg
@..\export_feed_body
@..\feed_pkg
@..\feed_body
@..\fileupload_pkg
@..\fileupload_body
@..\flow_pkg
@..\flow_body
@..\form_pkg
@..\form_body
@..\geo_map_pkg
@..\geo_map_body
@..\help_pkg
@..\help_body
@..\img_chart_pkg
@..\img_chart_body
@..\imp_pkg
@..\imp_body
@..\import_feed_pkg
@..\import_feed_body
@..\indicator_pkg
@..\indicator_body
@..\initiative_pkg
@..\initiative_body
@..\initiative_project_pkg
@..\initiative_project_body
@..\measure_pkg
@..\measure_body
@..\metric_dashboard_pkg
@..\metric_dashboard_body
@..\model_pkg
@..\model_body
@..\objective_pkg
@..\objective_body
@..\portal_dashboard_pkg
@..\portal_dashboard_body
@..\portlet_pkg
@..\portlet_body
@..\quick_survey_pkg
@..\quick_survey_body
@..\region_pkg
@..\region_body
@..\region_tree_pkg
@..\region_tree_body
@..\reporting_period_pkg
@..\reporting_period_body
@..\role_pkg
@..\role_body
@..\rss_pkg
@..\rss_body
@..\ruleset_pkg
@..\ruleset_body
@..\scenario_pkg
@..\scenario_body
@..\scenario_run_pkg
@..\scenario_run_body
@..\section_pkg
@..\section_body
@..\section_root_pkg
@..\section_root_body
@..\section_status_pkg
@..\section_status_body
@..\section_transition_pkg
@..\section_transition_body
@..\supplier\company_pkg
@..\supplier\company_body
@..\supplier\supplier_user_pkg
@..\supplier\supplier_user_body
@..\supplier\tag_pkg
@..\supplier\tag_body
@..\target_dashboard_pkg
@..\target_dashboard_body
@..\teamroom_pkg
@..\teamroom_body
@..\templated_report_pkg
@..\templated_report_body
@..\templated_report_schedule_pkg
@..\templated_report_schedule_body
@..\trash_pkg
@..\trash_body
@..\user_container_pkg
@..\user_container_body

-- conditional compilation if ethics exists
UNDEFINE ex_if
COLUMN ex_if NEW_VALUE ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\company_pkg' END AS ex_if FROM all_users WHERE username = 'ETHICS';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\company_body' END AS ex_if FROM all_users WHERE username = 'ETHICS';
@&ex_if

UNDEFINE ex_if

@update_tail
