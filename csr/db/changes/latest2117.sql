-- Please update version.sql too -- this keeps clean builds in sync
define version=2117
@update_header

ALTER TABLE csr.dataview ADD (suppress_unmerged_data_message NUMBER(1, 0) DEFAULT 0 NOT NULL);

@..\dataview_pkg
@..\dataview_body

@update_tail
