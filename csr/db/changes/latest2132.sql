-- Please update version.sql too -- this keeps clean builds in sync
 define version=2132
 @update_header

ALTER TABLE chain.company ADD (
	email            VARCHAR2(255) DEFAULT NULL
);


CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.activated_dtm, c.active, c.address_1, 
		   c.address_2, c.address_3, c.address_4, c.town, c.state, c.state_id, c.city, c.city_id, c.postcode, c.country_code, 
		   c.phone, c.fax, c.email, c.website, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
		   ct.lookup_key company_type_lookup, supp_rel_code_label, supp_rel_code_label_mand
	  FROM company c
	  LEFT JOIN v$country cou ON c.country_code = cou.country_code
	  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
	  LEFT JOIN company_type ct ON c.company_type_id = ct.company_type_id
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.deleted = 0
;

@../chain/company_pkg
@../chain/company_body

@update_tail