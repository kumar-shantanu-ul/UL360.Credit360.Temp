-- Please update version.sql too -- this keeps clean builds in sync
define version=1616
@update_header

ALTER TABLE csr.dataview_ind_member ADD (
	show_as_rank NUMBER(1) DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.dataview_ind_member ADD (
	show_as_rank NUMBER(1) DEFAULT 0 NOT NULL
);

@..\dataview_pkg
@..\dataview_body

@update_tail
