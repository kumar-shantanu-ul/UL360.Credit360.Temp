-- Please update version.sql too -- this keeps clean builds in sync
define version=1558
@update_header

ALTER TABLE csr.dataview RENAME COLUMN rank_limit TO rank_limit_left;
ALTER TABLE csr.dataview ADD rank_limit_right      NUMBER(10, 0)      DEFAULT 0 NOT NULL;

@..\dataview_pkg
@..\dataview_body
 
@update_tail
