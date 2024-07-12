-- Please update version.sql too -- this keeps clean builds in sync
define version=794
@update_header

ALTER TABLE csr.logistics_default DROP COLUMN distance_breakdown;
ALTER TABLE csr.logistics_default ADD distance_breakdown SYS.XMLType NULL;


@update_tail
