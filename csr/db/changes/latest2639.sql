-- Please update version.sql too -- this keeps clean builds in sync
define version=2639
@update_header

DROP TYPE CSR.T_DATASOURCE_DEP_TABLE;

CREATE OR REPLACE TYPE CSR.T_DATASOURCE_DEP_ROW AS 
  OBJECT ( 
	SEEK_IND_SID    			NUMBER(10, 0),
	CALC_DEP_TYPE				NUMBER(10, 0),
	DEP_IND_SID     			NUMBER(10, 0),
	LVL         				NUMBER(10, 0),
	CALC_START_DTM_ADJUSTMENT	NUMBER(10, 0),
	CALC_END_DTM_ADJUSTMENT		NUMBER(10, 0)
  );
/

CREATE OR REPLACE TYPE     CSR.T_DATASOURCE_DEP_TABLE AS
  TABLE OF CSR.T_DATASOURCE_DEP_ROW;
/



DROP TYPE CSR.T_CALC_DEP_TABLE;

CREATE OR REPLACE TYPE CSR.T_CALC_DEP_ROW AS 
  OBJECT ( 
	DEP_TYPE					NUMBER(10,0),
	IND_SID						NUMBER(10,0),
	IND_TYPE					NUMBER(10,0),
	CALC_START_DTM_ADJUSTMENT	NUMBER(10,0),
	CALC_END_DTM_ADJUSTMENT		NUMBER(10,0)
  );
/

create or replace TYPE     CSR.T_CALC_DEP_TABLE AS
  TABLE OF CSR.T_CALC_DEP_ROW;
/


@../dataset_legacy_body
@../datasource_body
@../dataview_body
@../delegation_body
@../form_body
@../indicator_body
@../stored_calc_datasource_body
@../target_dashboard_body
@../vb_legacy_body
@../val_datasource_body
@../calc_body

@update_tail
