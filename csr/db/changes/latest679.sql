-- Please update version.sql too -- this keeps clean builds in sync
define version=679
@update_header

alter table csr.dataview drop column use_aggr_estimates cascade constraints;
alter table csr.ind drop column aggr_estimate_with_ind_sid cascade constraints;

drop table csr.get_value_result;

CREATE GLOBAL TEMPORARY TABLE csr.GET_VALUE_RESULT
(
	period_start_dtm	DATE,
	period_end_dtm		DATE,
	source				NUMBER(10,0),
	source_id			NUMBER(10,0),
	source_type_id		NUMBER(10,0),
	ind_sid				NUMBER(10,0),
	region_sid			NUMBER(10,0),
	val_number			NUMBER(24,10),
	changed_dtm			DATE,
	note				CLOB,
	flags				NUMBER (10,0),
	is_leaf				NUMBER(1,0),
	is_merged			NUMBER(1,0),
	path				VARCHAR2(1024)
) ON COMMIT DELETE ROWS;


@../dataview_pkg.sql
@../val_datasource_pkg.sql
@../indicator_pkg.sql
@../dataview_body.sql
@../datasource_body.sql
@../vb_legacy_body.sql
@../range_body.sql
@../pending_datasource_body.sql
@../meter_body.sql
@../val_datasource_body.sql
@../schema_body.sql
@../delegation_body.sql
@../model_body.sql
@../indicator_body.sql
@../stored_calc_datasource_body.sql
@../pending_body.sql
@../measure_body.sql
@../csr_data_body.sql
@../val_body.sql

PROMPT also recompile:
PROMPT ../actions/task_body.sql
PROMPT ../actions/ind_template_body.sql
PROMPT ../actions/project_body.sql

@update_tail
