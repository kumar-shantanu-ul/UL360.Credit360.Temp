-- Please update version.sql too -- this keeps clean builds in sync
define version=625
@update_header

INSERT INTO csr.std_factor_set (std_factor_set_id, name) values (4, 'NGA');
INSERT INTO csr.std_factor_set (std_factor_set_id, name) values (5, 'Canada National');

@update_tail
