-- Please update version.sql too -- this keeps clean builds in sync
define version=1459
@update_header

alter table csr.batch_job drop constraint ck_batch_job_type;
alter table csr.deleg_plan_sync_job add batch_job_id number(10);
update csr.deleg_plan_sync_job dpsj set dpsj.batch_job_id = (select batch_job_id from csr.batch_job bj where bj.deleg_plan_sync_job_id = dpsj.deleg_plan_sync_job_id);
alter table csr.deleg_plan_sync_job modify batch_job_id not null;
alter table csr.batch_job add result varchar2(500);
alter table csr.batch_job add result_url varchar2(500);
alter table csr.batch_job drop column deleg_plan_sync_job_id cascade constraints;
alter table csr.deleg_plan_sync_job drop primary key drop index;
alter table csr.deleg_plan_sync_job drop column deleg_plan_sync_job_id;
drop sequence csr.deleg_plan_sync_job_id_seq;
alter table csr.deleg_plan_sync_job add constraint pk_deleg_plan_sync_job primary key (app_sid, batch_job_id);

CREATE OR REPLACE VIEW CSR.v$batch_job AS
	SELECT bj.app_sid, bj.batch_job_id, bj.batch_job_type_id, bj.description,
		   bjt.description batch_job_type_description, bj.requested_by_user_sid,
	 	   cu.full_name requested_by_full_name, cu.email requested_by_email, bj.requested_dtm,
	 	   bj.email_on_completion, bj.started_dtm, bj.completed_dtm, bj.updated_dtm, bj.retry_dtm,
	 	   bj.work_done, bj.total_work, bj.running_on, bj.result, bj.result_url
      FROM batch_job bj, batch_job_type bjt, csr_user cu
     WHERE bj.app_sid = cu.app_sid AND bj.requested_by_user_sid = cu.csr_user_sid
       AND bj.batch_job_type_id = bjt.batch_job_type_id;

@../batch_job_pkg
@../batch_job_body
@../deleg_plan_body
@../csr_data_pkg
@../csr_data_body
@../csr_user_body
@../delegation_body

@update_tail
