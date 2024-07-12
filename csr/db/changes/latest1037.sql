-- Please update version.sql too -- this keeps clean builds in sync
define version=1037
@update_header

alter table csr.temp_alert_batch_details drop column deleg_assigned_to;

@../sheet_body

@update_tail
