define version=3476
define minor_version=0
define is_combined=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
DELETE FROM CSR.UTIL_SCRIPT_RUN_LOG
WHERE UTIL_SCRIPT_ID = 77;
DELETE FROM CSR.UTIL_SCRIPT_PARAM
WHERE UTIL_SCRIPT_ID = 77;
DELETE FROM CSR.UTIL_SCRIPT
WHERE UTIL_SCRIPT_ID = 77;

DELETE FROM csr.automated_export_instance
WHERE automated_export_class_sid IN (
    select automated_export_class_sid FROM csr.automated_export_class
    WHERE exporter_plugin_id = 26
);

DELETE FROM csr.automated_export_class
WHERE exporter_plugin_id = 26;

DELETE FROM csr.auto_exp_exporter_plugin 
WHERE plugin_id = 26;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_pkg
@../util_script_body

@update_tail
