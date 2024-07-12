-- Please update version.sql too -- this keeps clean builds in sync
define version=1773
@update_header

ALTER TABLE csr.batch_job_structure_import ADD allow_null_overwrite NUMBER(1) DEFAULT 0 NOT NULL;

@update_tail