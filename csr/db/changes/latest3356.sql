define version=3356
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;

CREATE TABLE CSR.CONTEXT_SENSITIVE_HELP_REDIRECT (
	source_path			VARCHAR(2048)	NOT NULL,
	help_path			VARCHAR(2048)	NOT NULL,
	CONSTRAINT PK_CONTEXT_SENSITIVE_HELP_REDIRECT PRIMARY KEY (source_path)
);
CREATE TABLE CSR.CONTEXT_SENSITIVE_HELP_BASE (
	client_help_root	VARCHAR(128) NOT NULL,
	internal_help_root	VARCHAR(128) NOT NULL,
	CONSTRAINT PK_CONTEXT_SENSITIVE_HELP_BASE PRIMARY KEY (client_help_root, internal_help_root)
);
CREATE UNIQUE INDEX CONTEXT_SENSITIVE_HELP_BASE_UK ON CSR.CONTEXT_SENSITIVE_HELP_BASE ('1');
DROP INDEX CONTEXT_SENSITIVE_HELP_BASE_UK;
CREATE UNIQUE INDEX CSR.CONTEXT_SENSITIVE_HELP_BASE_UK ON CSR.CONTEXT_SENSITIVE_HELP_BASE ('1');
--Failed to locate all sections of latest3353_5.sql


ALTER TABLE CSR.AUTO_IMP_CORE_DATA_VAL
MODIFY SOURCE_FILE_REF VARCHAR2(4000)
;
ALTER TABLE CSR.AUTO_IMP_CORE_DATA_VAL_FAIL
MODIFY SOURCE_FILE_REF VARCHAR2(4000)
;


CREATE OR REPLACE PACKAGE csr.context_sensitive_help_pkg AS
	PROCEDURE DUMMY;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.context_sensitive_help_pkg AS
	PROCEDURE DUMMY
AS
	BEGIN
		NULL;
	END;
END;
/
GRANT EXECUTE ON csr.context_sensitive_help_pkg TO web_user;








BEGIN
	INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Context Sensitive Help', 0, 'Enable context sensitive help for this site.');
	INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Context Sensitive Help Management', 0, 'Enable context sensitive help global management page.');
	INSERT INTO CSR.CONTEXT_SENSITIVE_HELP_BASE (client_help_root, internal_help_root) VALUES ('http://cr360.helpdocsonline.com/', 'http://emu.helpdocsonline.com/');
END;
/
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
VALUES (68, 'Set calc dependencies in dataview', 'Will insert all the dependencies of a supplied calculated indicator into the supplied dataview. Useful for s++ migrations.', 'SetCalcDependenciesInDataview', 'W3736');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
VALUES (68, 'Calc ind sid', 'The sid of the calculated indicator', 0);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
VALUES (68, 'Dataview sid', 'The sid of the dataview to set indicators in', 1);
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
VALUES (67, 'Create automated export for all data', '[Read the wiki!] Creates an automated export class with all indicators set into the dataview. Useful for s++ migrations.', 'CreateAllDataExport', 'W3736');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
VALUES (67, 'Export name', 'The name of the export class', 0);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
VALUES (67, 'Dataview sid', 'The sid of the dataview to set indicators in', 1);






@..\context_sensitive_help_pkg
@..\util_script_pkg


@..\region_body
@..\chain\company_filter_body
@..\indicator_body
@..\unit_test_body
@..\context_sensitive_help_body
@..\util_script_body
@..\enable_body
@..\automated_import_body



@update_tail
