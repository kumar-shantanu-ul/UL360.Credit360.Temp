-- Please update version.sql too -- this keeps clean builds in sync
define version=2886
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.customer_options DROP CONSTRAINT chk_edit_co_use_po_data;
ALTER TABLE chain.customer_options DROP COLUMN edit_company_use_postcode_data;

CREATE UNIQUE INDEX csr.uk_ia_summary_response_id ON csr.internal_audit (
	CASE WHEN summary_response_id IS NOT NULL THEN app_sid END,
	summary_response_id
);

ALTER TABLE chain.company DROP CONSTRAINT chk_company_city;
ALTER TABLE chain.company DROP CONSTRAINT chk_company_state;

UPDATE chain.company c
   SET c.state = (
	SELECT r.name
	  FROM postcode.region r
	 WHERE r.region = c.state_id
	   AND r.country = c.country_code
	)
 WHERE c.state_id IS NOT NULL
   AND c.state IS NULL;

UPDATE chain.company c
   SET c.city = (
	SELECT r.city_name
	  FROM postcode.city r
	 WHERE r.city_id = c.city_id
	)
 WHERE c.city_id IS NOT NULL
   AND c.city IS NULL;

ALTER TABLE chain.company RENAME COLUMN city_id TO xxx_city_id;
ALTER TABLE chain.company RENAME COLUMN state_id TO xxx_state_id;

ALTER TABLE csrimp.chain_company DROP COLUMN city_id;
ALTER TABLE csrimp.chain_company DROP COLUMN state_id;



-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- ../chain/create_views.sql
CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.active, c.activated_dtm, c.deactivated_dtm,
		   c.address_1, c.address_2, c.address_3, c.address_4, c.state, c.city, c.postcode, c.country_code,
		   c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
		   ct.lookup_key company_type_lookup, ct.singular company_type_description, c.supp_rel_code_label, c.supp_rel_code_label_mand,
		   c.parent_sid, p.name parent_name, p.country_code parent_country_code, pcou.name parent_country_name,
		   c.country_is_hidden, cs.region_sid
	  FROM company c
	  JOIN customer_options co ON co.app_sid = c.app_sid
	  LEFT JOIN postcode.country cou ON c.country_code = cou.country
	  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
	  LEFT JOIN company_type ct ON c.company_type_id = ct.company_type_id
	  LEFT JOIN company p ON c.parent_sid = p.company_sid AND c.app_sid = p.app_sid
	  LEFT JOIN postcode.country pcou ON p.country_code = pcou.country
	  LEFT JOIN csr.supplier cs ON cs.company_sid = c.company_sid AND cs.app_sid = c.app_sid
	 WHERE c.deleted = 0
;

-- *** Data changes ***
-- RLS

-- Data

UPDATE chain.filter_page_column
   SET column_name = 'city'
 WHERE card_group_id = 23
   AND column_name = 'cityName';

UPDATE chain.filter_page_column
   SET column_name = 'state'
 WHERE card_group_id = 23
   AND column_name = 'stateName';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\chain\company_pkg
@..\chain\chain_pkg
@..\chain\invitation_pkg

@..\supplier_pkg

@..\chain\helper_body
@..\chain\company_filter_body
@..\chain\company_body
@..\chain\report_body
@..\chain\chain_body
@..\chain\invitation_body

@..\schema_body
@..\supplier_body
@..\region_body

@..\csrimp\imp_body

@../../../postcode/db/geo_region_pkg
@../../../postcode/db/geo_region_body


@update_tail
