-- Please update version too -- this keeps clean builds in sync
define version=1853
@update_header

ALTER TABLE csr.batch_job_cms_import ADD user_sid NUMBER(10) DEFAULT 3 NOT NULL;

@..\cms_import_pkg
@..\cms_import_body

@update_tail
