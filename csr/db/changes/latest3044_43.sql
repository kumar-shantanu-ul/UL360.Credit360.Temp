-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=43
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE CHAIN.ALT_COMPANY_NAME_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

CREATE TABLE CHAIN.ALT_COMPANY_NAME(
	APP_SID							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ALT_COMPANY_NAME_ID				NUMBER(10) NOT NULL,
	COMPANY_SID						NUMBER(10) NOT NULL,
	NAME							VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_ALT_COMPANY_NAME PRIMARY KEY (APP_SID, ALT_COMPANY_NAME_ID),
	CONSTRAINT FK_ALT_COMP_NAME_COMPANY FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CHAIN.COMPANY (APP_SID, COMPANY_SID),
	CONSTRAINT UK_ALT_COMPANY_NAME UNIQUE (APP_SID, COMPANY_SID, NAME)
);

CREATE TABLE CSRIMP.MAP_CHAIN_ALT_COMPANY_NAME(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ALT_COMPANY_NAME_ID			NUMBER(10) NOT NULL,
	NEW_ALT_COMPANY_NAME_ID			NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_ALT_COMPANY_NAME PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ALT_COMPANY_NAME_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_ALT_COMPANY_NAME UNIQUE (CSRIMP_SESSION_ID, NEW_ALT_COMPANY_NAME_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_ALT_COMPANY_NAME FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_ALT_COMPANY_NAME(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ALT_COMPANY_NAME_ID				NUMBER(10) NOT NULL,
	COMPANY_SID						NUMBER(10) NOT NULL,
	NAME							VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_CHAIN_ALT_COMPANY_NAME PRIMARY KEY (ALT_COMPANY_NAME_ID),
	CONSTRAINT FK_CHAIN_ALT_COMPANY_NAME FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
-- Alter tables

create index chain.ix_alt_company_name on chain.alt_company_name (app_sid, company_sid);

-- *** Grants ***
grant select on chain.alt_company_name_id_seq to csrimp;
grant select on chain.alt_company_name to csr;
grant select, insert, update on chain.alt_company_name to csrimp;
grant select, insert, update, delete on csrimp.chain_alt_company_name to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

CREATE OR REPLACE PROCEDURE chain.Temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2, 
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER DEFAULT 0
)
AS
	v_count						NUMBER(10);
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
BEGIN
	chain.Temp_RegisterCapability(
		in_capability_type	=> 3,/*chain_pkg.CT_COMPANIES*/
		in_capability		=> 'Alternative company names',/*chain.chain_pkg.ALT_COMPANY_NAMES*/
		in_perm_type		=> 0/* chain.chain_pkg.SPECIFIC_PERMISSION */
	);
END;
/
DROP PROCEDURE chain.Temp_RegisterCapability;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../schema_pkg
@../schema_body 
@../csrimp/imp_body
@../chain/chain_pkg
@../chain/chain_body
@../chain/company_pkg
@../chain/company_body
@../chain/company_filter_body
@../csr_app_body
@../quick_survey_body

@update_tail
