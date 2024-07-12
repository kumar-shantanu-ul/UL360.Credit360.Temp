-- Please update version.sql too -- this keeps clean builds in sync
define version=2066
@update_header

-- Change TEMP_DELEG_PLAN_OVERLAP to use ON COMMIT PRESERVE ROWS

-- this will fail if there are still sessions alive that are using it
-- might just have to keep trying?
DROP TABLE CSR.TEMP_DELEG_PLAN_OVERLAP;

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_DELEG_PLAN_OVERLAP
(
	APP_SID						NUMBER(10)                  NOT NULL,
	DELEG_PLAN_COL_DELEG_ID		NUMBER(10)                  NOT NULL, 
	REGION_SID					NUMBER(10)                  NOT NULL, 
	APPLIED_TO_REGION_SID		NUMBER(10)                  NOT NULL,	
	OVERLAPPING_SID				NUMBER(10)                  NOT NULL
)
ON COMMIT PRESERVE ROWS;

@../deleg_plan_body

@update_tail
