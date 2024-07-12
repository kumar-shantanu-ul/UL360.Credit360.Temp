-- Please update version.sql too -- this keeps clean builds in sync
define version=2244
@update_header

GRANT DELETE ON chain.supplier_audit TO csr;

@../audit_body
    	
@update_tail
