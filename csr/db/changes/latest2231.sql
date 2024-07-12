-- Please update version.sql too -- this keeps clean builds in sync
define version=2231
@update_header

alter table csrimp.CALC_TAG_DEPENDENCY drop constraint PK_CALC_TAG_DEP;
alter table csrimp.CALC_TAG_DEPENDENCY add CONSTRAINT PK_CALC_TAG_DEP PRIMARY KEY (CSRIMP_SESSION_ID, CALC_IND_SID, TAG_ID);

@update_tail