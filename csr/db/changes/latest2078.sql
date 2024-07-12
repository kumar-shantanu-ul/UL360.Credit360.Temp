define version=2078
@update_header

ALTER TABLE csr.batch_job_structure_import ADD lang VARCHAR(10);
UPDATE csr.batch_job_structure_import
SET lang = 'en-gb';
ALTER TABLE csr.batch_job_structure_import MODIFY lang VARCHAR(10) NOT NULL;

@../structure_import_body

@update_tail
