-- Please update version.sql too -- this keeps clean builds in sync
define version=2154
@update_header

ALTER TABLE CHAIN.COMPANY ADD COUNTRY_IS_HIDDEN NUMBER(1, 0);
ALTER TABLE CHAIN.COMPANY ADD CONSTRAINT chk_co_country_is_hidden CHECK (COUNTRY_IS_HIDDEN IN (0, 1));
UPDATE chain.COMPANY SET country_is_hidden = 0;
ALTER TABLE CHAIN.COMPANY MODIFY COUNTRY_IS_HIDDEN DEFAULT 0 NOT NULL;

CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.activated_dtm, c.active, c.address_1, 
		   c.address_2, c.address_3, c.address_4, c.town, c.state, c.state_id, c.city, c.city_id, c.postcode, c.country_code, 
		   c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
		   ct.lookup_key company_type_lookup, c.supp_rel_code_label, c.supp_rel_code_label_mand,
		   c.parent_sid, p.name parent_name, p.country_code parent_country_code, pcou.name parent_company_name,
		   c.country_is_hidden
	  FROM company c
	  LEFT JOIN v$country cou ON c.country_code = cou.country_code
	  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
	  LEFT JOIN company_type ct ON c.company_type_id = ct.company_type_id
	  LEFT JOIN company p ON c.parent_sid = p.company_sid AND c.app_sid = p.app_sid
	  LEFT JOIN v$country pcou ON p.country_code = pcou.country_code
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.deleted = 0
;

@../chain/company_pkg 
@../chain/company_body 

@update_tail