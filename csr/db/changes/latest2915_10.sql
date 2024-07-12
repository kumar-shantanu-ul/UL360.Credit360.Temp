-- Please update version.sql too -- this keeps clean builds in sync
define version=2915
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE CHAIN.RISK_LEVEL (
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	RISK_LEVEL_ID					NUMBER(10, 0)	NOT NULL,
	LABEL							VARCHAR2(255)	NOT NULL,
	LOOKUP_KEY				 		VARCHAR2(255)	NULL,
	CONSTRAINT PK_RISK_LEVEL PRIMARY KEY (APP_SID, RISK_LEVEL_ID)
);

CREATE UNIQUE INDEX CHAIN.UK_RISK_LEVEL_LOOKUP_KEY ON CHAIN.RISK_LEVEL (APP_SID, NVL(UPPER(LOOKUP_KEY), TO_CHAR(RISK_LEVEL_ID)));

CREATE SEQUENCE  CHAIN.RISK_LEVEL_ID_SEQ  MINVALUE 1 MAXVALUE 999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE;

CREATE TABLE CHAIN.COUNTRY_RISK_LEVEL (
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	COUNTRY							VARCHAR2(2)		NOT NULL,
	RISK_LEVEL_ID					NUMBER(10, 0)	NOT NULL,
	START_DTM				 		DATE			NOT NULL,
	CONSTRAINT PK_COUNTRY_RISK_LEVEL PRIMARY KEY (APP_SID, COUNTRY, START_DTM),
	CONSTRAINT FK_RISK_LEVEL FOREIGN KEY (APP_SID, RISK_LEVEL_ID) REFERENCES CHAIN.RISK_LEVEL(APP_SID, RISK_LEVEL_ID),
	CONSTRAINT FK_COUNTRY FOREIGN KEY (COUNTRY) REFERENCES POSTCODE.COUNTRY (COUNTRY)
);



CREATE TABLE CSRIMP.CHAIN_RISK_LEVEL (
	CSRIMP_SESSION_ID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	RISK_LEVEL_ID					NUMBER(10, 0)	NOT NULL,
	LABEL							VARCHAR2(255)	NOT NULL,
	LOOKUP_KEY				 		VARCHAR2(255)	NULL,
	CONSTRAINT PK_CHAIN_RISK_LEVEL PRIMARY KEY (CSRIMP_SESSION_ID, RISK_LEVEL_ID),
	CONSTRAINT FK_CHAIN_RISK_LEVEL_SESSION FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE UNIQUE INDEX CSRIMP.UK_CHAIN_RISK_LVL_LKUP_KEY ON CSRIMP.CHAIN_RISK_LEVEL (CSRIMP_SESSION_ID, NVL(UPPER(LOOKUP_KEY), TO_CHAR(RISK_LEVEL_ID)));

CREATE TABLE CSRIMP.CHAIN_COUNTRY_RISK_LEVEL (
	CSRIMP_SESSION_ID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COUNTRY							VARCHAR2(2)		NOT NULL,
	RISK_LEVEL_ID					NUMBER(10, 0)	NOT NULL,
	START_DTM				 		DATE			NOT NULL,
	CONSTRAINT PK_CHAIN_COUNTRY_RISK_LEVEL PRIMARY KEY (CSRIMP_SESSION_ID, COUNTRY, START_DTM),
	CONSTRAINT FK_CHAIN_CNTRY_RSK_LVL_SESSION FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_RISK_LEVEL (
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_RISK_LEVEL_ID 				NUMBER(10) NOT NULL,
	NEW_RISK_LEVEL_ID 				NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_RISK_LEVEL PRIMARY KEY (CSRIMP_SESSION_ID, OLD_RISK_LEVEL_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_RISK_LEVEL_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables

ALTER TABLE CHAIN.CUSTOMER_OPTIONS
	ADD COUNTRY_RISK_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE CHAIN.CUSTOMER_OPTIONS
	ADD CONSTRAINT CHK_COUNTRY_RISK_ENABLED CHECK (COUNTRY_RISK_ENABLED IN (0, 1));

ALTER TABLE CSRIMP.CHAIN_CUSTOMER_OPTIONS
	ADD COUNTRY_RISK_ENABLED NUMBER(1) NOT NULL;

ALTER TABLE CSRIMP.ISSUE_CUSTOM_FIELD
	DROP CONSTRAINT CHK_ISS_CUST_FLD_TYP;

ALTER TABLE CSRIMP.ISSUE_CUSTOM_FIELD
	ADD CONSTRAINT CHK_ISS_CUST_FLD_TYP CHECK (FIELD_TYPE IN ('T', 'O', 'M', 'D'));

-- *** Grants ***
grant select, insert, update, delete on csrimp.chain_risk_level to web_user;
grant select, insert, update, delete on csrimp.chain_country_risk_level to web_user;
grant select, insert, update on chain.risk_level to csrimp;
grant select, insert, update on chain.country_risk_level to csrimp;
grant select on chain.risk_level_id_seq to csrimp;
grant select on chain.risk_level to csr;
grant select on chain.country_risk_level to csr;


-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	 VALUES (67, 'Country risk', 'EnableChainCountryRisk', 'Enables country risk.');


		 
		 
CREATE OR REPLACE PROCEDURE chain.Temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2, 
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER DEFAULT 0
)
AS
	v_count						NUMBER(10);
	v_ct						NUMBER(10);
BEGIN
	IF in_capability_type = 3 /*chain_pkg.CT_COMPANIES*/ THEN
		Temp_RegisterCapability(1 /*chain_pkg.CT_COMPANY*/, in_capability, in_perm_type);
		Temp_RegisterCapability(2 /*chain_pkg.CT_SUPPLIERS*/, in_capability, in_perm_type, 1);
		RETURN;	
	END IF;
	
	IF in_capability_type = 1 AND in_is_supplier <> 0 /* chain_pkg.IS_NOT_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Company capabilities cannot be supplier centric');
	ELSIF in_capability_type = 2 /* chain_pkg.CT_SUPPLIERS */ AND in_is_supplier <> 1 /* chain_pkg.IS_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Supplier capabilities must be supplier centric');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;
	
	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND (
			(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 0 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   		 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   	   );
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;
	
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);
	
END;
/

DECLARE 
	v_capability_id		NUMBER;
BEGIN
	chain.Temp_RegisterCapability(
		in_capability_type	=> 1,  								/* CT_COMPANY*/
		in_capability		=> 'View country risk levels' 		/* chain.chain_pkg.VIEW_COUNTRY_RISK_LEVELS */, 
		in_perm_type		=> 1, 								/* BOOLEAN_PERMISSION */
		in_is_supplier 		=> 0
	);
END;
/

DROP PROCEDURE chain.Temp_RegisterCapability;
		 
		 
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../schema_pkg
@../chain/chain_pkg
@../chain/helper_pkg

@../enable_body
@../schema_body
@../chain/chain_body
@../chain/company_body
@../chain/company_filter_body
@../chain/helper_body
@../chain/type_capability_body
@../csrimp/imp_body

@update_tail
