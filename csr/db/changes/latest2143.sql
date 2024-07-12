-- Please update version.sql too -- this keeps clean builds in sync
define version=2143
@update_header

ALTER TABLE csr.cms_alert_type ADD (is_batched NUMBER(1, 0) DEFAULT 0 NOT NULL);
ALTER TABLE csrimp.cms_alert_type ADD (is_batched NUMBER(1, 0) DEFAULT 0 NOT NULL);

@..\alert_pkg;
@..\alert_body;

@..\csrimp\imp_body;

@..\schema_body;
		
@update_tail
