-- Please update version.sql too -- this keeps clean builds in sync
define version=3165
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.module_param ADD (allow_blank NUMBER(1,0) DEFAULT 0 NOT NULL);
ALTER TABLE csr.module_param ADD CONSTRAINT CHK_ALLOW_BLANK CHECK (ALLOW_BLANK IN (0,1));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	UPDATE csr.module_param
	   SET param_name = 'Secondary Tree Name?'
	 WHERE module_id = 1
	   AND pos = 0;

	UPDATE csr.module_param
	   SET param_name = 'Site name', param_hint = NULL
	 WHERE module_id = 7
	   AND pos = 0;

	UPDATE csr.module_param
	   SET param_name = 'Company name', param_hint = NULL
	 WHERE module_id = 13
	   AND pos = 0;

	UPDATE csr.module_param
	   SET param_name = 'User name', param_hint = NULL
	 WHERE module_id = 15
	   AND pos = 0;
	UPDATE csr.module_param
	   SET param_name = 'Password', param_hint = NULL
	 WHERE module_id = 15
	   AND pos = 1;

	UPDATE csr.module_param
	   SET param_name = 'Create default initiative module projects, metrics and metric groups?', param_hint = '(y|n default=n)'
	 WHERE module_id = 46
	   AND pos = 0;
	   
	UPDATE csr.module_param
	   SET param_name = 'The path to the client''s Urjanet folder on our SFTP server (cyanoxantha)', param_hint = 'client_name.urjanet'
	 WHERE module_id = 60
	   AND pos = 0;

	UPDATE csr.module_param
	   SET param_name = 'Use sandbox GRESB enviornment instead of live?', param_hint = '(y|n default=n)'
	 WHERE module_id = 65
	   AND pos = 0;

	UPDATE csr.module_param
	   SET param_name = 'Create regulation workflow?', param_hint = '(Y/N)'
	 WHERE module_id = 79
	   AND pos = 0;
	UPDATE csr.module_param
	   SET param_name = 'Create requirement workflow?', param_hint = '(Y/N)'
	 WHERE module_id = 79
	   AND pos = 1;

	UPDATE csr.module_param
	   SET param_name = 'ENHESA client id', param_hint = NULL
	 WHERE module_id = 80
	   AND pos = 0;

	UPDATE csr.module_param
	   SET param_name = 'Provide name of top level company if chain is not already enabled', param_hint = NULL
	 WHERE module_id = 84
	   AND pos = 0;
	UPDATE csr.module_param
	   SET param_name = 'Enter default property type (existing properties will be assigned this type)', param_hint = NULL
	 WHERE module_id = 84
	   AND pos = 1;

	UPDATE csr.module_param
	   SET param_name = 'The FTP profile to use. If this does not already exist, this will be set up to connect to cyanoxantha', param_hint = NULL
	 WHERE module_id = 88
	   AND pos = 0;
	UPDATE csr.module_param
	   SET param_name = 'The folder on the FTP server containing Higg responses', param_hint = NULL
	 WHERE module_id = 88
	   AND pos = 1;
END;
/

BEGIN
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint, allow_blank)
	VALUES (99, 'ProviderHint', 0, 'empty (default FileStore), Azure, FileStore', 1);
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint, allow_blank)
	VALUES (99, 'Force switch of provider if already exists', 1, '0=no, 1=yes', 1);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../enable_body

@update_tail
