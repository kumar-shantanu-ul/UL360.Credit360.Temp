-- Please update version.sql too -- this keeps clean builds in sync
define version=2545
@update_header

ALTER TABLE
   csr.cms_imp_class_step
RENAME COLUMN
   ftp_sort_by
TO
   sort_by;

ALTER TABLE
   csr.cms_imp_class_step
RENAME COLUMN
   ftp_sort_by_dir
TO
   sort_by_direction;

ALTER TABLE
   csr.cms_imp_class_step
RENAME COLUMN
   ftp_file_mask
TO
   file_mask;

ALTER TABLE
   csr.cms_imp_class
RENAME COLUMN
   on_completion_plugin
TO
   import_plugin;
   
ALTER TABLE
	CSR.CMS_IMP_CLASS_STEP
ADD PLUGIN VARCHAR2(255);

@../cms_data_imp_pkg;
@../cms_data_imp_body;

@update_tail
