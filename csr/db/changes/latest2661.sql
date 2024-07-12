--Please update version.sql too -- this keeps clean builds in sync
define version=2661
@update_header

alter table csr.batch_job add attempts number (10) default 0 not null ;
alter table csr.batch_job add notified number (1) default 0 not null ;
alter table csr.batch_job add constraint ck_batch_job_notified check (notified in (0,1));
alter table csr.batch_job_type add notify_address varchar2(512) default 'support@credit360.com';
alter table csr.batch_job_type add notify_after_attempts number(10) default 3;

@../batch_job_pkg
@../batch_job_body

@update_tail
