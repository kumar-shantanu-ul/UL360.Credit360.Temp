-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
define minor_version=28
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE CHAIN.HIGG (
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	FTP_FOLDER				VARCHAR2(1000) NOT NULL,
	FTP_PROFILE_LABEL		VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_HIGG PRIMARY KEY (APP_SID)
);

CREATE TABLE CSRIMP.CHAIN_HIGG (
	CSRIMP_SESSION_ID       NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FTP_FOLDER				VARCHAR2(1000),
	FTP_PROFILE_LABEL		VARCHAR2(255),
    CONSTRAINT PK_HIGG PRIMARY KEY (CSRIMP_SESSION_ID),
	CONSTRAINT FK_HIGG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables

-- *** Grants ***

GRANT SELECT, INSERT ON chain.higg TO csr;
GRANT SELECT ON csr.audit_closure_type TO chain;
GRANT SELECT, INSERT, UPDATE ON chain.higg TO csrimp;
GRANT SELECT, INSERT ON chain.higg TO csr;
GRANT INSERT ON chain.higg_module_tag_group TO csr;

GRANT EXECUTE ON chain.higg_setup_pkg TO web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT DISTINCT hc.app_sid, fp.label, ftp.payload_path
		  FROM chain.higg_config hc
		  JOIN csr.auto_imp_fileread_ftp ftp ON ftp.app_sid = hc.app_sid
		  JOIN csr.ftp_profile fp ON fp.ftp_profile_id = ftp.ftp_profile_id
	)
	LOOP
		INSERT INTO chain.higg (app_sid, ftp_profile_label, ftp_folder)
		VALUES (r.app_sid, r.label, r.payload_path);
	END LOOP;

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (88, 'Higg', 'EnableHigg', 'Enables Higg integration');

	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	  VALUES (88, 'in_ftp_profile', 0, 'The FTP profile to use. If this does not already exist, this will be set up to connect to cyanoxantha');
	  
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	  VALUES (88, 'in_ftp_folder', 1, 'The folder on the FTP server containing Higg responses');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../enable_pkg
@../schema_pkg
@../chain/higg_setup_pkg

@../enable_body
@../quick_survey_body
@../schema_body
@../chain/higg_body
@../chain/higg_setup_body
@../csrimp/imp_body

@update_tail
