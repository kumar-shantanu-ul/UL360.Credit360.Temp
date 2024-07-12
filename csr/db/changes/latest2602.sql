--Please update version.sql too -- this keeps clean builds in sync
define version=2602
@update_header

UPDATE csr.non_compliance 
   SET is_closed = NULL 
 WHERE is_closed = 0
   AND non_compliance_type_id IS NULL;

@../audit_body
	
@update_tail
