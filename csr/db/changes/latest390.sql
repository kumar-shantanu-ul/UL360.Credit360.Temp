-- Please update version.sql too -- this keeps clean builds in sync
define version=390
@update_header

ALTER TABLE csr.dataview ADD (
	SORT_BY_MOST_RECENT    NUMBER(1, 0)      DEFAULT 0 NOT NULL
);

@../schema_body.sql
@../dataview_pkg.sql
@../dataview_body.sql

@update_tail
