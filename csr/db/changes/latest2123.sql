-- Please update version.sql too -- this keeps clean builds in sync
define version=2123
@update_header

ALTER TABLE csrimp.dataview ADD (suppress_unmerged_data_message NUMBER(1, 0) DEFAULT 0 NOT NULL);

@..\csrimp\imp_body

@update_tail
