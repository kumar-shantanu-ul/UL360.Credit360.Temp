-- Please update version.sql too -- this keeps clean builds in sync
define version=907
@update_header

ALTER TABLE csr.target_dashboard ADD use_root_region_sid NUMBER(1, 0) DEFAULT 0 NOT NULL;

@..\target_dashboard_pkg
@..\target_dashboard_body

@update_tail
