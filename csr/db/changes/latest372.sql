-- Please update version.sql too -- this keeps clean builds in sync
define version=372
@update_header

alter table target_dashboard modify end_dtm null;

@..\target_dashboard_body

@update_tail
