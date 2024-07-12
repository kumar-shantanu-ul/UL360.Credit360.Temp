-- Please update version.sql too -- this keeps clean builds in sync
define version=2732
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD  (EDIT_COMPANY_USE_POSTCODE_DATA     NUMBER(1, 0)     DEFAULT 1 NOT NULL);

ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD  CONSTRAINT chk_edit_co_use_po_data CHECK (EDIT_COMPANY_USE_POSTCODE_DATA IN (0, 1));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
CREATE OR REPLACE VIEW CHAIN.v$company AS
  SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.activated_dtm, c.active, c.address_1,
		   c.address_2, c.address_3, c.address_4, c.town, c.state, 
		   CASE co.edit_company_use_postcode_data WHEN 1 THEN pr.name ELSE c.state END state_name,
		   c.state_id, c.city,
		   CASE co.edit_company_use_postcode_data WHEN 1 THEN pc.city_name ELSE c.city END city_name,
		   c.city_id, c.postcode, c.country_code,
		   c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid,
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required,
		   c.user_level_messaging, c.sector_id,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
		   ct.lookup_key company_type_lookup, c.supp_rel_code_label, c.supp_rel_code_label_mand,
		   c.parent_sid, p.name parent_name, p.country_code parent_country_code, pcou.name parent_country_name,
		   c.country_is_hidden, cs.region_sid
	  FROM company c
	  LEFT JOIN v$country cou ON c.country_code = cou.country_code
	  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
	  LEFT JOIN company_type ct ON c.company_type_id = ct.company_type_id
	  LEFT JOIN company p ON c.parent_sid = p.company_sid AND c.app_sid = p.app_sid
	  LEFT JOIN v$country pcou ON p.country_code = pcou.country_code
	  LEFT JOIN csr.supplier cs ON cs.company_sid = c.company_sid AND cs.app_sid = c.app_sid
	  LEFT JOIN postcode.city pc ON c.city_id = pc.city_id AND c.country_code = pc.country
	  LEFT JOIN postcode.region pr ON c.state_id = pr.region AND c.country_code = pr.country
	  LEFT JOIN customer_options co ON co.app_sid = p.app_sid
	 WHERE c.deleted = 0
;
-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CHAIN.CUSTOMER_OPTIONS_COLUMNS (column_name, description, show_in_admin_page) VALUES ('EDIT_COMPANY_USE_POSTCODE_DATA', 'Description of EDIT_COMPANY_USE_POSTCODE_DATA',1);

-- ** New package grants **

-- *** Packages ***
@..\chain\helper_body

@update_tail
