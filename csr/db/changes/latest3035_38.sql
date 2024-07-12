-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=38
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.compliance_root_regions (
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	region_sid						NUMBER(10,0) NOT NULL,
	region_type						NUMBER(2,0) NOT NULL,
	CONSTRAINT pk_compliance_root_regions PRIMARY KEY (app_sid, region_sid, region_type)
);

CREATE INDEX csr.ix_crr_rt ON csr.compliance_root_regions (app_sid, region_type);

CREATE TABLE csr.enhesa_options (
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	client_id						VARCHAR2(1024) NOT NULL,
	username						VARCHAR2(1024) NOT NULL,
	password						VARCHAR2(1024) NOT NULL,
	last_success					DATE,	
	last_run						DATE,
	last_message					VARCHAR2(1024),
	next_run						DATE,
	CONSTRAINT pk_enhesa_options PRIMARY KEY (app_sid)
);

CREATE TABLE csrimp.compliance_root_regions (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	region_sid						NUMBER(10,0) NOT NULL,
	region_type						NUMBER(2,0) NOT NULL,
	CONSTRAINT pk_compliance_root_regions PRIMARY KEY (csrimp_session_id, region_sid, region_type),
	CONSTRAINT fk_compliance_root_regions
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) 
		ON DELETE CASCADE
);

CREATE TABLE csrimp.enhesa_options (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	client_id						VARCHAR2(1024) NOT NULL,
	username						VARCHAR2(1024) NOT NULL,
	password						VARCHAR2(1024) NOT NULL,
	last_success					DATE,	
	last_run						DATE,
	last_message					VARCHAR2(1024),
	next_run						DATE,
	CONSTRAINT pk_enhesa_options PRIMARY KEY (csrimp_session_id),
	CONSTRAINT fk_enhesa_options
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) 
		ON DELETE CASCADE
);

-- Alter tables

ALTER TABLE csr.compliance_root_regions ADD (
	CONSTRAINT fk_crr_r
		FOREIGN KEY (app_sid, region_sid)
		REFERENCES csr.region (app_sid, region_sid),
	CONSTRAINT fk_crr_crt
		FOREIGN KEY (app_sid, region_type)
		REFERENCES csr.customer_region_type (app_sid, region_type)
);

ALTER TABLE csr.compliance_item ADD (
	rollout_dtm						DATE,
	rollout_pending					NUMBER(1) DEFAULT 0 NOT NULL,
	lookup_key						VARCHAR2(1024),
	CONSTRAINT ck_rollout_pending CHECK (rollout_pending IN (0, 1))
);

CREATE UNIQUE INDEX csr.uk_ci_lookup_key ON csr.compliance_item (app_sid,NVL(lookup_key, compliance_item_id));

ALTER TABLE csr.compliance_options ADD (
	rollout_delay					NUMBER(5) DEFAULT 15 NOT NULL
);

ALTER TABLE csr.compliance_regulation ADD (
	external_id						NUMBER(10)
);

ALTER TABLE csrimp.compliance_item ADD (
	rollout_dtm						DATE,
	rollout_pending					NUMBER(1) NOT NULL,
	lookup_key						VARCHAR2(1024)
);

ALTER TABLE csrimp.compliance_options ADD (
	requirement_flow_sid			NUMBER(10) NOT NULL,
	regulation_flow_sid				NUMBER(10) NOT NULL,
	rollout_delay					NUMBER(5) NOT NULL
);

ALTER TABLE csrimp.compliance_regulation ADD (
	external_id						NUMBER(10)
);

CREATE OR REPLACE TYPE CSR.T_COMPLIANCE_ROLLOUT_ITEM AS
	OBJECT (
		COMPLIANCE_ITEM_ID			NUMBER(10),
		REGION_SID					NUMBER(10)
	);
/

CREATE OR REPLACE TYPE CSR.T_COMPLIANCE_ROLLOUT_TABLE AS
	TABLE OF CSR.T_COMPLIANCE_ROLLOUT_ITEM;
/

ALTER TABLE csr.compliance_item_change_type ADD (
	enhesa_id					NUMBER(10),
	CONSTRAINT CK_ENHESA_CT CHECK (enhesa_id IS NULL OR (enhesa_id IS NOT NULL AND SOURCE = 1))	
);

DROP INDEX csr.IX_CI_TITLE_SEARCH; 
DROP INDEX csr.IX_CI_CITATION_SEARCH;
DROP INDEX csr.IX_CI_SUMMARY_SEARCH;

ALTER TABLE csr.compliance_item MODIFY (
	title						VARCHAR2(1024),
	citation					VARCHAR2(4000),
	summary						VARCHAR2(4000)
);
grant create table to csr;

create index csr.IX_CI_TITLE_SEARCH on csr.compliance_item(title) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

create index csr.IX_CI_CITATION_SEARCH on csr.compliance_item(citation) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

create index csr.IX_CI_SUMMARY_SEARCH on csr.compliance_item(summary) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

create index csr.IX_CI_LOOKUP_SEARCH on csr.compliance_item(lookup_key) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

revoke create table from csr;

--It was created under with no schema so drop with no schema.
BEGIN
	EXECUTE IMMEDIATE 'DROP INDEX uk_compliance_item_ref';
EXCEPTION
	WHEN OTHERS THEN
		-- ORA-01418: specified index does not exist
		IF SQLCODE <> -1418 THEN
			RAISE;
		END IF;
END;
/

BEGIN
	EXECUTE IMMEDIATE 'DROP INDEX csr.uk_compliance_item_ref';
EXCEPTION
	WHEN OTHERS THEN
		-- ORA-01418: specified index does not exist
		IF SQLCODE <> -1418 THEN
			RAISE;
		END IF;
END;
/

BEGIN
	FOR r IN (
		SELECT 1
		  FROM all_constraints
		 WHERE constraint_name = 'UK_REFERENCE_CODE'
		   AND owner = 'CSR'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.compliance_item DROP CONSTRAINT UK_REFERENCE_CODE';
	END LOOP;
END;
/

CREATE UNIQUE INDEX csr.uk_compliance_item_ref ON csr.compliance_item (
	app_sid,
	decode(source, 0, NVL(reference_code, compliance_item_id), compliance_item_id)
);

-- *** Grants ***

-- ** Cross schema constraints ***

GRANT SELECT, INSERT, UPDATE ON csr.compliance_root_regions TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.enhesa_options TO csrimp;

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (80, 'in_client_id', 0, 'ENHESA client id');
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (80, 'in_username', 1, 'ENHESA username');

UPDATE csr.compliance_item_change_type SET enhesa_id = 0 WHERE compliance_item_change_type_id = 8;
UPDATE csr.compliance_item_change_type SET enhesa_id = 1 WHERE compliance_item_change_type_id = 9;
UPDATE csr.compliance_item_change_type SET enhesa_id = 3 WHERE compliance_item_change_type_id = 10;
UPDATE csr.compliance_item_change_type SET enhesa_id = 4 WHERE compliance_item_change_type_id = 11;
UPDATE csr.compliance_item_change_type SET enhesa_id = 5 WHERE compliance_item_change_type_id = 12;
UPDATE csr.compliance_item_change_type SET enhesa_id = 6 WHERE compliance_item_change_type_id = 13;
UPDATE csr.compliance_item_change_type SET enhesa_id = 7 WHERE compliance_item_change_type_id = 14;
			
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csrimp/imp_pkg
@../compliance_pkg
@../enable_pkg
@../schema_pkg

@../csrimp/imp_body
@../compliance_body
@../csr_app_body
@../enable_body
@../region_body
@../schema_body

@update_tail
