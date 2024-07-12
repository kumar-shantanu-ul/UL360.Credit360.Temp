-- Please update version.sql too -- this keeps clean builds in sync
define version=314
@update_header

ALTER TABLE customer ADD use_tracker NUMBER(1) DEFAULT 1 NOT NULL CHECK (use_tracker IN (0,1));

@..\schema_body
@..\csr_app_body

@update_tail
