-- Please update version.sql too -- this keeps clean builds in sync
define version=2815
define minor_version=21
@update_header

UPDATE security.securable_object_class
   SET helper_pkg = 'csr.automated_import_pkg'
 WHERE class_name = 'CSRAutomatedImport';

UPDATE security.securable_object_class
   SET helper_pkg = 'csr.automated_export_pkg'       
 WHERE class_name = 'CSRAutomatedExport';

@update_tail
