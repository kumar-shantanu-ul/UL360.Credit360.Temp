-- Please update version.sql too -- this keeps clean builds in sync
define version=2882
define minor_version=1
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

UNDEFINE ex_if
COLUMN ex_if NEW_VALUE ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\course_body' END AS ex_if FROM all_users WHERE username = 'ETHICS';
@&ex_if

UNDEFINE ex_if

-- *** Packages ***

@..\..\..\aspen2\db\tree_body
@..\..\..\aspen2\cms\db\pivot_body
@..\..\..\aspen2\DynamicTables\db\schema_body
@..\actions\gantt_pkg
@..\actions\gantt_body
@..\actions\initiative_body
@..\actions\importer_body
@..\actions\periodic_alert_body
@..\actions\task_body
@..\chain\setup_body
@..\chain\type_capability_body
@..\chem\substance_body
@..\supplier\company_pkg
@..\supplier\company_body
@..\supplier\chain\message_body
@..\csrimp\imp_body
@..\csr_data_pkg
@..\doc_body
@..\enable_body
@..\energy_star_job_body
@..\initiative_aggr_body
@..\initiative_doc_body
@..\issue_pkg
@..\initiative_alert_body
@..\initiative_body
@..\issue_body
@..\meter_alarm_body
@..\meter_monitor_pkg
@..\meter_monitor_body
@..\meter_patch_body
@..\meter_report_body
@..\region_pkg
@..\region_body
@..\region_tree_pkg
@..\region_tree_body
@..\ruleset_body
@..\sheet_body
@..\stored_calc_datasource_body
@..\teamroom_body
@..\templated_report_pkg
@..\templated_report_body
@..\templated_report_schedule_body
@..\user_cover_body

@update_tail
