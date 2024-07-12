-- Please update version.sql too -- this keeps clean builds in sync
define version=1885
@update_header

ALTER TABLE csr.dataview ADD include_notes_in_table      NUMBER(1)      DEFAULT 0 NOT NULL;

@../dataview_pkg
@../dataview_body

@update_tail
