-- Please update version.sql too -- this keeps clean builds in sync
define version=995
@update_header


CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_DELEG_PLAN_OVERLAP
(
	APP_SID						NUMBER(10)                  NOT NULL,
	DELEG_PLAN_COL_DELEG_ID		NUMBER(10)                  NOT NULL, 
	REGION_SID					NUMBER(10)                  NOT NULL, 
	APPLIED_TO_REGION_SID		NUMBER(10)                  NOT NULL,	
	OVERLAPPING_SID				NUMBER(10)                  NOT NULL
)
ON COMMIT DELETE ROWS;

update csr.delegation
    set master_delegation_sid = null
  where delegation_sid in (
	select delegation_sid from csr.master_deleg
  );

@..\deleg_plan_pkg
@..\deleg_plan_body

@update_tail
