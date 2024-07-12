-- Please update version.sql too -- this keeps clean builds in sync
define version=2256
@update_header

-- Make lookup_key column the same type as region_ref (lookup_key VARCHAR2(64) to VARCHAR2(255)).
ALTER TABLE csr.region
MODIFY(lookup_key VARCHAR2(255));

@update_tail
