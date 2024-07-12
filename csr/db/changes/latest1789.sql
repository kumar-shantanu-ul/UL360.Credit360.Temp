-- Please update version.sql too -- this keeps clean builds in sync
define version=1789
@update_header

-- FB32392 CHG005-ID065-Pareto View / Anonymous Regions
ALTER TABLE csr.dataview ADD anonymous_region_names      NUMBER(1)      DEFAULT 0 NOT NULL;

@..\dataview_pkg
@..\dataview_body

@update_tail
