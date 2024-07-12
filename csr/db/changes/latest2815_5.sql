-- Please update version.sql too -- this keeps clean builds in sync
define version=2815
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.company ADD (
	DEACTIVATED_DTM					DATE
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- .../chain/create_views.sql
CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.active, c.activated_dtm, c.deactivated_dtm,
		   c.address_1, c.address_2, c.address_3, c.address_4, c.town, c.state, 
		   NVL(pr.name, c.state) state_name, c.state_id, c.city, NVL(pc.city_name, c.city) city_name,
		   c.city_id, c.postcode, c.country_code,
		   c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
		   ct.lookup_key company_type_lookup, ct.singular company_type_description, c.supp_rel_code_label, c.supp_rel_code_label_mand,
		   c.parent_sid, p.name parent_name, p.country_code parent_country_code, pcou.name parent_country_name,
		   c.country_is_hidden, cs.region_sid
	  FROM company c
	  JOIN customer_options co ON co.app_sid = c.app_sid
	  LEFT JOIN v$country cou ON c.country_code = cou.country_code
	  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
	  LEFT JOIN company_type ct ON c.company_type_id = ct.company_type_id
	  LEFT JOIN company p ON c.parent_sid = p.company_sid AND c.app_sid = p.app_sid
	  LEFT JOIN v$country pcou ON p.country_code = pcou.country_code
	  LEFT JOIN csr.supplier cs ON cs.company_sid = c.company_sid AND cs.app_sid = c.app_sid
	  LEFT JOIN postcode.city pc ON c.city_id = pc.city_id AND c.country_code = pc.country
	  LEFT JOIN postcode.region pr ON c.state_id = pr.region AND c.country_code = pr.country
	 WHERE c.deleted = 0
;

-- *** Data changes ***
-- RLS

-- Data

CREATE OR REPLACE PROCEDURE chain.temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2,
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER
)
AS
	v_count						NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;

	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND (
				(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 1 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
			 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
		   );

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;

	INSERT INTO capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);

END;
/
-- New chain capabilities
BEGIN
	chain.temp_RegisterCapability(0 /*chain.chain_pkg.CT_COMMON*/, 'Deactivate company' /*chain.chain_pkg.DEACTIVATE_COMPANY*/, 1 /*chain.chain_pkg.BOOLEAN_PERMISSION*/, 1 /*chain.chain_pkg.IS_SUPPLIER_CAPABILITY*/);
END;
/

DROP PROCEDURE chain.temp_RegisterCapability;


-- ** New package grants **

-- *** Packages ***
@../chain/business_relationship_pkg
@../chain/chain_pkg
@../chain/chain_link_pkg
@../chain/company_pkg
@../chain/company_type_pkg
@../region_pkg
@../supplier_pkg

@../chain/activity_body
@../chain/business_relationship_body
@../chain/chain_link_body
@../chain/company_body
@../chain/company_filter_body
@../chain/company_type_body
@../region_body
@../supplier_body

@update_tail
