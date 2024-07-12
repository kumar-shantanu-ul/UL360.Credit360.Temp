-- Please update version.sql too -- this keeps clean builds in sync
define version=1527
@update_header

ALTER TABLE csr.dataview ADD rank_missing_values_treatment      NUMBER(10, 0)      DEFAULT 0 NOT NULL;

@..\dataview_pkg
@..\dataview_body
 
@update_tail
