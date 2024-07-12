-- Please update version.sql too -- this keeps clean builds in sync
define version=737
@update_header

UPDATE csr.issue_type 
   SET label = 'Basic issue'
 WHERE issue_type_id = 1000;

@..\csr_data_pkg
@..\issue_body

@update_tail
