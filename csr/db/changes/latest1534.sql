-- Please update version.sql too -- this keeps clean builds in sync
define version=1534
@update_header

ALTER TABLE csr.csr_user RENAME COLUMN parent_sid TO line_manager_sid;
ALTER TABLE csrimp.csr_user RENAME COLUMN parent_sid TO line_manager_sid;

UPDATE csr.capability
   SET name = 'Edit user line manager'
 WHERE name = 'Edit user parent';
 
COMMIT;


@../csr_user_pkg
@../csr_user_body
@../chain/company_user_body
@../csrimp/imp_body
@../schema_body

@update_tail