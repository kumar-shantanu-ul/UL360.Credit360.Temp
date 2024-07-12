-- Please update version too -- this keeps clean builds in sync
define version=1725
@update_header

whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

BEGIN INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C) VALUES (26200, 5, 'mm^3', 1000000000, 1, 0); EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
/

@update_tail