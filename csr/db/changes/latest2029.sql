-- Please update version.sql too -- this keeps clean builds in sync
define version=2029
@update_header

ALTER TABLE csr.initiative_metric ADD (
	LOOKUP_KEY	VARCHAR2(255)
);

@..\initiative_grid_pkg
@..\initiative_grid_body

@update_tail
