-- Please update version.sql too -- this keeps clean builds in sync
define version=431
@update_header

alter table csr.pending_val add merged_state char(1) default 'U' not null;
alter table csr.pending_val add constraint ck_merged_state check (merged_state in ('U', 'S', 'R'));

update pending_val set merged_state = 'S' where pending_val_id in (select pv.pending_val_id from pending_val pv inner join val v on v.source_id = pv.pending_val_id and v.source_type_id = 7 where pv.merged_state = 'U');

@../pending_body.sql
@../approval_step_range_body.sql

@update_tail
