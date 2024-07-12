-- Please update version.sql too -- this keeps clean builds in sync
define version=577
@update_header

create index ix_val_source_type_source on val (app_sid, source_type_id, source_id);

@update_tail
