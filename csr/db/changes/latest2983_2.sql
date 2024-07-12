-- Please update version.sql too -- this keeps clean builds in sync
define version=2983
define minor_version=2
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

-- recompile them if they exist; skip them if they don't

UNDEFINE ex_if
COLUMN ex_if NEW_VALUE ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\supplier\greenTick\gt_food_body' END AS ex_if FROM all_objects WHERE owner = 'SUPPLIER' AND object_type = 'PACKAGE' AND object_name = 'GT_FOOD_PKG';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\supplier\greenTick\gt_packaging_body' END AS ex_if FROM all_objects WHERE owner = 'SUPPLIER' AND object_type = 'PACKAGE' AND object_name = 'GT_PACKAGING_PKG';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\supplier\greenTick\gt_transport_body' END AS ex_if FROM all_objects WHERE owner = 'SUPPLIER' AND object_type = 'PACKAGE' AND object_name = 'GT_TRANSPORT_PKG';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\supplier\greenTick\model_body' END AS ex_if FROM all_objects WHERE owner = 'SUPPLIER' AND object_type = 'PACKAGE' AND object_name = 'MODEL_PKG';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\supplier\greenTick\model_pd_body' END AS ex_if FROM all_objects WHERE owner = 'SUPPLIER' AND object_type = 'PACKAGE' AND object_name = 'MODEL_PD_PKG';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\supplier\greenTick\product_info_body' END AS ex_if FROM all_objects WHERE owner = 'SUPPLIER' AND object_type = 'PACKAGE' AND object_name = 'PRODUCT_INFO_PKG';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\supplier\greenTick\revision_body' END AS ex_if FROM all_objects WHERE owner = 'SUPPLIER' AND object_type = 'PACKAGE' AND object_name = 'REVISION_PKG';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\supplier\wood\part_wood_body' END AS ex_if FROM all_objects WHERE owner = 'SUPPLIER' AND object_type = 'PACKAGE' AND object_name = 'PART_WOOD_PKG';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\company_user_body' END AS ex_if FROM all_objects WHERE owner = 'ETHICS' AND object_type = 'PACKAGE' AND object_name = 'COMPANY_USER_PKG';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\course_body' END AS ex_if FROM all_objects WHERE owner = 'ETHICS' AND object_type = 'PACKAGE' AND object_name = 'COURSE_PKG';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\demo_body' END AS ex_if FROM all_objects WHERE owner = 'ETHICS' AND object_type = 'PACKAGE' AND object_name = 'DEMO_PKG';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\ethics_body' END AS ex_if FROM all_objects WHERE owner = 'ETHICS' AND object_type = 'PACKAGE' AND object_name = 'ETHICS_PKG';
@&ex_if

UNDEFINE ex_if

-- *** Packages ***
@..\..\..\aspen2\cms\db\calc_xml_body
@..\..\..\aspen2\cms\db\filter_body
@..\..\..\aspen2\cms\db\form_body
@..\..\..\aspen2\cms\db\menu_body
@..\..\..\aspen2\cms\db\tab_body
@..\..\..\aspen2\cms\db\util_body
@..\..\..\aspen2\db\fp_user_body
@..\..\..\aspen2\db\job_body
@..\..\..\aspen2\db\number_to_string
@..\..\..\aspen2\db\trash_body
@..\..\..\aspen2\db\tree_body
@..\..\..\aspen2\DynamicTables\db\fulltext_index_body
@..\..\..\aspen2\DynamicTables\db\schema_body

@..\actions\file_upload_body
@..\actions\gantt_body
@..\actions\ind_template_body
@..\actions\initiative_body
@..\actions\project_body
@..\actions\reckoner_body
@..\actions\setup_body
@..\actions\task_body

@..\aggregate_ind_body
@..\approval_dashboard_body
@..\audit_pkg
@..\audit_body
@..\auto_approve_body

-- Not on live, so skipping recompilation
-- @..\backup_body

@..\calc_body
@..\calendar_body
@..\comp_regulation_report_body
@..\comp_requirement_report_body
@..\compliance_body
@..\csr_user_body
@..\deleg_plan_body
@..\delegation_body
@..\diary_body
@..\doc_body
@..\doc_folder_body
@..\enable_body
@..\energy_star_attr_body
@..\energy_star_body
@..\energy_star_job_body
@..\enhesa_body
@..\fileupload_body
@..\flow_body
@..\form_body
@..\geo_map_body
@..\image_upload_portlet_pkg
@..\image_upload_portlet_body
@..\img_chart_body
@..\imp_body
@..\indicator_pkg
@..\indicator_body
@..\initiative_aggr_body
@..\initiative_body
@..\initiative_export_body
@..\initiative_report_body
@..\issue_body
@..\job_body
@..\like_for_like_body
@..\logistics_body
@..\measure_body
@..\meter_alarm_stat_body
@..\meter_body
@..\meter_list_body
@..\meter_monitor_body
@..\meter_patch_body
@..\meter_report_body
@..\model_body
@..\non_compliance_report_body
@..\pending_body
@..\portlet_body
@..\postit_body
@..\property_body
@..\quick_survey_body
@..\recurrence_pattern_body
@..\region_body
@..\region_set_body
@..\region_tree_body
@..\role_body
@..\rss_body
@..\ruleset_body
@..\scenario_body
@..\scenario_run_body
@..\schema_body
@..\section_body
@..\section_root_body
@..\section_search_body
@..\sheet_body
@..\stored_calc_datasource_body
@..\strategy_body
@..\supplier_body
@..\tag_body
@..\templated_report_body
@..\training_body
@..\training_flow_helper_body
@..\tree_body

-- only run locally not on live?
@..\unit_test_body

@..\user_report_body
@..\util_script_body
@..\utility_body
@..\val_body

@..\chain\bsci_body
@..\chain\capability_body
@..\chain\company_body
@..\chain\company_dedupe_body
@..\chain\company_filter_body
@..\chain\company_user_body

-- only run locally not on live?
@..\chain\dev_body

@..\chain\filter_body
@..\chain\flow_form_body
@..\chain\higg_body
@..\chain\higg_setup_body
@..\chain\invitation_body
@..\chain\metric_body
@..\chain\newsflash_body
@..\chain\product_body
@..\chain\purchased_component_body
@..\chain\questionnaire_body
@..\chain\report_body
@..\chain\scheduled_alert_body
@..\chain\setup_body
@..\chain\type_capability_body
@..\chain\upload_body
@..\chain\validated_purch_component_body

@..\chem\substance_body

@..\csrimp\imp_body

@..\ct\admin_body
@..\ct\consumption_body
@..\ct\link_body
@..\ct\setup_body
@..\ct\util_body
@..\ct\value_chain_report_body

@..\donations\budget_body
@..\donations\fields_body
@..\donations\funding_commitment_body
@..\donations\transition_body

@..\supplier\company_body
@..\supplier\product_body
@..\supplier\questionnaire_body
@..\supplier\supplier_user_body

@..\supplier\chain\chain_company_body
@..\supplier\chain\company_user_body
@..\supplier\chain\invite_body

@update_tail
