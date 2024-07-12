-- Please update version.sql too -- this keeps clean builds in sync
define version=815
@update_header

INSERT INTO csr.tpl_region_type (tpl_region_type_id, label)
VALUES (8, 'Selected region and its children');

INSERT INTO csr.tpl_region_type (tpl_region_type_id, label)
VALUES (9, 'Selected region, its parents and its children');

@update_tail