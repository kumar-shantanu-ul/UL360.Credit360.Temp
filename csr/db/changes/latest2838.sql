-- Please update version.sql too -- this keeps clean builds in sync
define version=2838
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Functions ***

-- *** Grants ***

-- ** Cross schema constraints ***

-- ** types **
DROP TYPE CHAIN.T_COMPANY_RELATIONSHIP_TABLE;

CREATE OR REPLACE TYPE CHAIN.T_COMPANY_RELATIONSHIP_ROW AS 
	OBJECT ( 
		COMPANY_SID					NUMBER(10),
		NAME						VARCHAR(1000),
		COUNTRY_NAME				VARCHAR(1000),
		ACTIVE_RELATIONSHIP			NUMBER(1),
		EDITABLE_RELATIONSHIP		NUMBER(1),--Based on capabilities
		COMPANY_TYPE_DESCRIPTION	VARCHAR(1000),
		RELATIONSHIP_ROLE			NUMBER(1), --1 SUPPLIER, 2 PURCHASER
		HAS_READ_PERMS_ON_COMPANY	NUMBER(1)
	);
/

CREATE OR REPLACE TYPE CHAIN.T_COMPANY_RELATIONSHIP_TABLE AS 
	TABLE OF CHAIN.T_COMPANY_RELATIONSHIP_ROW;
/

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

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
		in_capability_type	=> 1,  		/* CT_COMPANY*/
		in_capability	=> 'Company user' /* chain.chain_pkg.COMPANY_USER */, 
		in_perm_type	=> 0, 			/* SPECIFIC_PERMISSION */
		in_is_supplier 	=> 0
	);
	
	chain.Temp_RegisterCapability(
		in_capability_type	=> 2,  		/* CT_SUPPLIERS*/
		in_capability	=> 'Company user' /* chain.chain_pkg.COMPANY_USER */, 
		in_perm_type	=> 0, 			/* SPECIFIC_PERMISSION */
		in_is_supplier 	=> 1
	);
	
	--populate new capabilities based on the existing permission sets of COMPANY capability...
	SELECT capability_id
	  INTO v_capability_id
	  FROM chain.capability
	 WHERE capability_name = 'Company user'
	   AND is_supplier = 0
	   AND capability_type_id = 1;
	   
	INSERT INTO chain.company_type_capability (app_sid, primary_company_type_id, primary_company_group_type_id, secondary_company_type_id, tertiary_company_type_id,
		permission_set, capability_id, primary_company_type_role_sid)
	SELECT app_sid, primary_company_type_id, primary_company_group_type_id, secondary_company_type_id, tertiary_company_type_id,
		security.bitwise_pkg.bitor(bitand(permission_set, 1), bitand(permission_set, 2)), v_capability_id, primary_company_type_role_sid
	  FROM chain.company_type_capability
	 WHERE capability_id = (
		   SELECT capability_id
			 FROM chain.capability
			WHERE capability_name ='Company'
	);
	
	-- ...and SUPPLIER
	SELECT capability_id
	  INTO v_capability_id
	  FROM chain.capability
	 WHERE capability_name = 'Company user'
	   AND is_supplier = 1
	   AND capability_type_id = 2;
	   
	INSERT INTO chain.company_type_capability (app_sid, primary_company_type_id, primary_company_group_type_id, secondary_company_type_id, tertiary_company_type_id,
		permission_set, capability_id, primary_company_type_role_sid)
	SELECT app_sid, primary_company_type_id, primary_company_group_type_id, secondary_company_type_id, tertiary_company_type_id,
		security.bitwise_pkg.bitor(bitand(permission_set, 1), bitand(permission_set, 2)), v_capability_id, primary_company_type_role_sid
	  FROM chain.company_type_capability
	 WHERE capability_id = (
		   SELECT capability_id
			 FROM chain.capability
			WHERE capability_name = 'Suppliers'
	);
	
END;
/

DROP PROCEDURE chain.Temp_RegisterCapability;


-- ** New package grants **

-- *** Packages ***
@../chain/chain_pkg

@../chain/company_body
@../chain/company_user_body
@../chain/type_capability_body
@../chain/setup_body

@update_tail
