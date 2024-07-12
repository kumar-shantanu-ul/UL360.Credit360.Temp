-- Please update version.sql too -- this keeps clean builds in sync
define version=1
@update_header


-- for testing flashback
DROP TABLE GT_TRANSPO_04282009125813000
 CASCADE CONSTRAINTS;



@update_tail