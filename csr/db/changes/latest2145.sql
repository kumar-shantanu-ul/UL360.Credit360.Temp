-- Please update version.sql too -- this keeps clean builds in sync
define version=2145
@update_header

ALTER TABLE csr.batch_job_cms_import ADD settings_xml_t CLOB;

UPDATE csr.batch_job_cms_import SET settings_xml_t = TO_CLOB(settings_xml);

COMMIT;

ALTER TABLE csr.batch_job_cms_import DROP COLUMN settings_xml;

ALTER TABLE csr.batch_job_cms_import RENAME COLUMN settings_xml_t TO settings_xml;

ALTER TABLE csr.batch_job_cms_import MODIFY settings_xml NOT NULL;

@../cms_import_pkg
@../cms_import_body

@update_tail
