-- Please update version.sql too -- this keeps clean builds in sync
define version=1755
@update_header

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_REGION_METRIC_VAL (
	APP_SID					NUMBER(10),
	REGION_SID				NUMBER(10),
	IND_SID					NUMBER(10),
	EFFECTIVE_DTM			DATE,
	VAL						NUMBER(24,10),
	NOTE					VARCHAR2(4000)
) ON COMMIT DELETE ROWS;

@../region_metric_body

@update_tail


