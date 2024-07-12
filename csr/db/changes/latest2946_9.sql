-- Please update version.sql too -- this keeps clean builds in sync
define version=2946
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE CHEM.CHEM_OPTIONS (
	APP_SID						NUMBER(10, 0)	DEFAULT sys_context('SECURITY', 'APP') NOT NULL,
	CHEM_HELPER_PKG				VARCHAR(255),
	CONSTRAINT PK_CHEM_OPTIONS PRIMARY KEY (APP_SID)
);

CREATE TABLE CSRIMP.CHEM_CHEM_OPTIONS (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CHEM_HELPER_PKG				VARCHAR(255),
	CONSTRAINT PK_CHEM_OPTIONS PRIMARY KEY (CSRIMP_SESSION_ID),
	CONSTRAINT FK_CHEM_CHEM_OPTIONS_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHEM_CAS (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CAS_CODE VARCHAR2(50)		NOT NULL,
	NAME VARCHAR2(4000)			NOT NULL,
	UNCONFIRMED NUMBER(1)		NOT NULL,
	IS_VOC NUMBER(1)			NOT NULL,
	CATEGORY VARCHAR2(20),
	CONSTRAINT PK_CAS PRIMARY KEY (CSRIMP_SESSION_ID, CAS_CODE),
	CONSTRAINT FK_CHEM_CAS_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE OR REPLACE TYPE CHEM.T_CAS_COMP_ROW AS
	OBJECT (
		CAS_CODE				VARCHAR2(50),
		PCT_COMPOSITION 		NUMBER(5,4) 
	);
/
CREATE OR REPLACE TYPE CHEM.T_CAS_COMP_TABLE AS
	TABLE OF CHEM.T_CAS_COMP_ROW;
/


DROP TABLE chem.waiver;

-- Alter tables
ALTER TABLE chem.cas
ADD app_sid NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NULL;

ALTER TABLE chem.cas_restricted 
DROP CONSTRAINT fk_cas_cas_restr;

ALTER TABLE chem.substance_cas
DROP CONSTRAINT fk_cas_subst_cas;

ALTER TABLE chem.cas_group_member
DROP CONSTRAINT fk_cas_cas_grp_mbr;

ALTER TABLE chem.cas
DROP CONSTRAINT pk_cas DROP INDEX;

BEGIN
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM chem.substance_cas
		 UNION
		SELECT DISTINCT app_sid
		  FROM chem.cas_restricted	
		 UNION
		SELECT DISTINCT app_sid		  
		  FROM chem.cas_group_member		  
	)
	LOOP
		INSERT INTO chem.cas (app_sid, cas_code, name, unconfirmed, is_voc, category)
		     SELECT r.app_sid, cas_code, name, unconfirmed, is_voc, category
			   FROM chem.cas 
			  WHERE app_sid IS NULL;
	END LOOP;
	
	DELETE
	  FROM chem.cas
	 WHERE app_sid IS NULL;
	
END;
/


ALTER TABLE chem.cas
     MODIFY app_sid NOT NULL;

ALTER TABLE chem.cas
ADD CONSTRAINT pk_cas PRIMARY KEY (app_sid, cas_code);

ALTER TABLE chem.cas_restricted ADD CONSTRAINT fk_cas_cas_restr 
    FOREIGN KEY (app_sid, cas_code) REFERENCES chem.cas (app_sid, cas_code);
	
ALTER TABLE chem.substance_cas ADD CONSTRAINT fk_cas_subst_cas 
    FOREIGN KEY (app_sid, cas_code) REFERENCES chem.cas (app_sid, cas_code);

ALTER TABLE chem.cas_group_member ADD CONSTRAINT fk_cas_cas_grp_mbr 
    FOREIGN KEY (app_sid, cas_code) REFERENCES CHEM.CAS (app_sid, cas_code);	


-- *** Grants ***
GRANT SELECT, INSERT, UPDATE, DELETE ON chem.cas TO csr;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.chem_cas TO web_user;
GRANT SELECT, INSERT, UPDATE ON chem.cas TO csrimp;

GRANT SELECT, INSERT, UPDATE, DELETE ON chem.chem_options TO csr;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.chem_chem_options TO web_user;
GRANT SELECT, INSERT, UPDATE ON chem.chem_options TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../chem/substance_pkg
@../chem/substance_body
@../chem/audit_body
@../schema_pkg
@../schema_body 
@../csr_app_body
@../csrimp/imp_body

@update_tail
