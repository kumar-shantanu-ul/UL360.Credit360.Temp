grant select, references on csr.csr_user to actions;
grant select on csr.dataview_ind_member to actions;
grant select, update, references on csr.ind to actions;
grant select, references on csr.measure to actions;
grant select, references on csr.measure_conversion to actions;
grant select, references on csr.region to actions;
grant select, references on csr.dataview to actions;
grant select, references on csr.factor_type to actions;
grant select, references on csr.measure to actions;
grant select, references on csr.measure_conversion to actions;
grant select on csr.user_measure_conversion to actions;
grant select, references on csr.customer to actions;
grant select, references, insert, delete on csr.calc_dependency to actions;
grant select, references, update, delete on csr.val to actions;
grant select, references, delete on csr.val_change to actions;
grant select, references on csr.ind_tag to actions;
grant select, references on csr.search_tag to actions;
grant select, references on csr.role to actions;
grant select, references on csr.region_role_member to actions;
grant select, references on csr.region_owner to actions;
grant select on csr.region_start_point to actions;
grant select, references on csr.region_tree to actions;
grant select, update, references on csr.issue to actions;
grant select, insert, delete, references on csr.issue_action to actions;
grant select on csr.issue_action_id_seq to actions;
grant select, references on csr.std_alert_type to actions;
grant select, references on csr.temp_alert_batch_run to actions;
grant select on csr.gas_type to actions;
grant select on csr.ind_description to actions;

grant select, update, references on csr.scenario to actions;
grant select, update, references on csr.scenario_rule to actions;
grant select, update, insert, delete, references on csr.scenario_auto_run_request to actions;

grant select, references on aspen2.filecache to actions;

grant select on security.securable_object to actions;
grant select on security.user_table to actions;
grant select on security.group_members to actions;
grant select on security.application to actions;
grant select, references on security.website to actions;


grant select, insert, update, delete, references on actions.PROJECT_REGION_ROLE_MEMBER to csr;
grant select, references on actions.TASK_TAG to csr;
grant select, delete on actions.TASK_STATUS_ROLE to csr;
grant select, delete on actions.TASK_STATUS_TRANSITION to csr;
grant select, delete on actions.ALLOW_TRANSITION to csr;
grant select, delete, references on actions.TASK_PERIOD to csr;
grant select, delete, references on actions.TASK_PERIOD_STATUS to csr;
grant select, delete, references on actions.task_recalc_region to csr;
grant select, delete, references on actions.aggr_task_period_override to csr;
grant select, delete, references on actions.aggr_task_period to csr;
grant select, delete, references on actions.task_period_override to csr;
grant select, delete, references on actions.task_period_file_upload to csr;
grant select, delete, references on actions.task_region to csr;
