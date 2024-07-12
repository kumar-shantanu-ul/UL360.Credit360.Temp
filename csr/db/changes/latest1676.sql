-- Please update version.sql too -- this keeps clean builds in sync
define version=1676
@update_header

grant execute on csr.deleg_report_pkg to web_user;

ALTER TABLE csr.deleg_report MODIFY (
	APP_SID DEFAULT SYS_CONTEXT('SECURITY', 'APP')
);

ALTER TABLE csr.deleg_report_deleg_plan MODIFY (
	APP_SID DEFAULT SYS_CONTEXT('SECURITY', 'APP')
);

ALTER TABLE csr.deleg_report_region MODIFY (
	APP_SID DEFAULT SYS_CONTEXT('SECURITY', 'APP')
);

@../deleg_report_pkg
@../deleg_report_body

@update_tail
