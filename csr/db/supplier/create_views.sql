/* A couple of core views (COMPANY, PRODUCT, PRODUCT_QUESTIONNAIRE) are held in the ER/Studio schema
   and get CREATE OR REPLACEd in CREATE OR REPLACE_schema.sql. The reason for this is that they're really just exact copies
   of the core tables with simple checks in the WHERE clause for USED = 1, DELETED = 0 etc so it kind
   of makes sense to keep these alongside the underlying tables.
   
   [[ EXCEPT THEY'RE NOT BECAUSE THEY JOIN TO CSR SO NOW THEY LIVE IN HERE... (rk) ]]
   
   Other stuff should go in here.
 */

/*********************************************  V$CHAIN_USER  ********************************************/


-- 
-- VIEW: SUPPLIER.COMPANY 
--

CREATE OR REPLACE VIEW SUPPLIER.COMPANY
(COMPANY_SID, NAME, ADDRESS_1, ADDRESS_2, ADDRESS_3, ADDRESS_4, TOWN, STATE, POSTCODE, PHONE, PHONE_ALT, FAX, INTERNAL_SUPPLIER, ACTIVE, DELETED, COMPANY_STATUS_ID, COUNTRY_CODE, APP_SID) AS
SELECT AL.COMPANY_SID, AL.NAME, AL.ADDRESS_1, AL.ADDRESS_2, AL.ADDRESS_3, AL.ADDRESS_4, AL.TOWN, AL.STATE, AL.POSTCODE, AL.PHONE, AL.PHONE_ALT, AL.FAX, AL.INTERNAL_SUPPLIER, AL.ACTIVE, AL.DELETED, AL.COMPANY_STATUS_ID, AL.COUNTRY_CODE, AL.APP_SID
FROM ALL_COMPANY AL
WHERE DELETED = 0
;



-- 
-- VIEW: SUPPLIER.PRODUCT 
--

CREATE OR REPLACE VIEW SUPPLIER.PRODUCT
(PRODUCT_ID, PRODUCT_CODE, DESCRIPTION, SUPPLIER_COMPANY_SID, ACTIVE, DELETED, APP_SID) AS
SELECT AL.PRODUCT_ID, AL.PRODUCT_CODE, AL.DESCRIPTION, AL.SUPPLIER_COMPANY_SID, AL.ACTIVE, AL.DELETED, AL.APP_SID
FROM ALL_PRODUCT AL
WHERE DELETED = 0
;



CREATE OR REPLACE VIEW SUPPLIER.GT_PRODUCT AS 
SELECT p.*, gtp.gt_product_type_id, gtp.gt_product_type_group_id, 
       gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, hrs_used_per_month, mains_powered
  FROM product p, product_tag pt, gt_tag_product_type gtpt, gt_product_type gtp
 WHERE p.product_id = pt.product_id
   AND pt.tag_id = gtpt.tag_id
   AND gtpt.gt_product_type_id = gtp.gt_product_type_id;
   
-- 
-- VIEW: SUPPLIER.PRODUCT_QUESTIONNAIRE 
--

CREATE OR REPLACE VIEW SUPPLIER.PRODUCT_QUESTIONNAIRE
(PRODUCT_ID, QUESTIONNAIRE_ID, QUESTIONNAIRE_STATUS_ID, DUE_DATE, LAST_SAVED_BY_SID, LAST_SAVED_BY, LAST_SAVED_DTM) AS
SELECT PR.PRODUCT_ID, PR.QUESTIONNAIRE_ID, PR.QUESTIONNAIRE_STATUS_ID, PR.DUE_DATE, PR.LAST_SAVED_BY_SID, CU.FULL_NAME LAST_SAVED_BY, PR.LAST_SAVED_DTM
  FROM SUPPLIER.ALL_PRODUCT_QUESTIONNAIRE PR, CSR.CSR_USER CU
 WHERE PR.LAST_SAVED_BY_SID = CU.CSR_USER_SID (+)
   AND PR.USED = 1
;
	
	
-- user_fully_hidden = 0
-- user_hidden = 1
-- user_show_job_title = 2
-- user_show_name_and_job_title = 3
-- user_show_all = 4

CREATE OR REPLACE VIEW SUPPLIER.v$all_chain_user AS 
  SELECT cu.company_sid, csru.app_sid, csru.csr_user_sid, cu.pending_company_authorization, cu.user_profile_visibility_id,
    CASE 
        WHEN SYS_CONTEXT('SECURITY','SUPPLY_CHAIN_COMPANY') = cu.company_sid OR cu.user_profile_visibility_id >= 3 THEN full_name
    END full_name,
    CASE 
        WHEN SYS_CONTEXT('SECURITY','SUPPLY_CHAIN_COMPANY') = cu.company_sid OR cu.user_profile_visibility_id = 4 THEN email
    END email,
    CASE 
        WHEN SYS_CONTEXT('SECURITY','SUPPLY_CHAIN_COMPANY') = cu.company_sid OR cu.user_profile_visibility_id >= 2 THEN job_title
    END job_title,
    CASE 
        WHEN SYS_CONTEXT('SECURITY','SUPPLY_CHAIN_COMPANY') = cu.company_sid OR cu.user_profile_visibility_id = 4 THEN phone_number
    END phone_number
  FROM csr.csr_user csru, company_user cu
 WHERE csru.app_sid = SYS_CONTEXT('SECURITY','APP')
   AND csru.app_sid = cu.app_sid
   AND csru.csr_user_sid = cu.csr_user_sid
;
   
CREATE OR REPLACE VIEW SUPPLIER.v$chain_user AS 
  SELECT * 
    FROM v$all_chain_user
   WHERE (user_profile_visibility_id > 0
   			OR (SYS_CONTEXT('SECURITY','SUPPLY_CHAIN_COMPANY') = company_sid AND SYS_CONTEXT('SECURITY','SID') = csr_user_sid)
   	   )
;

/*********************************************************************************************************/

/***************************************  V$ALL_CONTACT / V$CONTACT ****************************************/
-- holds the merged contact data for the context application
CREATE OR REPLACE VIEW SUPPLIER.v$all_contact AS
    SELECT c.contact_id, c.contact_state_id, c.owner_company_sid, c.app_sid, c.contact_guid, 
    	   c.existing_company_sid, c.existing_user_sid, c.last_contact_state_update_dtm, c.registered_to_company_sid, registered_as_user_sid,
		   CASE WHEN c.existing_user_sid IS NULL THEN c.full_name ELSE vcu.full_name END full_name,
		   CASE WHEN c.existing_user_sid IS NULL THEN c.email ELSE vcu.email END email,
		   CASE WHEN c.existing_user_sid IS NULL THEN c.job_title ELSE vcu.job_title END job_title,
		   CASE WHEN c.existing_user_sid IS NULL THEN c.phone_number ELSE vcu.email END phone_number,	   
		   CASE WHEN c.existing_company_sid IS NULL THEN c.company_name ELSE cm.name END company_name,
		   CASE WHEN c.existing_company_sid IS NULL THEN c.address_1 ELSE cm.address_1 END address_1,
		   CASE WHEN c.existing_company_sid IS NULL THEN c.address_2 ELSE cm.address_2 END address_2,
		   CASE WHEN c.existing_company_sid IS NULL THEN c.address_3 ELSE cm.address_3 END address_3,
		   CASE WHEN c.existing_company_sid IS NULL THEN c.address_4 ELSE cm.address_4 END address_4,		   
		   CASE WHEN c.existing_company_sid IS NULL THEN c.town ELSE cm.town END town,
		   CASE WHEN c.existing_company_sid IS NULL THEN c.state ELSE cm.state END state,
		   CASE WHEN c.existing_company_sid IS NULL THEN c.postcode ELSE cm.postcode END postcode,
		   CASE WHEN c.existing_company_sid IS NULL THEN c.country_code ELSE cm.country_code END country_code,		   
		   CASE WHEN c.existing_company_sid IS NULL THEN c.estimated_annual_spend ELSE aps.estimated_annual_spend END estimated_annual_spend,
		   CASE WHEN c.existing_company_sid IS NULL THEN c.currency_code ELSE aps.currency_code END currency_code
	  FROM contact c, company cm, v$chain_user vcu, all_procurer_supplier aps   
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND c.existing_company_sid = cm.company_sid(+)
	   AND c.existing_user_sid = vcu.csr_user_sid(+)
	   AND c.owner_company_sid = aps.procurer_company_sid(+)
       AND c.existing_company_sid = aps.supplier_company_sid(+)
;

-- reduced view to filter only active contacts
CREATE OR REPLACE VIEW SUPPLIER.v$contact AS
	SELECT *
	  FROM v$all_contact
	 WHERE contact_state_id = 0 -- active
;

/*********************************************************************************************************/


/**********************************************  V$MESSAGE  **********************************************/


-- holds the prepared message data for the context application
CREATE OR REPLACE VIEW SUPPLIER.v$message AS
	-- Text only message --
	SELECT m.message_id, m.app_sid, m.msg_dtm, m.user_sid, m.company_sid, m.group_sid, mt.tpl, 
		   null param_0, null param_0_action,
		   null param_1, null param_1_action,
		   null param_2, null param_2_action
	  FROM message m, message_template mt, message_template_format mtf, company_user cu
	 WHERE mtf.message_template_format_id = 0 -- message_pkg.MTF_TEXT_ONLY --
	   AND mtf.message_template_format_id = mt.message_template_format_id
	   AND m.message_template_id = mt.message_template_id
	   AND m.company_sid = cu.company_sid
	   AND m.user_sid = cu.csr_user_sid
	   AND m.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND m.app_sid = cu.app_sid
UNION  
	-- Message in the format of {UserSid (Full name), CompanySid (Company name)} --
	SELECT m.message_id, m.app_sid, m.msg_dtm, m.user_sid, m.company_sid, m.group_sid, mt.tpl,  
		   NVL(vcu.full_name, vcu.job_title) param_0, '/csr/site/supplier/chain/UserProfile.acds?userSid='||mu.user_sid param_0_action,
		   c.name param_1, '/csr/site/supplier/chain/CompanyProfile.acds?companySid='||c.company_sid param_1_action,
		   null param_2, null param_2_action
	  FROM message m, message_template mt, message_template_format mtf, message_user mu, company c, v$all_chain_user vcu
	 WHERE mtf.message_template_format_id = 1 -- message_pkg.MTF_USER_COMPANY --
	   AND mtf.message_template_format_id = mt.message_template_format_id
	   AND m.message_template_id = mt.message_template_id
	   AND m.message_id = mu.message_id
	   AND c.company_sid = m.company_sid
	   AND vcu.csr_user_sid = mu.user_sid
	   AND m.app_sid = vcu.app_sid        
	   AND m.app_sid = mu.app_sid
	   AND m.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND mu.entry_index = 0
UNION
	-- Message in the format of {UserSid (Full name), UserSid (Full name), CompanySid (Company name)} --
	SELECT m.message_id, m.app_sid, m.msg_dtm, m.user_sid, m.company_sid, m.group_sid, mt.tpl, 
		   fmu.label param_0, '/csr/site/supplier/chain/UserProfile.acds?userSid='||fmu.user_sid param_0_action,
		   smu.label param_1, '/csr/site/supplier/chain/UserProfile.acds?userSid='||smu.user_sid param_1_action,
		   c.name param_2, '/csr/site/supplier/chain/CompanyProfile.acds?companySid='||c.company_sid param_2_action
	  FROM message m, message_template mt, message_template_format mtf, company c, 
		   (SELECT message_id, NVL(vcu.full_name, vcu.job_title) label, mu.user_sid, mu.app_sid 
			  FROM message_user mu, v$all_chain_user vcu
			 WHERE mu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND mu.user_sid = vcu.csr_user_sid(+)
			   AND mu.entry_index = 0) fmu, -- first message user --
		   (SELECT message_id, NVL(vcu.full_name, vcu.job_title) label, mu.user_sid, mu.app_sid 
			  FROM message_user mu, v$all_chain_user vcu
			 WHERE mu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND mu.user_sid = vcu.csr_user_sid(+)
			   AND mu.entry_index = 1) smu -- second message user --
	 WHERE mtf.message_template_format_id = 2 -- message_pkg.MTF_USER_USER_COMPANY --
	   AND mtf.message_template_format_id = mt.message_template_format_id
	   AND m.message_template_id = mt.message_template_id
	   AND m.message_id = fmu.message_id
	   AND m.message_id = smu.message_id
	   AND m.company_sid = c.company_sid
	   AND m.app_sid = fmu.app_sid
	   AND m.app_sid = smu.app_sid
	   AND m.app_sid = SYS_CONTEXT('SECURITY','APP')
UNION
	-- Message in the format of {UserSid (Full name), ContactId (Company name), QuestionnaireId (Friendly name)} --
	SELECT m.message_id, m.app_sid, m.msg_dtm, m.user_sid, m.company_sid, m.group_sid, mt.tpl,  
		   NVL(vcu.full_name, vcu.job_title) param_0, '/csr/site/supplier/chain/UserProfile.acds?userSid='||mu.user_sid param_0_action,
           c.company_name param_1, '/csr/site/supplier/chain/ContactProfile.acds?contactId='||c.contact_id param_1_action,
		   q.friendly_name param_2, '/csr/site/supplier/chain/ViewQuestionnaire.acds?questionnaireId='||q.chain_questionnaire_id param_2_action
	  FROM message m, message_template mt, message_template_format mtf, message_user mu, message_contact mc, message_questionnaire mq, 
           v$all_chain_user vcu, v$all_contact c, chain_questionnaire q
	 WHERE mtf.message_template_format_id = 3 -- message_pkg.MTF_USER_CONTACT_QNAIRE --
	   AND mtf.message_template_format_id = mt.message_template_format_id
	   AND m.message_template_id = mt.message_template_id
	   AND m.message_id = mu.message_id
       AND m.message_id = mc.message_id
       AND m.message_id = mq.message_id
	   AND vcu.csr_user_sid = mu.user_sid
	   AND vcu.company_sid = m.company_sid
	   AND mc.contact_id = c.contact_id(+)
       AND mq.chain_questionnaire_id = q.chain_questionnaire_id
       AND m.app_sid = vcu.app_sid        
	   AND m.app_sid = mu.app_sid
	   AND m.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND mu.entry_index = 0
UNION
	-- Message in the format of {UserSid (Full name), SupplierSid (Company name), QuestionnaireId (Friendly name)} --
	SELECT m.message_id, m.app_sid, m.msg_dtm, m.user_sid, m.company_sid, m.group_sid, mt.tpl,
		   NVL(vcu.full_name, vcu.job_title) param_0, '/csr/site/supplier/chain/UserProfile.acds?userSid='||mu.user_sid param_0_action,
		   c.name param_1, '/csr/site/supplier/chain/CompanyProfile.acds?companySid='||c.company_sid param_1_action,
		   q.friendly_name param_2, '/csr/site/supplier/chain/ViewQuestionnaire.acds?questionnaireId='||q.chain_questionnaire_id param_2_action
	  FROM message m, message_template mt, message_template_format mtf, message_user mu, message_procurer_supplier mps, 
		   message_questionnaire mq, v$all_chain_user vcu, chain_questionnaire q, all_company c
	 WHERE mtf.message_template_format_id = 4 -- message_pkg.MTF_USER_SUPPLIER_QNAIRE --
	   AND mtf.message_template_format_id = mt.message_template_format_id
	   AND m.message_template_id = mt.message_template_id
	   AND m.message_id = mu.message_id
	   AND m.message_id = mps.message_id
	   AND m.message_id = mq.message_id
	   AND vcu.csr_user_sid = mu.user_sid
	   AND vcu.company_sid = mps.procurer_company_sid
	   AND mps.procurer_company_sid = m.company_sid
	   AND mps.supplier_company_sid = c.company_sid
	   AND mq.chain_questionnaire_id = q.chain_questionnaire_id
	   AND m.app_sid = vcu.app_sid        
	   AND m.app_sid = mu.app_sid
	   AND m.app_sid = mps.app_sid
	   AND m.app_sid = c.app_sid
	   AND m.app_sid = mps.app_sid
	   AND m.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND mu.entry_index = 0
UNION
	-- Message in the format of {UserSid (Full name), ProcurerSid (Company name), QuestionnaireId (Friendly name)} --
	SELECT m.message_id, m.app_sid, m.msg_dtm, m.user_sid, m.company_sid, m.group_sid, mt.tpl,
		   NVL(vcu.full_name, vcu.job_title) param_0, '/csr/site/supplier/chain/UserProfile.acds?userSid='||mu.user_sid param_0_action,
		   c.name param_1, '/csr/site/supplier/chain/CompanyProfile.acds?companySid='||c.company_sid param_1_action,
		   q.friendly_name param_2, '/csr/site/supplier/chain/ViewQuestionnaire.acds?questionnaireId='||q.chain_questionnaire_id param_2_action
	  FROM message m, message_template mt, message_template_format mtf, message_user mu, message_procurer_supplier mps, 
		   message_questionnaire mq, v$all_chain_user vcu, chain_questionnaire q, all_company c
	 WHERE mtf.message_template_format_id = 5 -- message_pkg.MTF_USER_PROCURER_QNAIRE --
	   AND mtf.message_template_format_id = mt.message_template_format_id
	   AND m.message_template_id = mt.message_template_id
	   AND m.message_id = mu.message_id
	   AND m.message_id = mps.message_id
	   AND m.message_id = mq.message_id
	   AND vcu.csr_user_sid = mu.user_sid
	   AND vcu.company_sid = mps.supplier_company_sid
	   AND mps.procurer_company_sid = c.company_sid
	   AND mps.supplier_company_sid = m.company_sid
	   AND mq.chain_questionnaire_id = q.chain_questionnaire_id
	   AND m.app_sid = vcu.app_sid        
	   AND m.app_sid = mu.app_sid
	   AND m.app_sid = mps.app_sid
	   AND m.app_sid = c.app_sid
	   AND m.app_sid = mps.app_sid
	   AND m.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND mu.entry_index = 0
UNION
	 -- Message in the format of {SupplierSid (Company name), QuestionnaireId (Friendly name)} --
	 SELECT m.message_id, m.app_sid, m.msg_dtm, m.user_sid, m.company_sid, m.group_sid, mt.tpl,
		   c.name param_0, '/csr/site/supplier/chain/CompanyProfile.acds?companySid='||c.company_sid param_0_action,
		   q.friendly_name param_1, '/csr/site/supplier/chain/ViewQuestionnaire.acds?questionnaireId='||q.chain_questionnaire_id param_1_action,
		   null param_2, null param_2_action
	  FROM message m, message_template mt, message_template_format mtf, message_procurer_supplier mps, 
		   message_questionnaire mq, chain_questionnaire q, all_company c
	 WHERE mtf.message_template_format_id = 6 -- message_pkg.MTF_SUPPLIER_QNAIRE --
	   AND mtf.message_template_format_id = mt.message_template_format_id
	   AND m.message_template_id = mt.message_template_id
	   AND m.message_id = mps.message_id
	   AND m.message_id = mq.message_id
	   AND mps.supplier_company_sid = c.company_sid
	   AND mps.procurer_company_sid = m.company_sid
	   AND mq.chain_questionnaire_id = q.chain_questionnaire_id 
	   AND m.app_sid = mps.app_sid
	   AND m.app_sid = c.app_sid
	   AND m.app_sid = mps.app_sid
	   AND m.app_sid = SYS_CONTEXT('SECURITY','APP')
;
/*********************************************************************************************************/

/***************************************  V$COMPANY_QUESTIONNAIRE  ***************************************/

CREATE OR REPLACE VIEW SUPPLIER.v$company_questionnaire AS 
	SELECT 0 request_status_id, -1 response_status_id, i.app_sid, 
		   i.invite_id, c.owner_company_sid procurer_company_sid, 
		   i.sent_by_user_sid procurer_user_sid, pc.name procurer_company_name,
		   c.existing_company_sid supplier_company_sid, c.contact_id, 
		   null supplier_user_sid, c.company_name supplier_company_name,
		   iq.last_msg_dtm, iq.reminder_count, 
		   q.chain_questionnaire_id, q.friendly_name questionnaire_name, 
		   iq.due_dtm, i.creation_dtm, null accepted_dtm, 
		   q.edit_url, q.view_url, q.result_url, q.all_results_url, q.quick_survey_sid
	  FROM v$contact c, invite i, chain_questionnaire q, invite_questionnaire iq, 
			(SELECT * FROM company WHERE app_sid = SYS_CONTEXT('SECURITY','APP')) pc
	 WHERE i.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND i.app_sid = c.app_sid
	   AND i.app_sid = q.app_sid 
	   AND i.app_sid = iq.app_sid
	   AND i.sent_to_contact_id = c.contact_id
	   AND i.sent_by_company_sid = c.owner_company_sid
	   AND iq.last_msg_from_company_sid = c.owner_company_sid
	   AND i.sent_by_company_sid = pc.company_sid
	   AND i.invite_id = iq.invite_id
	   AND q.chain_questionnaire_id = iq.chain_questionnaire_id  
	   AND i.invite_status_id = 0
UNION ALL
	SELECT qr.request_status_id, cqr.response_status_id, qr.app_sid, 
			null invite_id, qr.procurer_company_sid, 
			qr.procurer_user_sid, pc.name procurer_company_name,
			qr.supplier_company_sid, null contact_id, 
			qr.supplier_user_sid, ac.name supplier_company_name,
			last_reminder_dtm last_msg_dtm, reminder_count, 
			qr.chain_questionnaire_id, q.friendly_name questionnaire_name, 
			qr.due_dtm, null creation_dtm, qr.accepted_dtm, 
			q.edit_url, q.view_url, q.result_url, q.all_results_url, q.quick_survey_sid
	  FROM questionnaire_request qr, chain_questionnaire q, all_company ac, company_questionnaire_response cqr,
			(SELECT * FROM company WHERE app_sid = SYS_CONTEXT('SECURITY','APP')) pc
	 WHERE qr.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND qr.app_sid = q.app_sid 
	   AND qr.app_sid = ac.app_sid
	   AND qr.app_sid = cqr.app_sid
	   AND qr.procurer_company_sid = pc.company_sid
	   AND qr.supplier_company_sid = ac.company_sid   
	   AND qr.supplier_company_sid = cqr.company_sid   
   	   AND qr.chain_questionnaire_id = q.chain_questionnaire_id
   	   AND qr.chain_questionnaire_id = cqr.chain_questionnaire_id
;

/*********************************************************************************************************/

/***************************************  V$QUESTIONNAIRE  ***************************************/

CREATE OR REPLACE VIEW SUPPLIER.v$questionnaire AS 
	SELECT 	q.questionnaire_id, q.class_name, q.friendly_name, q.description, q.active, q.package_name, 
			qg.group_id, qg.name, qg.workflow_type_id, qg.colour
	  FROM questionnaire q
	  JOIN questionnaire_group_membership qgm ON q.questionnaire_id = qgm.questionnaire_id	
	  JOIN questionnaire_group qg ON qgm.group_id = qg.group_id
	 WHERE qg.app_sid =  SYS_CONTEXT('SECURITY','APP')
;

/*********************************************************************************************************/