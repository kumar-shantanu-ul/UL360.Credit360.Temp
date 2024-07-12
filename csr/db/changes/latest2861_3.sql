-- Please update version.sql too -- this keeps clean builds in sync
define version=2861
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DEFINE script_id=11

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
VALUES (&&script_id, 'Enable/Disable self-registration permissions', 'Updates permissions. See wiki for details.', 'SetSelfRegistrationPermissions', 'W2592');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos)
VALUES (&&script_id, 'Setting value (0 off, 1 on)', 'The setting to use.', 0);

-- ** New package grants **

-- *** Packages ***
@..\csr_data_pkg
@..\csr_data_body
@..\util_script_pkg
@..\util_script_body


@update_tail
