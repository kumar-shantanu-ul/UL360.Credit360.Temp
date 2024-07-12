-- Please update version.sql too -- this keeps clean builds in sync
define version=3303
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- /csr/db/chain/create_views.sql
CREATE OR REPLACE VIEW chain.v$purchaser_involvement AS
	SELECT sit.flow_involvement_type_id, sr.supplier_company_sid
	  FROM supplier_relationship sr
	  JOIN company pc ON pc.company_sid = sr.purchaser_company_sid
	  LEFT JOIN csr.supplier ps ON ps.company_sid = pc.company_sid
	  JOIN company sc ON sc.company_sid = sr.supplier_company_sid
	  JOIN supplier_involvement_type sit
		ON (sit.user_company_type_id IS NULL OR sit.user_company_type_id = pc.company_type_id)
	   AND (sit.page_company_type_id IS NULL OR sit.page_company_type_id = sc.company_type_id)
	   AND (sit.purchaser_type = 1 /*chain_pkg.PURCHASER_TYPE_ANY*/
		OR (sit.purchaser_type = 2 /*chain_pkg.PURCHASER_TYPE_PRIMARY*/ AND sr.is_primary = 1)
		OR (sit.purchaser_type = 3 /*chain_pkg.PURCHASER_TYPE_OWNER*/ AND pc.company_sid = sc.parent_sid)
	   )
	  LEFT JOIN csr.region_role_member rrm
	    ON rrm.region_sid = ps.region_sid
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND rrm.role_sid = sit.restrict_to_role_sid
	 WHERE pc.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND pc.deleted = 0
	   AND sc.deleted = 0
	   AND sr.deleted = 0
	   AND (sit.restrict_to_role_sid IS NULL OR rrm.user_sid IS NOT NULL);

-- *** Data changes ***
-- RLS

-- Data

-- This was already done in latest3061_41, but was missed in basedata, so some installations may be missing this capability. The
-- proc is re-runnable, so no harm in running it everywhere, although this is mainly going to fix dev databases.
DECLARE
	PROCEDURE Temp_RegisterCapability (
		in_capability_type			IN  NUMBER,
		in_capability				IN  VARCHAR2, 
		in_perm_type				IN  NUMBER,
		in_is_supplier				IN  NUMBER DEFAULT 0
	)
	AS
		v_count						NUMBER(10);
		v_ct						NUMBER(10);
	BEGIN
		IF in_capability_type = 10 /*chain_pkg.CT_COMPANIES*/ THEN
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
BEGIN
	security.user_pkg.LogonAdmin;
	Temp_RegisterCapability(
		in_capability_type	=> 3,  															/* CT_ON_BEHALF_OF*/
		in_capability		=> 'Set primary purchaser in a relationship between A and B', 	/* SET_PRIMARY_PRCHSR */
		in_perm_type		=> 1, 															/* BOOLEAN_PERMISSION */
		in_is_supplier		=> 1
	);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
