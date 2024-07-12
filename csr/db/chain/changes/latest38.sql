define version=38
@update_header

PROMPT >> Creating temporary table
CREATE GLOBAL TEMPORARY TABLE TT_QUESTIONNAIRE_LIST 
( 
	QUESTIONNAIRE_ID			NUMBER(10) NOT NULL,
	QUESTIONNAIRE_STATUS_ID		NUMBER(10) NOT NULL,
	QUESTIONNAIRE_STATUS_NAME	VARCHAR2(200) NOT NULL,
	STATUS_UPDATE_DTM			TIMESTAMP(6),
	POSITION					NUMBER(10)
) 
ON COMMIT PRESERVE ROWS; 

PROMPT >> Creating sequence(s)
CREATE SEQUENCE QUESTIONNAIRE_SHARE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

PROMPT >> Creating new tables
CREATE TABLE QNR_SHARE_LOG_ENTRY(
    APP_SID                   NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    SHARE_LOG_ENTRY_INDEX     NUMBER(10, 0)     NOT NULL,
    ENTRY_DTM                 TIMESTAMP(6)      DEFAULT SYSDATE NOT NULL,
    SHARE_STATUS_ID           NUMBER(10, 0)     NOT NULL,
    COMPANY_SID               NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') NOT NULL,
    USER_SID                  NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
    QUESTIONNAIRE_SHARE_ID    NUMBER(10, 0)     NOT NULL,
    USER_NOTES                VARCHAR2(4000),
    CONSTRAINT PK197 PRIMARY KEY (APP_SID, QUESTIONNAIRE_SHARE_ID, SHARE_LOG_ENTRY_INDEX)
)
;

CREATE TABLE QNR_STATUS_LOG_ENTRY(
    APP_SID                    NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    QUESTIONNAIRE_ID           NUMBER(10, 0)     NOT NULL,
    STATUS_LOG_ENTRY_INDEX     NUMBER(10, 0)     NOT NULL,
    ENTRY_DTM                  TIMESTAMP(6)      DEFAULT SYSDATE NOT NULL,
    QUESTIONNAIRE_STATUS_ID    NUMBER(10, 0)     NOT NULL,
    USER_SID                   NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
    USER_NOTES                 VARCHAR2(4000),
    CONSTRAINT PK196 PRIMARY KEY (APP_SID, QUESTIONNAIRE_ID, STATUS_LOG_ENTRY_INDEX)
)
;

CREATE TABLE QUESTIONNAIRE_SHARE(
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    QUESTIONNAIRE_SHARE_ID    NUMBER(10, 0)    NOT NULL,
    SHARE_WITH_COMPANY_SID    NUMBER(10, 0)    NOT NULL,
    QNR_OWNER_COMPANY_SID     NUMBER(10, 0)    NOT NULL,
    QUESTIONNAIRE_ID          NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK174 PRIMARY KEY (APP_SID, QUESTIONNAIRE_SHARE_ID),
    CONSTRAINT UC_RELATIONNSHIP_SHARE  UNIQUE (APP_SID, SHARE_WITH_COMPANY_SID, QNR_OWNER_COMPANY_SID, QUESTIONNAIRE_ID)
)
;

CREATE TABLE SHARE_STATUS(
    SHARE_STATUS_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION        VARCHAR2(200)    NOT NULL,
    CONSTRAINT PK173 PRIMARY KEY (SHARE_STATUS_ID)
)
;


PROMPT >> Altering existing tables
ALTER TABLE QUESTIONNAIRE_STATUS ADD (DESCRIPTION VARCHAR2(200));

ALTER TABLE QUESTIONNAIRE DROP CONSTRAINT RefQUESTIONNAIRE_STATUS44;

PROMPT >> Recompiling chain_pkg
@..\chain_pkg

PROMPT >> Redistributing existing questionnaire statuses to new design
DECLARE
	v_share_id		NUMBER(10);
	v_status_id		NUMBER(10);
BEGIN
	INSERT INTO share_status (share_status_id, description) VALUES (chain_pkg.NOT_SHARED, 'Not shared');
	INSERT INTO share_status (share_status_id, description) VALUES (chain_pkg.SHARING_DATA, 'Sharing data');
	INSERT INTO share_status (share_status_id, description) VALUES (chain_pkg.SHARED_DATA_RETURNED, 'Shared data returned');
	INSERT INTO share_status (share_status_id, description) VALUES (chain_pkg.SHARED_DATA_ACCEPTED, 'Shared data accepted');
	INSERT INTO share_status (share_status_id, description) VALUES (chain_pkg.SHARED_DATA_REJECTED, 'Shared data rejected');


	UPDATE questionnaire_status SET description = 'Entering data' WHERE questionnaire_status_id = chain_pkg.ENTERING_DATA;
	UPDATE questionnaire_status SET description = 'Reviewing data' WHERE questionnaire_status_id = chain_pkg.REVIEWING_DATA;
	UPDATE questionnaire_status SET description = 'Ready to share' WHERE questionnaire_status_id = chain_pkg.READY_TO_SHARE;

	FOR r IN (
		SELECT cu.host
		  FROM csr.customer cu, customer_options co
		 WHERE cu.app_sid = co.app_sid
	) LOOP

		user_pkg.logonadmin(r.host);

		chain_pkg.AddUserToChain(security_pkg.GetSid);

		-- set the status log entries (as best we can)
		FOR q IN (
			SELECT *
			  FROM questionnaire
			 WHERE app_sid = security_pkg.GetApp
		) LOOP
			
			-- create the initial log entry
			INSERT INTO qnr_status_log_entry
			(questionnaire_id, status_log_entry_index, entry_dtm, questionnaire_status_id)
			VALUES
			(q.questionnaire_id, 1, q.created_dtm, chain_pkg.ENTERING_DATA);

			-- if the questionnaire is shared, create the next level log entry
			IF q.questionnaire_status_id IN (questionnaire_pkg.Q_STATUS_SUBMITTED, questionnaire_pkg.Q_STATUS_REJECTED_PENDING, questionnaire_pkg.Q_STATUS_CLOSED_APPROVED, questionnaire_pkg.Q_STATUS_CLOSED_REJECTED) THEN
				
				INSERT INTO qnr_status_log_entry
				(questionnaire_id, status_log_entry_index, entry_dtm, questionnaire_status_id)
				VALUES
				(q.questionnaire_id, 2, q.status_update_dtm, 
					CASE 
					WHEN q.questionnaire_status_id = questionnaire_pkg.Q_STATUS_REJECTED_PENDING THEN chain_pkg.REVIEWING_DATA
					ELSE chain_pkg.READY_TO_SHARE
					END
				);
			
			END IF;
			
		END LOOP;
	
		-- set the share log entries (again, as best we can)
		FOR s IN (
			SELECT i.*, CASE WHEN i.share_status_id IN (chain_pkg.NOT_SHARED, chain_pkg.SHARING_DATA) THEN i.supplier_company_sid ELSE i.owner_company_sid END log_entry_by_company_sid
			  FROM (
				SELECT q.questionnaire_id, q.created_dtm, sr.owner_company_sid, sr.supplier_company_sid, q.status_update_dtm, 
					   CASE
						WHEN q.questionnaire_status_id IN (questionnaire_pkg.Q_STATUS_ASSIGNED, questionnaire_pkg.Q_STATUS_PENDING) THEN chain_pkg.NOT_SHARED
						WHEN q.questionnaire_status_id IN (questionnaire_pkg.Q_STATUS_SUBMITTED) THEN chain_pkg.SHARING_DATA
						WHEN q.questionnaire_status_id IN (questionnaire_pkg.Q_STATUS_REJECTED_PENDING) THEN chain_pkg.SHARED_DATA_RETURNED
						WHEN q.questionnaire_status_id IN (questionnaire_pkg.Q_STATUS_CLOSED_APPROVED) THEN chain_pkg.SHARED_DATA_ACCEPTED
						WHEN q.questionnaire_status_id IN (questionnaire_pkg.Q_STATUS_CLOSED_REJECTED) THEN chain_pkg.SHARED_DATA_REJECTED
					  END share_status_id
				  FROM v$supplier_relationship sr, questionnaire q
				 WHERE sr.app_sid = q.app_sid
				   AND sr.supplier_company_sid = q.company_sid
				  ) i

		) LOOP
		
			INSERT INTO questionnaire_share
			(questionnaire_share_id, questionnaire_id, share_with_company_sid, qnr_owner_company_sid)
			VALUES
			(questionnaire_share_id_seq.nextval, s.questionnaire_id, s.owner_company_sid, s.supplier_company_sid)
			RETURNING questionnaire_share_id INTO v_share_id;

			INSERT INTO qnr_share_log_entry
			(questionnaire_share_id, share_log_entry_index, entry_dtm, share_status_id, company_sid)
			VALUES
			(v_share_id, 1, s.created_dtm, chain_pkg.NOT_SHARED, s.supplier_company_sid);
			
			IF s.share_status_id <> chain_pkg.NOT_SHARED THEN
				INSERT INTO qnr_share_log_entry
				(questionnaire_share_id, share_log_entry_index, entry_dtm, share_status_id, company_sid)
				VALUES
				(v_share_id, 2, s.status_update_dtm, s.share_status_id, s.log_entry_by_company_sid);
			END IF;
		
		END LOOP;			  

		user_pkg.Logoff(security_pkg.GetAct);

	END LOOP;			
END;
/

DELETE FROM QUESTIONNAIRE_STATUS WHERE DESCRIPTION IS NULL;

commit;

PROMPT >> Fixing existing tables

ALTER TABLE QUESTIONNAIRE_STATUS MODIFY (DESCRIPTION NOT NULL);
ALTER TABLE QUESTIONNAIRE_STATUS DROP COLUMN STATUS_NAME;

ALTER TABLE QUESTIONNAIRE DROP COLUMN QUESTIONNAIRE_STATUS_ID;
ALTER TABLE QUESTIONNAIRE DROP COLUMN STATUS_UPDATE_DTM;


PROMPT >> Applying new fk contraints
-- 
-- TABLE: QUESTIONNAIRE_SHARE 
--

ALTER TABLE QUESTIONNAIRE_SHARE ADD CONSTRAINT RefSUPPLIER_RELATIONSHIP387 
    FOREIGN KEY (APP_SID, SHARE_WITH_COMPANY_SID, QNR_OWNER_COMPANY_SID)
    REFERENCES SUPPLIER_RELATIONSHIP(APP_SID, OWNER_COMPANY_SID, SUPPLIER_COMPANY_SID)
;

ALTER TABLE QUESTIONNAIRE_SHARE ADD CONSTRAINT RefQUESTIONNAIRE388 
    FOREIGN KEY (APP_SID, QUESTIONNAIRE_ID)
    REFERENCES QUESTIONNAIRE(APP_SID, QUESTIONNAIRE_ID)
;

ALTER TABLE QUESTIONNAIRE_SHARE ADD CONSTRAINT RefCUSTOMER_OPTIONS497 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER_OPTIONS(APP_SID)
;


-- 
-- TABLE: QNR_SHARE_LOG_ENTRY 
--

ALTER TABLE QNR_SHARE_LOG_ENTRY ADD CONSTRAINT RefCHAIN_USER485 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CHAIN_USER(APP_SID, USER_SID)
;

ALTER TABLE QNR_SHARE_LOG_ENTRY ADD CONSTRAINT RefCOMPANY486 
    FOREIGN KEY (APP_SID, COMPANY_SID)
    REFERENCES COMPANY(APP_SID, COMPANY_SID)
;

ALTER TABLE QNR_SHARE_LOG_ENTRY ADD CONSTRAINT RefSHARE_STATUS488 
    FOREIGN KEY (SHARE_STATUS_ID)
    REFERENCES SHARE_STATUS(SHARE_STATUS_ID)
;

ALTER TABLE QNR_SHARE_LOG_ENTRY ADD CONSTRAINT RefQUESTIONNAIRE_SHARE495 
    FOREIGN KEY (APP_SID, QUESTIONNAIRE_SHARE_ID)
    REFERENCES QUESTIONNAIRE_SHARE(APP_SID, QUESTIONNAIRE_SHARE_ID)
;



-- 
-- TABLE: QNR_STATUS_LOG_ENTRY 
--

ALTER TABLE QNR_STATUS_LOG_ENTRY ADD CONSTRAINT RefCHAIN_USER489 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CHAIN_USER(APP_SID, USER_SID)
;

ALTER TABLE QNR_STATUS_LOG_ENTRY ADD CONSTRAINT RefQUESTIONNAIRE_STATUS491 
    FOREIGN KEY (QUESTIONNAIRE_STATUS_ID)
    REFERENCES QUESTIONNAIRE_STATUS(QUESTIONNAIRE_STATUS_ID)
;

ALTER TABLE QNR_STATUS_LOG_ENTRY ADD CONSTRAINT RefQUESTIONNAIRE496 
    FOREIGN KEY (APP_SID, QUESTIONNAIRE_ID)
    REFERENCES QUESTIONNAIRE(APP_SID, QUESTIONNAIRE_ID)
;

PROMPT >> Creating new views

/************************************************************************
	NEW VIEWS
************************************************************************/

CREATE OR REPLACE VIEW v$questionnaire_status_log AS
  SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.questionnaire_type_id, q.created_dtm, q.due_by_dtm, qsle.status_log_entry_index, 
  		 qsle.entry_dtm, qsle.questionnaire_status_id, qs.description status_description, qsle.user_sid entry_by_user_sid, qsle.user_notes user_entry_notes
    FROM questionnaire q, qnr_status_log_entry qsle, questionnaire_status qs
   WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
     AND q.app_sid = qsle.app_sid
     AND q.questionnaire_id = qsle.questionnaire_id
     AND qs.questionnaire_status_id = qsle.questionnaire_status_id
   ORDER BY q.questionnaire_id, qsle.status_log_entry_index
;


CREATE OR REPLACE VIEW v$questionnaire_share_log AS
  SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.questionnaire_type_id, q.created_dtm, q.due_by_dtm,
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

CREATE OR REPLACE VIEW v$questionnaire AS
	SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.questionnaire_type_id, q.created_dtm, q.due_by_dtm, 
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

CREATE OR REPLACE VIEW v$questionnaire_share AS
	SELECT q.app_sid, q.questionnaire_id, q.questionnaire_type_id, q.created_dtm, q.due_by_dtm,
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



PROMPT >> Fixing existing views

/************************************************************************
	FIXED VIEWS
************************************************************************/

CREATE OR REPLACE VIEW v$event AS
	SELECT 
		e.app_sid,
		-- for company
		for_company_sid, c1.name for_company_name, et.for_company_url,
		-- for user
		for_user_sid, cu1.full_name for_user_full_name, cu1.friendly_name for_user_friendly_name, et.for_user_url,
		-- related company
		related_company_sid, c2.name related_company_name, et.related_company_url,
		-- related user
		related_user_sid, cu2.full_name related_user_full_name, cu2.friendly_name related_user_friendly_name, et.related_user_url,
		-- related questionnaire
		related_questionnaire_id, q.name related_questionnaire_name, et.related_questionnaire_url,
		-- other data
		e.event_id, e.created_dtm, 
		et.other_url_1, et.other_url_2, et.other_url_3, 
		-- event type
		et.event_type_id, message_template, priority,
		-- who is the event for
		NVL2(for_user_sid, cu1.full_name, c1.name) for_whom,
		NVL2(for_user_sid, 1, 0) is_for_user
	FROM 
		event e, event_type et, 
		csr.csr_user cu1, csr.csr_user cu2, 
		company c1, company c2,
		(
			SELECT q.app_sid, q.questionnaire_id, q.questionnaire_type_id, qt.name
			  FROM questionnaire q, questionnaire_type qt 
			 WHERE q.app_sid = qt.app_sid
			   AND q.questionnaire_type_id = qt.questionnaire_type_id
		) q
	WHERE e.app_sid = NVL(SYS_CONTEXT('SECURITY', 'APP'), e.app_sid)
	  --
	  AND e.app_sid = et.app_sid
	  AND e.event_type_id = et.event_type_id
	  --
	  AND e.app_sid = c1.app_sid
	  AND e.for_company_sid = c1.company_sid
	  --
	  AND e.app_sid = c2.app_sid(+)
	  AND e.related_company_sid = c2.company_sid(+)
	  --
	  AND e.app_sid = cu1.app_sid(+)
	  AND e.for_user_sid = cu1.csr_user_sid(+)
	  --
	  AND e.app_sid = cu2.app_sid(+)
	  AND e.related_user_sid = cu2.csr_user_sid(+)
	  --
	  AND e.app_sid = q.app_sid(+)
	  AND e.related_questionnaire_id = q.questionnaire_id(+)
;

CREATE OR REPLACE VIEW v$action AS
	SELECT
		a.app_sid,
		-- for company
		for_company_sid, c1.name for_company_name, at.for_company_url,
		-- for user
		for_user_sid, cu1.full_name for_user_full_name, cu1.friendly_name for_user_friendly_name, at.for_user_url,
		-- related company
		related_company_sid, c2.name related_company_name, at.related_company_url,
		-- related user
		related_user_sid, cu2.full_name related_user_full_name, cu2.friendly_name related_user_friendly_name, at.related_user_url,
		-- related questionnaire
		related_questionnaire_id, q.name related_questionnaire_name, 
		REPLACE(
			REPLACE(at.related_questionnaire_url,'{viewQuestionnaireUrl}',q.view_url), 
			'{editQuestionnaireUrl}', q.edit_url
		) related_questionnaire_url,
		-- other data
		action_id, A.created_dtm, due_date, is_complete, completion_dtm,
		at.other_url_1, at.other_url_2, at.other_url_3,
		-- reason for action
		ra.reason_for_action_id, reason_name reason_for_action_name, reason_description reason_for_action_description,
		-- to do - fill this in later
		-- action type
		at.action_type_id, message_template, priority,
		-- who is the action for
		NVL2(for_user_sid, cu1.full_name, c1.name) for_whom,
		NVL2(for_user_sid, 1, 0) is_for_user
	  FROM
		action a, action_type at, reason_for_action ra,
		csr.csr_user cu1, csr.csr_user cu2,
		company c1, company c2,
		(
			  SELECT q.app_sid, q.questionnaire_id, q.questionnaire_type_id, qt.name, qt.view_url, qt.edit_url
				FROM questionnaire q, questionnaire_type qt
			   WHERE q.app_sid = qt.app_sid
			     AND q.questionnaire_type_id = qt.questionnaire_type_id
		) q
	 WHERE a.app_sid = NVL(SYS_CONTEXT('SECURITY', 'APP'), a.app_sid)
	   --
	   AND a.app_sid = at.app_sid
	   AND ra.action_type_id = at.action_type_id
	   --
	   AND a.app_sid = ra.app_sid
	   AND a.reason_for_action_id = ra.reason_for_action_id
	   --
	   AND a.app_sid = c1.app_sid
	   AND a.for_company_sid = c1.company_sid
	   --	   
	   AND a.app_sid = c2.app_sid(+)
	   AND a.related_company_sid = c2.company_sid(+)
	   --
	   AND a.app_sid = cu1.app_sid(+)
	   AND a.for_user_sid = cu1.csr_user_sid(+)
	   --
	   AND a.app_sid = cu2.app_sid(+)
	   AND a.related_user_sid = cu2.csr_user_sid(+)
	   --
	   AND a.app_sid = q.app_sid(+)
	   AND a.related_questionnaire_id = q.questionnaire_id(+)
;



PROMPT >> Running rls
@..\rls

PROMPT >> Recompiling changed packages
@..\questionnaire_pkg

@..\action_body
@..\dashboard_body
@..\invitation_body
@..\questionnaire_body
@..\company_user_body

PROMPT >> Recompiling invalid packages
@..\..\..\..\aspen2\tools\recompile_packages.sql


PROMPT ****************************************************
PROMPT YOU NOW NEED TO UPDATE CLIENT PACKAGES
PROMPT (run these one at a time)
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT     
PROMPT cd ..\..\
PROMPT svn up supplier_pkg.sql
PROMPT svn up supplier_body.sql
PROMPT sqlplus csr/csr@&_CONNECT_IDENTIFIER
PROMPT @supplier_pkg
PROMPT @supplier_body
PROMPT exit
PROMPT cd..\..\
PROMPT     
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT     
PROMPT cd clients\maersk\db
PROMPT svn up
PROMPT sqlplus maersk/maersk@&_CONNECT_IDENTIFIER
PROMPT @build
PROMPT exit
PROMPT cd..\..\
PROMPT     
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT     
PROMPT cd HOMEDEPOT\db
PROMPT svn up
PROMPT sqlplus homedepot/homedepot@&_CONNECT_IDENTIFIER
PROMPT @build
PROMPT exit
PROMPT cd..\..\
PROMPT     
PROMPT ****************************************************

@update_tail

