-- Please update version.sql too -- this keeps clean builds in sync
define version=423
@update_header

alter table scenario_rule modify end_dtm null;

@update_tail
