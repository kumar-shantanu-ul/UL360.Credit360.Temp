-- Please update version.sql too -- this keeps clean builds in sync
define version=2220
@update_header

alter table csrimp.SCENARIO_RUN_VAL drop constraint PK_SCENARIO_RUN_VAL;
alter table csrimp.SCENARIO_RUN_VAL add CONSTRAINT PK_SCENARIO_RUN_VAL PRIMARY KEY (CSRIMP_SESSION_ID, SCENARIO_RUN_SID, IND_SID, REGION_SID, PERIOD_START_DTM, PERIOD_END_DTM);

@update_tail
