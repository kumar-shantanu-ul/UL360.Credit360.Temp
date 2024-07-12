-- Please update version.sql too -- this keeps clean builds in sync
define version=877
@update_header

INSERT INTO csr.std_factor_set(std_factor_set_id, name) VALUES (9, 'eGrid v1.1');

ALTER TABLE csr.logistics_default
	ADD sort_column NUMBER(1, 0) DEFAULT 0 NOT NULL;

@update_tail
