-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=26
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE CHAIN.CERTIFICATION_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

CREATE TABLE CHAIN.CERTIFICATION (
	APP_SID						NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CERTIFICATION_ID			NUMBER(10) NOT NULL,
	LABEL						VARCHAR2(1024) NOT NULL,
	LOOKUP_KEY					VARCHAR2(30),
	CONSTRAINT PK_CERTIFICATION PRIMARY KEY (APP_SID, CERTIFICATION_ID)
);

CREATE TABLE CHAIN.CERTIFICATION_AUDIT_TYPE (
	APP_SID						NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CERTIFICATION_ID			NUMBER(10) NOT NULL,
	INTERNAL_AUDIT_TYPE_ID		NUMBER(10) NOT NULL,
	CONSTRAINT PK_CERTIFICATION_AUDIT_TYPE PRIMARY KEY (APP_SID, CERTIFICATION_ID, INTERNAL_AUDIT_TYPE_ID),
	CONSTRAINT FK_CERT_AUDIT_TYPE_CERT FOREIGN KEY (APP_SID, CERTIFICATION_ID) REFERENCES CHAIN.CERTIFICATION(APP_SID, CERTIFICATION_ID)
);

CREATE TABLE CSRIMP.MAP_CHAIN_CERTIFICATION (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CERTIFICATION_ID		NUMBER(10) NOT NULL,
	NEW_CERTIFICATION_ID		NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_CERTIFICATION PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CERTIFICATION_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_CERTIFICATION UNIQUE (CSRIMP_SESSION_ID, NEW_CERTIFICATION_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_CERTIFICATION_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_CERTIFICATION (
	CSRIMP_SESSION_ID 			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CERTIFICATION_ID			NUMBER(10) NOT NULL,
	LABEL						VARCHAR2(1024) NOT NULL,
	LOOKUP_KEY					VARCHAR2(30),
	CONSTRAINT PK_CERTIFICATION PRIMARY KEY (CERTIFICATION_ID),
	CONSTRAINT FK_CERTIFICATION FOREIGN KEY
	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_CERT_AUD_TYPE (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CERTIFICATION_ID			NUMBER(10) NOT NULL,
	INTERNAL_AUDIT_TYPE_ID		NUMBER(10) NOT NULL,
	CONSTRAINT PK_CERTIFICATION_AUDIT_TYPE PRIMARY KEY (CERTIFICATION_ID, INTERNAL_AUDIT_TYPE_ID),
	CONSTRAINT FK_CERTIFICATION_AUDIT_TYPE FOREIGN KEY
	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
	ON DELETE CASCADE
);

-- Alter tables

-- *** Grants ***
grant select on chain.certification_id_seq to csrimp;
grant select on chain.certification to csr;
grant select on chain.certification_audit_type to csr;
grant select, insert, update on chain.certification to csrimp;
grant select, insert, update on chain.certification_audit_type to csrimp;

-- ** Cross schema constraints ***
ALTER TABLE CHAIN.CERTIFICATION_AUDIT_TYPE ADD CONSTRAINT FK_CERT_AUDIT_TYPE_AUDIT_TYPE 
	FOREIGN KEY (APP_SID, INTERNAL_AUDIT_TYPE_ID)
	REFERENCES CSR.INTERNAL_AUDIT_TYPE(APP_SID, INTERNAL_AUDIT_TYPE_ID)
;

CREATE INDEX CHAIN.IX_CERT_AUDIT_TYPE ON CHAIN.CERTIFICATION_AUDIT_TYPE (APP_SID, INTERNAL_AUDIT_TYPE_ID);
 
-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

--View from csr\db\chain\create_views.sql
CREATE OR REPLACE VIEW chain.v$supplier_certification AS
	SELECT cat.app_sid, cat.certification_id, ia.internal_audit_sid, s.company_sid, ia.internal_audit_type_id, ia.audit_dtm valid_from_dtm,
		   CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, add_months(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm 
			END expiry_dtm, atct.audit_closure_type_id 
	FROM chain.certification_audit_type cat 
	JOIN csr.internal_audit ia ON ia.internal_audit_type_id = cat.internal_audit_type_id
	 AND cat.app_sid = ia.app_sid
	 AND ia.deleted = 0
	JOIN csr.supplier s  ON ia.region_sid = s.region_sid AND s.app_sid = ia.app_sid
	JOIN csr.audit_type_closure_type atct ON ia.audit_closure_type_id = atct.audit_closure_type_id 
	 AND ia.internal_audit_type_id = atct.internal_audit_type_id
	 AND ia.app_sid = atct.app_sid
	JOIN csr.audit_closure_type act ON atct.audit_closure_type_id = act.audit_closure_type_id 
	 AND act.is_failure = 0
	 AND act.app_sid = atct.app_sid;

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
		in_capability_type	=> 1,  								/* CT_COMMON*/
		in_capability		=> 'View certifications' 		 	/* chain.chain_pkg.EDIT_OWN_FOLLOWER_STATUS */, 
		in_perm_type		=> 1, 								/* BOOLEAN_PERMISSION */
		in_is_supplier 		=> 0								/* chain_pkg.IS_SUPPLIER_CAPABILITY */
	);
	chain.Temp_RegisterCapability(
		in_capability_type	=> 2,  								/* CT_COMMON*/
		in_capability		=> 'View certifications' 			/* chain.chain_pkg.EDIT_OWN_FOLLOWER_STATUS */, 
		in_perm_type		=> 1, 								/* BOOLEAN_PERMISSION */
		in_is_supplier 		=> 1								/* chain_pkg.IS_SUPPLIER_CAPABILITY */
	);
END;
/
DROP PROCEDURE chain.Temp_RegisterCapability;

-- ** New package grants **
CREATE OR REPLACE PACKAGE chain.certification_pkg
IS
END certification_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.certification_pkg
IS
END certification_pkg;
/
grant execute on aspen2.t_split_numeric_table to chain;
grant execute on chain.certification_pkg to web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/chain_pkg
@../chain/company_filter_pkg
@../chain/certification_pkg
@../schema_pkg

@../chain/company_filter_body
@../chain/certification_body
@../schema_body 
@../csrimp/imp_body

@update_tail
