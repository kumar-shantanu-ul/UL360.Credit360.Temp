-- Please update version.sql too -- this keeps clean builds in sync
define version=467
@update_header

ALTER TABLE PENDING_IND add     FILE_UPLOAD_MANDATORY    NUMBER(1, 0)      DEFAULT 0 NOT NULL;
alter table PENDING_IND add CONSTRAINT CK_PENDING_IND_FILUPLOAD_MAND CHECK (FILE_UPLOAD_MANDATORY IN (0,1));

@../pending_pkg.sql
@../pending_body
@../schema_body.sql
@../pending_datasource_body.sql
@../approval_step_range_body.sql

@update_tail
