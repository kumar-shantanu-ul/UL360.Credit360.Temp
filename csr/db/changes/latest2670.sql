--Please update version.sql too -- this keeps clean builds in sync
define version=2670
@update_header

alter table csr.calc_job add notified number (1) default 0 not null ;
alter table csr.calc_job add constraint ck_calc_job_notified check (notified in (0,1));
alter table csr.customer add calc_job_notify_address varchar2(512) default 'support@credit360.com';
alter table csr.customer add calc_job_notify_after_attempts number(10) default 3;

@../stored_calc_datasource_pkg
@../stored_calc_datasource_body

@update_tail
