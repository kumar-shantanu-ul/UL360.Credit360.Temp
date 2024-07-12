-- Please update version.sql too -- this keeps clean builds in sync
define version=810
@update_header

create table csr.stored_calc_job_temp as 
	select app_sid, ind_sid, processing, min(start_dtm) start_dtm, max(end_dtm) end_dtm
	  from csr.stored_calc_job
	 group by app_sid, ind_sid, processing;
	  
alter table csr.stored_calc_job drop primary key drop index;
alter table csr.stored_calc_job drop column region_sid cascade constraints;
truncate table csr.stored_calc_job;
alter table csr.stored_calc_job add CONSTRAINT PK_CALC_IND_RECALC_JOB PRIMARY KEY (APP_SID, IND_SID, PROCESSING);
insert into csr.stored_calc_job (app_sid, ind_sid, start_dtm, end_dtm, processing)
	select app_sid, ind_sid, start_dtm, end_dtm, processing
	  from csr.stored_calc_job_temp;
drop table csr.stored_calc_job_temp;

@../val_body
@../system_status_body
@../indicator_body
@../region_body
@../calc_body

@update_tail