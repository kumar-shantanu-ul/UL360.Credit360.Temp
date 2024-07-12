-- Please update version.sql too -- this keeps clean builds in sync
define version=2010
@update_header

ALTER TABLE csr.dataview 
  ADD show_region_events NUMBER(1) DEFAULT 0 NOT NULL;

@..\dataview_pkg
@..\dataview_body

@update_tail