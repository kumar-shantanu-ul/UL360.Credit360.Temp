--Please update version.sql too -- this keeps clean builds in sync
define version=2654
@update_header

alter table csr.ruleset add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);
update csr.ruleset set period_set_id = 1, period_interval_id = decode(interval,'y',4,'h',3,'q',2,'m',1,'3',4,-1);
alter table csr.ruleset modify period_set_id not null;
alter table csr.ruleset modify period_interval_id not null;
alter table csr.ruleset add constraint fk_ruleset_period_int foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);

@../ruleset_pkg
@../ruleset_body

@update_tail
