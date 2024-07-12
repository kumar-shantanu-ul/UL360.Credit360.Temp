-- Please update version.sql too -- this keeps clean builds in sync
define version=1628
@update_header

INSERT INTO csr.capability (name, allow_by_default) VALUES ('Suppress N\A''s in model runs', 0);
							 
@update_tail
