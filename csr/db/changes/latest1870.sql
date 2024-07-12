-- Please update version.sql too -- this keeps clean builds in sync
define version=1870
@update_header

ALTER TABLE csr.benchmark_dashboard_ind ADD pos NUMBER(10, 0) NULL;
UPDATE csr.benchmark_dashboard_ind SET POS = 0;
ALTER TABLE csr.benchmark_dashboard_ind MODIFY pos NOT NULL;

@update_tail
