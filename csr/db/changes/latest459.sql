-- Please update version.sql too -- this keeps clean builds in sync
define version=459
@update_header

create table fb5276 as select * from pending_period where pending_dataset_id in (select pending_dataset_id from pending_period group by pending_dataset_id having count(*) > 1) and (select count(*) from approval_step_sheet where pending_period_id = pending_period.pending_period_id) = 0 and (select count(*) from pending_val where pending_period_id = pending_period.pending_period_id) = 0 order by app_sid, pending_dataset_id, pending_period_id;

delete from PVC_STORED_CALC_JOB where (app_sid, pending_period_id) in (select app_sid, pending_period_id from fb5276);

delete from pending_period where (app_sid, pending_period_id) in (select app_sid, pending_period_id from fb5276);

@update_tail
