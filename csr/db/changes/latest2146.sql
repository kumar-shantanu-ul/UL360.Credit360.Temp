-- Please update version.sql too -- this keeps clean builds in sync
define version=2146
@update_header

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_CALC_TREE
(
	LVL								NUMBER(10)	NOT NULL,
	PARENT_SID						NUMBER(10),
	IND_SID							NUMBER(10)	NOT NULL
) ON COMMIT DELETE ROWS;

@../dag_pkg
@../dag_body
@../stored_calc_datasource_body

@update_tail
