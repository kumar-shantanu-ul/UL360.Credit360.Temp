-- Please update version.sql too -- this keeps clean builds in sync
define version=81
@update_header

ALTER TABLE SUPPLIER.GT_PROFILE ADD (SCORE_PACK_IMPACT_RAW NUMBER(10,2));

@update_tail