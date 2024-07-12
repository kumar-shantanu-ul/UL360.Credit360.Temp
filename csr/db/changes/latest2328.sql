-- Please update version.sql too -- this keeps clean builds in sync
define version=2328
@update_header

ALTER TABLE csr.batch_job_structure_import ADD company_sid NUMBER(10);
ALTER TABLE csr.batch_job_structure_import ADD CONSTRAINT fk_bjsi_supplier 
	FOREIGN KEY(app_sid, company_sid) REFERENCES csr.supplier(app_sid, company_sid);

@../property_pkg
@../property_body
@../space_body
@../structure_import_body

@update_tail
