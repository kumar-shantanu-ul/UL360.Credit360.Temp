alter table questionnaire add CONSTRAINT UNIQUE_COMPANY_QNR_TYPE  UNIQUE (APP_SID, COMPANY_SID, QUESTIONNAIRE_TYPE_ID);

@..\event_pkg

BEGIN
	INSERT INTO event_type 
		(app_sid, event_type_id, message_template, 
		priority, for_company_url, for_user_url, 
		related_company_url, related_user_url, related_questionnaire_url, 
		other_url_1, other_url_2, other_url_3, class)
	SELECT 
		app_sid, 10, 'Invitation from {forCompanyName} to {relatedUserFullName} of {relatedCompanyUrl} has expired', 
		5, null, null, 
		'<a href="/csr/site/chain/supplierDetails.acds?companySid={relatedCompanySid}">{relatedCompanyName}</a>', null, null, 
		null, null, null, event_pkg.EV_INVITATION_EXPIRED
	  FROM event_type
	 WHERE event_type_id = 1;
		
		
	INSERT INTO event_type 
		(app_sid, event_type_id, message_template, 
		priority, for_company_url, for_user_url, 
		related_company_url, related_user_url, related_questionnaire_url, 
		other_url_1, other_url_2, other_url_3, class)
	SELECT
		app_sid, 11, 'Questionnaire {relatedQuestionnaireUrl} for {relatedCompanyUrl} is overdue', 
		5, null, null, 
		'<a href="/csr/site/chain/supplierDetails.acds?companySid={relatedCompanySid}">{relatedCompanyName}</a>', null, related_questionnaire_url, 
		null, null, null, event_pkg.EV_QUESTIONNAIRE_OVERDUE
	  FROM event_type
	 WHERE class = event_pkg.EV_QUESTIONNAIRE_APPROVED; -- copy the related questionnaire url
	 
	 INSERT INTO event_type 
		(app_sid, event_type_id, message_template, 
		priority, for_company_url, for_user_url, 
		related_company_url, related_user_url, related_questionnaire_url, 
		other_url_1, other_url_2, other_url_3, class)
	SELECT
		app_sid, 12, 'Questionnaire {relatedQuestionnaireUrl} for {relatedCompanyName} is overdue', 
		5, null, null, 
		null, null, related_questionnaire_url, 
		null, null, null, event_pkg.EV_QUESTIONNAIRE_OVERDUE_SUP
	  FROM event_type
	 WHERE class = event_pkg.EV_QUESTIONNAIRE_APPROVED; -- copy the related questionnaire url
END;
/

/*************************************************************************************************/
ALTER TABLE QUESTIONNAIRE_SHARE ADD (
	DUE_BY_DTM 				DATE,
	OVERDUE_EVENTS_SENT 	NUMBER(1) DEFAULT 0 NOT NULL
);

BEGIN
	-- move the due_by_dtm column to the share table
	-- mark all questionnaires overdue by more than 2 days as events already sent so that we don't flood 
	UPDATE questionnaire_share qs
	   SET (qs.due_by_dtm, qs.overdue_events_sent) = (
	   		SELECT q.due_by_dtm, CASE WHEN q.due_by_dtm < SYSDATE - 2 THEN 1 ELSE 0 END
	   		  FROM questionnaire q
	   		 WHERE q.questionnaire_id = qs.questionnaire_id
	   	);
END;
/

ALTER TABLE QUESTIONNAIRE_SHARE MODIFY DUE_BY_DTM NOT NULL;
ALTER TABLE QUESTIONNAIRE DROP COLUMN DUE_BY_DTM;

CREATE GLOBAL TEMPORARY TABLE TT_QUESTIONNAIRE_ORGANIZER
( 
	QUESTIONNAIRE_ID			NUMBER(10) NOT NULL,
	QUESTIONNAIRE_STATUS_ID		NUMBER(10) NOT NULL,
	QUESTIONNAIRE_STATUS_NAME	VARCHAR2(200) NOT NULL,
	STATUS_UPDATE_DTM			TIMESTAMP(6),
	DUE_BY_DTM					DATE,
	POSITION					NUMBER(10)
) 
ON COMMIT PRESERVE ROWS; 


/*************************************************************************************************/
CREATE OR REPLACE VIEW v$questionnaire AS
	SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.questionnaire_type_id, q.created_dtm,
		   qt.view_url, qt.edit_url, qt.owner_can_review, qt.class, qt.name, qt.db_class, qt.group_name, qt.position, 
		   qsle.status_log_entry_index, qsle.questionnaire_status_id, qs.description questionnaire_status_name, qsle.entry_dtm status_update_dtm
	  FROM questionnaire q, questionnaire_type qt, qnr_status_log_entry qsle, questionnaire_status qs
	 WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND q.app_sid = qt.app_sid
	   AND q.app_sid = qsle.app_sid
       AND q.questionnaire_type_id = qt.questionnaire_type_id
       AND qsle.questionnaire_status_id = qs.questionnaire_status_id
       AND q.questionnaire_id = qsle.questionnaire_id
       AND (qsle.questionnaire_id, qsle.status_log_entry_index) IN (   
			SELECT questionnaire_id, MAX(status_log_entry_index)
			  FROM qnr_status_log_entry
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY questionnaire_id
			)
;
/*************************************************************************************************/
CREATE OR REPLACE VIEW v$questionnaire_status_log AS
  SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.questionnaire_type_id, q.created_dtm, qsle.status_log_entry_index, 
  		 qsle.entry_dtm, qsle.questionnaire_status_id, qs.description status_description, qsle.user_sid entry_by_user_sid, qsle.user_notes user_entry_notes
    FROM questionnaire q, qnr_status_log_entry qsle, questionnaire_status qs
   WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
     AND q.app_sid = qsle.app_sid
     AND q.questionnaire_id = qsle.questionnaire_id
     AND qs.questionnaire_status_id = qsle.questionnaire_status_id
   ORDER BY q.questionnaire_id, qsle.status_log_entry_index
;
/*************************************************************************************************/
CREATE OR REPLACE VIEW v$questionnaire_share AS
	SELECT q.app_sid, q.questionnaire_id, q.questionnaire_type_id, q.created_dtm, qs.due_by_dtm, qs.overdue_events_sent,
		   qs.qnr_owner_company_sid, qs.share_with_company_sid, qsle.share_log_entry_index, qsle.entry_dtm, 
		   qs.questionnaire_share_id, qsle.share_status_id, ss.description share_status_name,
           qsle.company_sid entry_by_company_sid, qsle.user_sid entry_by_user_sid, qsle.user_notes
	  FROM questionnaire q, questionnaire_share qs, qnr_share_log_entry qsle, share_status ss
	 WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND q.app_sid = qs.app_sid
	   AND q.app_sid = qsle.app_sid
	   AND q.company_sid = qs.qnr_owner_company_sid
	   AND (								-- allows builtin admin to see relationships as well for debugging purposes
	   			qs.share_with_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), qs.share_with_company_sid)
	   		 OR qs.qnr_owner_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), qs.qnr_owner_company_sid)
	   	   )
	   AND q.questionnaire_id = qs.questionnaire_id
	   AND qs.questionnaire_share_id = qsle.questionnaire_share_id
	   AND qsle.share_status_id = ss.share_status_id
	   AND (qsle.questionnaire_share_id, qsle.share_log_entry_index) IN (   
	   			SELECT questionnaire_share_id, MAX(share_log_entry_index)
	   			  FROM qnr_share_log_entry
	   			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   			 GROUP BY questionnaire_share_id
			)
;
/*************************************************************************************************/
CREATE OR REPLACE VIEW v$questionnaire_share_log AS
  SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.questionnaire_type_id, q.created_dtm, qs.due_by_dtm,
         qs.share_with_company_sid, qsle.share_log_entry_index, qsle.entry_dtm, qsle.share_status_id, 
         ss.description share_description, qsle.company_sid entry_by_company_sid, qsle.user_sid entry_by_user_sid, qsle.user_notes
    FROM questionnaire q, questionnaire_share qs, qnr_share_log_entry qsle, share_status ss
   WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
     AND q.app_sid = qs.app_sid
     AND q.app_sid = qsle.app_sid
     AND q.company_sid = qs.qnr_owner_company_sid
     AND q.questionnaire_id = qs.questionnaire_id
     AND qs.questionnaire_share_id = qsle.questionnaire_share_id
     AND qsle.share_status_id = ss.share_status_id
   ORDER BY q.questionnaire_id, qsle.share_log_entry_index
;
/*************************************************************************************************/

@..\action_pkg
@..\questionnaire_pkg

@..\action_body
@..\questionnaire_body
@..\company_user_body
@..\dashboard_body
@..\invitation_body
@..\scheduled_alert_body
