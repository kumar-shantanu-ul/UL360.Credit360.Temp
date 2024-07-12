-- Please update version.sql too -- this keeps clean builds in sync
define version=3182
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CHAIN.T_REF_PERM_ROW AS
  OBJECT (
	REFERENCE_ID				NUMBER(10),
	PRIMARY_COMPANY_TYPE_ID		NUMBER(10),
	SECONDARY_COMPANY_TYPE_ID	NUMBER(10),
	PERMISSION_SET				NUMBER(10)
  );
/

CREATE OR REPLACE TYPE CHAIN.T_REF_PERM_TABLE AS
  TABLE OF CHAIN.T_REF_PERM_ROW;
/

CREATE TABLE CHAIN.REFERENCE_CAPABILITY (
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	REFERENCE_ID					NUMBER(10, 0)	NOT NULL,
	PRIMARY_COMPANY_TYPE_ID			NUMBER(10, 0)	NOT NULL,
	PRIMARY_COMPANY_GROUP_TYPE_ID	NUMBER(10, 0),
	PRIMARY_COMPANY_TYPE_ROLE_SID	NUMBER(10, 0),
	SECONDARY_COMPANY_TYPE_ID		NUMBER(10, 0),
	PERMISSION_SET					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT CK_REF_CAP_ROLE_XOR CHECK (
		(PRIMARY_COMPANY_GROUP_TYPE_ID IS NOT NULL AND PRIMARY_COMPANY_TYPE_ROLE_SID IS NULL) OR
		(PRIMARY_COMPANY_GROUP_TYPE_ID IS NULL AND PRIMARY_COMPANY_TYPE_ROLE_SID IS NOT NULL)
	),
	CONSTRAINT FK_REF_CAP_REF FOREIGN KEY (APP_SID, REFERENCE_ID) REFERENCES CHAIN.REFERENCE (APP_SID, REFERENCE_ID),
	CONSTRAINT FK_REF_CAP_PRI_COMP_TYPE FOREIGN KEY (APP_SID, PRIMARY_COMPANY_TYPE_ID) REFERENCES CHAIN.COMPANY_TYPE (APP_SID, COMPANY_TYPE_ID),
	CONSTRAINT FK_REF_CAP_SEC_COMP_TYPE FOREIGN KEY (APP_SID, SECONDARY_COMPANY_TYPE_ID) REFERENCES CHAIN.COMPANY_TYPE (APP_SID, COMPANY_TYPE_ID),
	CONSTRAINT FK_REF_CAP_PRI_COMP_GRP FOREIGN KEY (PRIMARY_COMPANY_GROUP_TYPE_ID) REFERENCES CHAIN.COMPANY_GROUP_TYPE (COMPANY_GROUP_TYPE_ID)
);

CREATE INDEX CHAIN.IX_REF_CAP_REF ON CHAIN.REFERENCE_CAPABILITY (APP_SID, REFERENCE_ID);
CREATE INDEX CHAIN.IX_REF_CAP_PRI_COMP_TYPE ON CHAIN.REFERENCE_CAPABILITY (APP_SID, PRIMARY_COMPANY_TYPE_ID);
CREATE INDEX CHAIN.IX_REF_CAP_SEC_COMP_TYPE ON CHAIN.REFERENCE_CAPABILITY (APP_SID, SECONDARY_COMPANY_TYPE_ID);
CREATE INDEX CHAIN.IX_REF_CAP_PRI_COMP_GRP ON CHAIN.REFERENCE_CAPABILITY (PRIMARY_COMPANY_GROUP_TYPE_ID);
CREATE INDEX CHAIN.IX_REF_CAP_PRI_COMP_ROL ON CHAIN.REFERENCE_CAPABILITY (APP_SID, PRIMARY_COMPANY_TYPE_ROLE_SID);

CREATE UNIQUE INDEX CHAIN.UX_REFERENCE_CAPABILITY ON CHAIN.REFERENCE_CAPABILITY (
	APP_SID,
	REFERENCE_ID,
	PRIMARY_COMPANY_TYPE_ID,
	NVL2(PRIMARY_COMPANY_GROUP_TYPE_ID, 'CTG_' || PRIMARY_COMPANY_GROUP_TYPE_ID, 'CTR_' || PRIMARY_COMPANY_TYPE_ROLE_SID),
	NVL(SECONDARY_COMPANY_TYPE_ID, 0)
);

CREATE TABLE CSRIMP.CHAIN_REFERENCE_CAPABILITY (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	REFERENCE_ID					NUMBER(10, 0)	NOT NULL,
	PRIMARY_COMPANY_TYPE_ID			NUMBER(10, 0)	NOT NULL,
	PRIMARY_COMPANY_GROUP_TYPE_ID	NUMBER(10, 0),
	PRIMARY_COMPANY_TYPE_ROLE_SID	NUMBER(10, 0),
	SECONDARY_COMPANY_TYPE_ID		NUMBER(10, 0),
	PERMISSION_SET					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT FK_CHAIN_REF_CAP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE CHAIN.REFERENCE DROP CONSTRAINT FK_REF_AC_REF_PURCHASER;
DROP INDEX chain.ix_reference_purchaser_ref;

ALTER TABLE CHAIN.REFERENCE DROP CONSTRAINT FK_REF_AC_REF_SUPPLIER;
DROP INDEX chain.ix_reference_supplier_ref_;

DROP TABLE CHAIN.REFERENCE_ACCESS_LEVEL;

ALTER TABLE CHAIN.REFERENCE RENAME COLUMN supplier_ref_access_level_id TO xxx_supplier_lvl;
ALTER TABLE CHAIN.REFERENCE RENAME COLUMN purchaser_ref_access_level_id TO xxx_purchaser_lvl;

ALTER TABLE CSRIMP.CHAIN_REFERENCE DROP COLUMN supplier_ref_access_level_id;
ALTER TABLE CSRIMP.CHAIN_REFERENCE DROP COLUMN purchaser_ref_access_level_id;

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE ON CHAIN.REFERENCE_CAPABILITY TO CSR;
GRANT SELECT, INSERT, UPDATE ON CHAIN.REFERENCE_CAPABILITY TO CSRIMP;
GRANT SELECT, INSERT, UPDATE, DELETE ON CSRIMP.CHAIN_REFERENCE_CAPABILITY TO TOOL_USER;

-- ** Cross schema constraints ***
ALTER TABLE CHAIN.REFERENCE_CAPABILITY
	ADD CONSTRAINT FK_REF_CAP_PRI_COMP_ROL
	FOREIGN KEY (APP_SID, PRIMARY_COMPANY_TYPE_ROLE_SID)
	REFERENCES CSR.ROLE (APP_SID, ROLE_SID);

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_primary_cap_id		NUMBER;
	v_secondary_cap_id		NUMBER;
BEGIN
	SELECT capability_id
	  INTO v_primary_cap_id
	  FROM chain.capability
	 WHERE capability_name = 'Company';
	
	SELECT capability_id
	  INTO v_secondary_cap_id
	  FROM chain.capability
	 WHERE capability_name = 'Suppliers';

	security.user_pkg.logonadmin;
	FOR s IN (
		SELECT c.host, c.app_sid
		  FROM csr.customer c 
		 WHERE EXISTS (
			SELECT NULL FROM chain.reference WHERE app_sid = c.app_sid
		 )
	) LOOP
		security.user_pkg.logonadmin(s.host);
		
		FOR r IN (
			SELECT r.reference_id, r.xxx_supplier_lvl, r.xxx_purchaser_lvl,
				   rct.company_type_id
			  FROM chain.reference r
			  LEFT JOIN chain.reference_company_type rct ON rct.reference_id = r.reference_id
		) LOOP
			IF r.xxx_supplier_lvl > 0 THEN
				INSERT INTO chain.reference_capability
							(reference_id, primary_company_type_id,
							 primary_company_group_type_id, primary_company_type_role_sid,
							 secondary_company_type_id,
							 permission_set)
				SELECT r.reference_id, ctc.primary_company_type_id,
					   ctc.primary_company_group_type_id, ctc.primary_company_type_role_sid,
					   ctc.secondary_company_type_id,
					   LEAST(ctc.permission_set, CASE r.xxx_supplier_lvl
							WHEN 2 then 3
							ELSE 1
					   END)
				  FROM chain.company_type_capability ctc
				 WHERE ctc.capability_id = v_primary_cap_id 
				   AND NVL(r.company_type_id, ctc.primary_company_type_id) = ctc.primary_company_type_id
				   AND ctc.permission_set > 0;
			END IF;

			IF r.xxx_purchaser_lvl > 0 THEN
				INSERT INTO chain.reference_capability
							(reference_id, primary_company_type_id,
							 primary_company_group_type_id, primary_company_type_role_sid,
							 secondary_company_type_id,
							 permission_set)
				SELECT r.reference_id, ctc.primary_company_type_id,
					   ctc.primary_company_group_type_id, ctc.primary_company_type_role_sid,
					   ctc.secondary_company_type_id,
					   LEAST(ctc.permission_set, CASE r.xxx_purchaser_lvl
							WHEN 2 then 3
							ELSE 1
					   END)
				  FROM chain.company_type_capability ctc
				 WHERE ctc.capability_id = v_secondary_cap_id
				   AND NVL(r.company_type_id, ctc.secondary_company_type_id) = ctc.secondary_company_type_id
				   AND ctc.permission_set > 0;
			END IF;
		END LOOP;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/chain_pkg
@../chain/helper_pkg
@../schema_pkg

@../enable_body
@../chain/chain_body
@../chain/helper_body
@../chain/company_body
@../chain/business_rel_report_body
@../chain/company_filter_body
@../chain/higg_setup_body
@../csrimp/imp_body
@../schema_body

@update_tail
