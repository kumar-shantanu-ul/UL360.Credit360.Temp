-- Please update version.sql too -- this keeps clean builds in sync
define version=2844
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.UTIL_SCRIPT_PARAM ADD PARAM_VALUE VARCHAR2(1024);
ALTER TABLE CSR.UTIL_SCRIPT_PARAM ADD PARAM_HIDDEN NUMBER(1) DEFAULT 0 NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
VALUES (9, 'Enable/Disable automatic parent-child sheet status matching', 'Updates customer.status_from_parent_on_subdeleg. See wiki for details.', 'SetFlag', 'W2570');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos, param_value, param_hidden)
VALUES (9, 'Table', 'Fixed Param', 0, 'csr.customer', 1);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos, param_value, param_hidden)
VALUES (9, 'Column', 'Fixed Param', 1, 'status_from_parent_on_subdeleg', 1);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos)
VALUES (9, 'Setting value (0 off, 1 on)', 'The setting to use.', 2);

UPDATE CSR.UTIL_SCRIPT
   SET util_script_name = 'Toggle multi-period delegation flag',
       util_script_sp = 'ToggleDelegMultiPeriodFlag'
 WHERE util_script_id=4;

-- ** New package grants **

-- *** Packages ***
@..\util_script_pkg
@..\util_script_body

@update_tail
