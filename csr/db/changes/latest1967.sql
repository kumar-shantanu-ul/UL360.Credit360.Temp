-- Please update version.sql too -- this keeps clean builds in sync
define version=1967
@update_header

ALTER TABLE csr.tpl_report_tag_dataview
  ADD (split_table_by_columns NUMBER(10) DEFAULT 0 NOT NULL);

@../templated_report_pkg
@../templated_report_body

@update_tail
