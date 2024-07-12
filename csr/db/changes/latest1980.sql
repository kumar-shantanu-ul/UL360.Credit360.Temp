-- Please update version.sql too -- this keeps clean builds in sync
define version=1980
@update_header

ALTER TABLE csrimp.tpl_report_tag_dataview
  ADD (
  	hide_if_empty NUMBER(1) DEFAULT 0 NOT NULL,
  	split_table_by_columns NUMBER(10) DEFAULT 0 NOT NULL);

@../csrimp/imp_body

@update_tail
