-- Please update version.sql too -- this keeps clean builds in sync
define version=55
@update_header

ALTER TABLE TASK MODIFY WEIGHTING NUMBER(5,4);

@update_tail
