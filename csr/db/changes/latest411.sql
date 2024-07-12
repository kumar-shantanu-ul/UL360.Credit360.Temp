-- Please update version.sql too -- this keeps clean builds in sync
define version=411
@update_header

alter table customer drop constraint ck_aggregation_engine_version;
alter table customer add constraint ck_aggregation_engine_version check (aggregation_engine_version in (1,2,3));

drop index idx_val_last_val_change_id;
create index idx_val_last_val_change_id on val(app_sid, last_val_change_id)

set define off
@..\calc_pkg
@..\calc_body
@..\indicator_body

@update_tail
