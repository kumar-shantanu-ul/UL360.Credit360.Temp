-- Please update version.sql too -- this keeps clean builds in sync
define version=46
@update_header

ALTER TABLE scheme ADD track_company_giving NUMBER(1) DEFAULT 0 NOT NULL;

@../scheme_pkg
@../scheme_body

@update_tail
