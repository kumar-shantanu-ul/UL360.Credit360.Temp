-- Please update version.sql too -- this keeps clean builds in sync
define version=3129
define minor_version=2
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

DELETE FROM csr.module_param WHERE module_id = 97;
UPDATE csr.module
   SET description = '[In development] Enables API integrations. See utility script page for API user creation.'
 WHERE module_id = 97;

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (38,'API integrations - Create API Client','[In development] Will create a API Client and user if the specified username doesn''t exist.','CreateAPIClient',null);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (38, 'User Name', 'The name of the user the api integration will connect as. If the name specified doesn''t exist, it will be created (as a hidden user).', 1, NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (38, 'Client Id', 'A secure string for the client ID. Generate a GUID perhaps.', 2, NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (38, 'Client Secret', 'Akin to a password. Should be kept secure. Generate a GUID perhaps.', 3, NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (39,'API integrations - Update API Client secret','[In development] Update the client secret for a client id (API users).','UpdateAPIClientSecret',null);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (39, 'Client Id', 'The id of the client to update', 1, NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (39, 'Client Secret', 'The new secret', 2, NULL);


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../security/db/oracle/user_pkg
@../../../security/db/oracle/user_body

@../enable_pkg
@../util_script_pkg

@../enable_body
@../util_script_body

@update_tail
