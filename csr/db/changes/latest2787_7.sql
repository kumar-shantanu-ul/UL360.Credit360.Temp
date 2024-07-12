-- Please update version.sql too -- this keeps clean builds in sync
define version=2787
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

/* Updated chain.v$company */
CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.activated_dtm, c.active, c.address_1, 
		   c.address_2, c.address_3, c.address_4, c.town, c.state, 
		   NVL(pr.name, c.state) state_name, c.state_id, c.city, NVL(pc.city_name, c.city) city_name,
		   c.city_id, c.postcode, c.country_code,
		   c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
		   ct.lookup_key company_type_lookup, c.supp_rel_code_label, c.supp_rel_code_label_mand,
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

-- ** New package grants **

-- *** Packages ***

@update_tail
