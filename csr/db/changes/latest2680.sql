--Please update version.sql too -- this keeps clean builds in sync
define version=2680
@update_header

ALTER TABLE csr.approval_dashboard add
(
	period_set_id 			NUMBER(10),
	period_interval_id		NUMBER(10)
);
update csr.approval_dashboard set period_set_id = 1, period_interval_id = decode(interval,'y',4,'h',3,'q',2,'m',1,-1);
alter table csr.approval_dashboard modify period_set_id not null;
alter table csr.approval_dashboard modify period_interval_id not null;
ALTER TABLE csr.approval_dashboard ADD CONSTRAINT fk_app_dash_period_int FOREIGN KEY (app_sid, period_set_id, period_interval_id)
REFERENCES csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.approval_dashboard drop column interval;

@../approval_dashboard_pkg
@../approval_dashboard_body

@update_tail
