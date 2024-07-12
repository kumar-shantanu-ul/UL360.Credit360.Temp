-- Please update version.sql too -- this keeps clean builds in sync
define version=2248
@update_header

CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.activated_dtm, c.active, c.address_1, 
		   c.address_2, c.address_3, c.address_4, c.town, c.state, pr.name state_name, c.state_id, c.city, pc.city_name, c.city_id, c.postcode, c.country_code, 
		   c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
		   ct.lookup_key company_type_lookup, c.supp_rel_code_label, c.supp_rel_code_label_mand,
		   c.parent_sid, p.name parent_name, p.country_code parent_country_code, pcou.name parent_company_name,
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
	 WHERE c.deleted = 0
;

CREATE OR REPLACE VIEW CHAIN.v$chain_user AS
	SELECT csru.app_sid, csru.csr_user_sid user_sid, csru.email, csru.user_name,   -- CSR_USER data
		   csru.full_name, csru.friendly_name, csru.phone_number, csru.job_title,   -- CSR_USER data
		   cu.visibility_id, cu.registration_status_id,								-- CHAIN_USER data
		   cu.receive_scheduled_alerts, cu.details_confirmed, ut.account_enabled
	  FROM csr.csr_user csru, chain_user cu, security.user_table ut
	 WHERE csru.app_sid = cu.app_sid
	   AND csru.csr_user_sid = cu.user_sid
	   AND cu.user_sid = ut.sid_id
	   AND cu.registration_status_id <> 2 -- not rejected 
	   AND cu.registration_status_id <> 3 -- not merged 
	   AND cu.deleted = 0
;

CREATE OR REPLACE VIEW CHAIN.v$company_user_group AS
	SELECT app_sid, company_sid, group_sid user_group_sid
	  FROM chain.company_group
	 WHERE company_group_type_id=2 -- users
	   AND group_sid IS NOT NULL
;

CREATE OR REPLACE VIEW CHAIN.v$company_pending_group AS
	SELECT app_sid, company_sid, group_sid pending_group_sid
	  FROM chain.company_group
	 WHERE company_group_type_id=3 -- pending users
	   AND group_sid IS NOT NULL
;  

CREATE OR REPLACE VIEW CHAIN.v$company_admin_group AS
	SELECT app_sid, company_sid, group_sid admin_group_sid
	  FROM chain.company_group
	 WHERE company_group_type_id=1 -- admins
	   AND group_sid IS NOT NULL
;

CREATE OR REPLACE VIEW CHAIN.v$company_user AS
  SELECT cug.app_sid, cug.company_sid, vcu.user_sid, vcu.email, vcu.user_name, 
		vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title,   
		vcu.visibility_id, vcu.registration_status_id, vcu.details_confirmed,
		vcu.account_enabled
    FROM v$company_user_group cug, v$chain_user vcu, security.group_members gm
   WHERE cug.app_sid = vcu.app_sid
     AND cug.user_group_sid = gm.group_sid_id
     AND vcu.user_sid = gm.member_sid_id
;

CREATE OR REPLACE VIEW CHAIN.v$company_pending_user AS        
  SELECT cpg.app_sid, cpg.company_sid, vcu.user_sid, vcu.email, vcu.user_name, 
		vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title,   
		vcu.visibility_id, vcu.registration_status_id, vcu.details_confirmed
    FROM v$company_pending_group cpg, v$chain_user vcu, security.group_members gm
   WHERE cpg.app_sid = vcu.app_sid
     AND cpg.pending_group_sid = gm.group_sid_id
     AND vcu.user_sid = gm.member_sid_id
;

CREATE OR REPLACE VIEW CHAIN.v$company_admin AS
  SELECT cag.app_sid, cag.company_sid, vcu.user_sid, vcu.email, vcu.user_name, 
		vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title,   
		vcu.visibility_id, vcu.registration_status_id, vcu.details_confirmed, vcu.account_enabled
    FROM v$company_admin_group cag, v$chain_user vcu, security.group_members gm
   WHERE cag.app_sid = vcu.app_sid
     AND cag.admin_group_sid = gm.group_sid_id
     AND vcu.user_sid = gm.member_sid_id
;



@update_tail
