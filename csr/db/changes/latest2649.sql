--Please update version.sql too -- this keeps clean builds in sync
define version=2649
@update_header

alter table csr.deleg_report add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);
update csr.deleg_report set period_set_id = 1, period_interval_id = decode(interval,'y',4,'h',3,'q',2,'m',1,'3',4,-1);
alter table csr.deleg_report modify period_set_id not null;
alter table csr.deleg_report modify period_interval_id not null;
alter table csr.deleg_report add constraint fk_deleg_report_period_int foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);

@../deleg_report_pkg
@../deleg_report_body

@update_tail
