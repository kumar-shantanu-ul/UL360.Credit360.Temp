-- Please update version.sql too -- this keeps clean builds in sync
define version=1067
@update_header

declare
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_constraint_name varchar2(30);
	v_table_name varchar2(30);
begin	
	v_list := t_tabs(
		'ACCURACY_TYPE_OPTION','UK_AT_ID_LABEL',
		'CALC_JOB','UK_CALC_JOB',
		'CUSTOM_LOCATION','AK_CUSTOM_LOCATION',
		'DATAVIEW_SCENARIO_RUN','UK_DATAVIEW_SCENARIO_RUN',
		'FLOW_STATE_TRANSITION','UK_FLOW_STATE_TRANSITION',
		'IND_SELECTION_GROUP_MEMBER','UK_IND_SELECTION_GROUP_IND',
		'ISSUE_PENDING_VAL','UK_ISSUE_PENDING_VAL',
		'ISSUE_SHEET_VALUE','UK_ISSUE_SHEET_VALUE',
		'ISSUE_SURVEY_ANSWER','UK_ISSUE_SURVEY_ANSWER',
		'MODEL_RANGE','UK_MODEL_RANGE',
		'PENDING_VAL','U_IND_REGION_PERIOD',
		'PENDING_VAL','UK_PENDING_VAL_IRP',
		'QUICK_SURVEY_EXPR_ACTION','UK_QS_EXPR_ACTION',
		'ROLE','UK_ROLE_LOOKUP_KEY',
		'ROLE','UX_ROLE_LOOKUP_KEY',
		'SHEET_VALUE','UK_SHT_VAL_SHT_IND_REG',
		'USER_SETTING_ENTRY','UK_USER_SETTING_ENTRY',
		'VAL','UK_VAL_UNIQUE');
	for i in 1 .. v_list.count / 2 loop	
		v_table_name := v_list(2*i-1);
		v_constraint_name := v_list (2*i);

		for r in (select table_name,constraint_name from all_constraints where owner='CSR' and constraint_name=v_constraint_name and table_name=v_table_name and constraint_type='U') loop
			dbms_output.put_line('alter table csr.'||r.table_name||' drop constraint '||r.constraint_name||' drop index');
			execute immediate 'alter table csr.'||r.table_name||' drop constraint '||r.constraint_name||' drop index';
		end loop;
		for r in (select index_name from all_indexes where owner='CSR' and index_name=v_constraint_name and dropped='NO') loop
			dbms_output.put_line('drop index csr.'||r.index_name);
			execute immediate 'drop index csr.'||r.index_name;
		end loop;
	end loop;
end;
/

alter table csr.accuracy_type_option add constraint UK_AT_ID_LABEL  UNIQUE (APP_SID, ACCURACY_TYPE_ID, LABEL);
alter table csr.calc_job add CONSTRAINT UK_CALC_JOB  UNIQUE (APP_SID, UNMERGED, SCENARIO_RUN_SID, PROCESSING);
alter table csr.custom_location add CONSTRAINT AK_CUSTOM_LOCATION  UNIQUE (APP_SID, LOCATION_TYPE_ID, LOCATION_HASH);
alter table csr.dataview_scenario_run add CONSTRAINT UK_DATAVIEW_SCENARIO_RUN  UNIQUE (APP_SID, DATAVIEW_SID, SCENARIO_RUN_TYPE, SCENARIO_RUN_SID);
alter table csr.flow_state_transition add CONSTRAINT UK_FLOW_STATE_TRANSITION  UNIQUE (APP_SID, FROM_STATE_ID, TO_STATE_ID);
alter table csr.ind_Selection_group_MEMBER add CONSTRAINT UK_IND_SELECTION_GROUP_IND  UNIQUE (APP_SID, IND_SID);
alter table csr.issue_pending_val add CONSTRAINT UK_ISSUE_PENDING_VAL  UNIQUE (APP_SID, PENDING_IND_ID, PENDING_REGION_ID, PENDING_PERIOD_ID);
alter table csr.issue_sheet_value add CONSTRAINT UK_ISSUE_SHEET_VALUE  UNIQUE (APP_SID, IND_SID, REGION_SID, START_DTM, END_DTM);
alter table csr.issue_survey_answer add CONSTRAINT UK_ISSUE_SURVEY_ANSWER  UNIQUE (SURVEY_RESPONSE_ID, QUESTION_ID);
alter table csr.model_range add CONSTRAINT UK_MODEL_RANGE  UNIQUE (APP_SID, RANGE_ID);
alter table csr.pending_val add CONSTRAINT UK_PENDING_VAL_IRP  UNIQUE (APP_SID, PENDING_IND_ID, PENDING_REGION_ID, PENDING_PERIOD_ID);
alter table csr.QUICK_SURVEY_EXPR_ACTION add CONSTRAINT UK_QS_EXPR_ACTION  UNIQUE (APP_SID, QUICK_SURVEY_EXPR_ACTION_ID, SURVEY_SID, EXPR_ID);
CREATE UNIQUE INDEX CSR.UX_ROLE_LOOKUP_KEY ON CSR.ROLE(DECODE(LOOKUP_KEY, NULL, NULL, APP_SID), LOOKUP_KEY);
alter table csr.sheet_value add CONSTRAINT UK_SHT_VAL_SHT_IND_REG  UNIQUE (APP_SID, SHEET_ID, IND_SID, REGION_SID);
alter table CSR.user_setting_entry add CONSTRAINT UK_USER_SETTING_ENTRY  UNIQUE (APP_SID, CSR_USER_SID, CATEGORY, SETTING, TAB_PORTLET_ID);
alter table csr.val add CONSTRAINT UK_VAL_UNIQUE UNIQUE (APP_SID, IND_SID, REGION_SID, PERIOD_START_DTM, PERIOD_END_DTM);

@update_tail
