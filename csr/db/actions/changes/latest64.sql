-- Please update version.sql too -- this keeps clean builds in sync
define version=64
@update_header

CREATE GLOBAL TEMPORARY TABLE PROGRESS_DATA
(
	IDX					NUMBER(10, 0)	NOT NULL,
	REGION_SID			NUMBER(10, 0)	NULL,
	IND_SID				NUMBER(10, 0)	NULL,
	PERIOD_START_DTM	DATE			NULL,
	VAL					NUMBER(24,10)	NULL
)
ON COMMIT DELETE ROWS;

@update_tail
