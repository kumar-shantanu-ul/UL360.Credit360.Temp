-- Please update version.sql too -- this keeps clean builds in sync
define version=328
@update_header

create index ix_sht_inhrt_val_app_inhrt_id on sheet_inherited_value(app_sid,inherited_value_id) tablespace indx;

@update_tail
