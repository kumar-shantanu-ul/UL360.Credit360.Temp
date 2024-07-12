-- Please update version.sql too -- this keeps clean builds in sync
define version=2530
@update_header

UPDATE csr.non_compliance_type 
   SET lookup_key = label 
 WHERE lookup_key IS NULL;
 
ALTER TABLE csr.non_compliance_type MODIFY lookup_key NOT NULL;

ALTER TABLE csrimp.non_compliance_type MODIFY lookup_key NOT NULL;

@update_tail
