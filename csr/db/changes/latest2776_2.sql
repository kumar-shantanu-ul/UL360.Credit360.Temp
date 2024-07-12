-- Please update version.sql too -- this keeps clean builds in sync
define version=2776
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE cms.tab ADD parent_tab_sid NUMBER(10);
ALTER TABLE cms.tab ADD CONSTRAINT fk_parent_tab_sid
	FOREIGN KEY (app_sid, parent_tab_sid) REFERENCES cms.tab (app_sid, tab_sid);

ALTER TABLE cms.tab ADD CONSTRAINT chk_parent_tab_view
	CHECK ((is_view= 0 AND parent_tab_sid IS NULL) OR is_view = 1);

ALTER TABLE chain.company_tab ADD options VARCHAR2(255);

ALTER TABLE csrimp.cms_tab ADD parent_tab_sid NUMBER(10);
ALTER TABLE csrimp.chain_company_tab ADD options VARCHAR2(255);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.
--C:\cvs\csr\db\chain\create_views.sql
CREATE OR REPLACE VIEW CHAIN.v$questionnaire_type_status AS
	SELECT questionnaire_type_id, component_id, questionnaire_name, company_sid, status_id 
	  FROM (
		SELECT qt.questionnaire_type_id, qt.name questionnaire_name, qs.component_id, c.company_sid,
			CASE 
				WHEN qs.has_expired = 1 THEN 20	 					--SHARED_DATA_EXPIRED
				WHEN qs.share_status_id IN (14, 19) THEN 14 		--SHARED_DATA_ACCEPTED, SHARED_DATA_RESENT -> SHARED_DATA_ACCEPTED
				WHEN qs.share_status_id = 12 THEN 12 				--SHARING_DATA
				WHEN qs.share_status_id = 11 AND qs.due_by_dtm >= SYSDATE THEN 16	--NOT_SHARED -> NOT_SHARED_PENDING
				WHEN qs.share_status_id = 11 AND qs.due_by_dtm < SYSDATE THEN 17	--NOT_SHARED -> NOT_SHARED_OVERDUE
				WHEN qs.share_status_id = 13 THEN 13				--SHARED_DATA_RETURNED
				WHEN qs.share_status_id = 15 THEN 15				--SHARED_DATA_REJECTED
				WHEN i.invitation_status_id = 1 THEN 21				--ACTIVE-> QNR_INVITATION_NOT_ACCEPTED
				WHEN i.invitation_status_id = 5 THEN 16				--ACCEPTED-> NOT_SHARED_PENDING
				WHEN i.invitation_status_id IN (6,7,9,11,12) THEN 22 --REJECTED_NOT_EMPLOYEE, REJECTED_NOT_SUPPLIER, CANNOT_ACCEPT_TERMS, REJECTED_NOT_PARTNER, REJECTED_QNNAIRE_REQ-> QNR_INVITATION_DECLINED
				WHEN i.invitation_status_id = 2 THEN 23				--EXPIRED-> QNR_INVITATION_EXPIRED
				ELSE NULL
			END status_id
		  FROM company c
		  LEFT JOIN invitation i ON c.company_sid = i.to_company_sid
		  LEFT JOIN invitation_qnr_type iqt ON i.invitation_id = iqt.invitation_id
		  LEFT JOIN v$questionnaire_share qs 
			ON NVL(iqt.questionnaire_type_id, qs.questionnaire_type_id) = qs.questionnaire_type_id 
		   AND c.company_sid = qs.qnr_owner_company_sid 
		   AND (NVL(i.on_behalf_of_company_sid, i.from_company_sid) IS NULL OR qs.share_with_company_sid IN (i.on_behalf_of_company_sid, i.from_company_sid))
		  JOIN questionnaire_type qt ON NVL(iqt.questionnaire_type_id,qs.questionnaire_type_id) = qt.questionnaire_type_id
		 WHERE (qs.share_with_company_sid IS NULL OR qs.share_with_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
		   AND (NVL(i.on_behalf_of_company_sid, i.from_company_sid) IS NULL OR SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') IN (i.on_behalf_of_company_sid, i.from_company_sid))
	  ) 
	 WHERE status_id IS NOT NULL
	 GROUP BY questionnaire_type_id, component_id, questionnaire_name, company_sid, status_id;
-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../../../aspen2/cms/db/tab_pkg
@../flow_pkg
@../plugin_pkg
@../chain/plugin_pkg

@../../../aspen2/cms/db/tab_body
@../../../aspen2/cms/db/filter_body
@../schema_body
@../quick_survey_body
@../flow_body
@../plugin_body
@../chain/type_capability_body
@../chain/plugin_body

@update_tail
