-- Please update version.sql too -- this keeps clean builds in sync
define version=3001
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables
-- Missing tables for csrimp from latest1750...
CREATE TABLE csrimp.scenario_run_version (
	csrimp_session_id		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	scenario_run_sid		NUMBER(10) NOT NULL,
	version					NUMBER(10) NOT NULL,
	CONSTRAINT FK_SCN_RUN_VER_IS FOREIGN KEY
		(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.scenario_run_version_file (
	csrimp_session_id		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	scenario_run_sid		NUMBER(10) NOT NULL,
	version					NUMBER(10) NOT NULL,
	file_path				VARCHAR2(4000) NOT NULL,
	sha1					RAW(20) NOT NULL,
	CONSTRAINT FK_SCN_RUN_FILE_SCN_RUN_VER_IS FOREIGN KEY
		(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

-- Alter tables

-- *** Grants ***
GRANT INSERT,SELECT ON csr.scenario_run_version TO csrimp;
GRANT INSERT,SELECT ON csr.scenario_run_version_file TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@../schema_pkg
@@../schema_body
@@../csrimp/imp_body

@update_tail
