-- Please update version.sql too -- this keeps clean builds in sync
define version=1910
@update_header

/************** CHAIN PRODUCT/COMPONENT QUESTIONNAIRE SETUP ******************/

/*************************
GRANTS
************************/

GRANT SELECT ON csr.quick_survey TO chain;

/*************************
CHAIN SCHEMA CHANGES
************************/

BEGIN

	EXECUTE IMMEDIATE 'CREATE TABLE CHAIN.INVITATION_QNR_TYPE_COMPONENT(
    APP_SID                  NUMBER(10, 0)    DEFAULT SYS_CONTEXT(''SECURITY'', ''APP'') NOT NULL,
    INVITATION_ID            NUMBER(10, 0)    NOT NULL,
    QUESTIONNAIRE_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    COMPONENT_ID             NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK499 PRIMARY KEY (APP_SID, INVITATION_ID, QUESTIONNAIRE_TYPE_ID)
)';

EXECUTE IMMEDIATE 'ALTER TABLE CHAIN.INVITATION_QNR_TYPE_COMPONENT ADD CONSTRAINT RefCOMPONENT1218 
    FOREIGN KEY (APP_SID, COMPONENT_ID)
    REFERENCES CHAIN.COMPONENT(APP_SID, COMPONENT_ID)';

EXECUTE IMMEDIATE 'ALTER TABLE CHAIN.INVITATION_QNR_TYPE_COMPONENT ADD CONSTRAINT RefINVITATION_QNR_TYPE1219 
    FOREIGN KEY (APP_SID, INVITATION_ID, QUESTIONNAIRE_TYPE_ID)
    REFERENCES CHAIN.INVITATION_QNR_TYPE(APP_SID, INVITATION_ID, QUESTIONNAIRE_TYPE_ID)';
	
EXECUTE IMMEDIATE 'ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD PURCHASED_COMP_AUTO_MAP NUMBER(1,0)';
EXECUTE IMMEDIATE 'UPDATE CHAIN.CUSTOMER_OPTIONS SET PURCHASED_COMP_AUTO_MAP = 0';
EXECUTE IMMEDIATE 'ALTER TABLE CHAIN.CUSTOMER_OPTIONS MODIFY PURCHASED_COMP_AUTO_MAP NUMBER(1,0) DEFAULT 0 NOT NULL';

EXECUTE IMMEDIATE 'ALTER TABLE CHAIN.QUESTIONNAIRE ADD COMPONENT_ID NUMBER(10, 0) DEFAULT NULL';

	EXCEPTION 
		WHEN OTHERS THEN
			NULL;
END;
/

-- CREATE TABLE CHAIN.INVITATION_QNR_TYPE_COMPONENT(
    -- APP_SID                  NUMBER(10, 0)    DEFAULT SYS_CONTEXT(''SECURITY'', ''APP'') NOT NULL,
    -- INVITATION_ID            NUMBER(10, 0)    NOT NULL,
    -- QUESTIONNAIRE_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    -- COMPONENT_ID             NUMBER(10, 0)    NOT NULL,
    -- CONSTRAINT PK499 PRIMARY KEY (APP_SID, INVITATION_ID, QUESTIONNAIRE_TYPE_ID)
-- )
-- ;

-- ALTER TABLE CHAIN.INVITATION_QNR_TYPE_COMPONENT ADD CONSTRAINT RefCOMPONENT1218 
    -- FOREIGN KEY (APP_SID, COMPONENT_ID)
    -- REFERENCES CHAIN.COMPONENT(APP_SID, COMPONENT_ID)
-- ;

-- ALTER TABLE CHAIN.INVITATION_QNR_TYPE_COMPONENT ADD CONSTRAINT RefINVITATION_QNR_TYPE1219 
    -- FOREIGN KEY (APP_SID, INVITATION_ID, QUESTIONNAIRE_TYPE_ID)
    -- REFERENCES CHAIN.INVITATION_QNR_TYPE(APP_SID, INVITATION_ID, QUESTIONNAIRE_TYPE_ID)
-- ;


-- ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD PURCHASED_COMP_AUTO_MAP NUMBER(1,0);
-- UPDATE CHAIN.CUSTOMER_OPTIONS SET PURCHASED_COMP_AUTO_MAP = 0;
-- ALTER TABLE CHAIN.CUSTOMER_OPTIONS MODIFY PURCHASED_COMP_AUTO_MAP NUMBER(1,0) DEFAULT 0 NOT NULL;

-- ALTER TABLE CHAIN.QUESTIONNAIRE ADD COMPONENT_ID NUMBER(10, 0) DEFAULT NULL;


/***********************************************************************
	v$questionnaire - a view of all questionnaires with their current status ids exposed
***********************************************************************/

CREATE OR REPLACE VIEW CHAIN.v$questionnaire AS
	SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.component_id, q.questionnaire_type_id, q.created_dtm, 
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

/***********************************************************************
	v$questionnaire_share - a view of all supplier questionnaires by current status
***********************************************************************/

CREATE OR REPLACE VIEW CHAIN.v$questionnaire_share AS
	SELECT q.app_sid, q.questionnaire_id, q.component_id, q.questionnaire_type_id, q.created_dtm, qs.due_by_dtm, qs.overdue_events_sent,
		   qs.qnr_owner_company_sid, qs.share_with_company_sid, qsle.share_log_entry_index, qsle.entry_dtm, 
		   qs.questionnaire_share_id, qs.reminder_sent_dtm, qs.overdue_sent_dtm, qsle.share_status_id, ss.description share_status_name,
           qsle.company_sid entry_by_company_sid, qsle.user_sid entry_by_user_sid, qsle.user_notes
	  FROM questionnaire q, questionnaire_share qs, qnr_share_log_entry qsle, share_status ss, v$company s
	 WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND q.app_sid = qs.app_sid
	   AND q.app_sid = qsle.app_sid
	   AND q.company_sid = s.company_sid
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


/*************************
CSR SCHEMA CHANGES
************************/

BEGIN
EXECUTE IMMEDIATE 'ALTER TABLE CSR.SUPPLIER_SURVEY_RESPONSE ADD COMPONENT_ID NUMBER(10, 0)';
EXECUTE IMMEDIATE 'UPDATE CSR.SUPPLIER_SURVEY_RESPONSE SET COMPONENT_ID = 0';
EXECUTE IMMEDIATE 'ALTER TABLE CSR.SUPPLIER_SURVEY_RESPONSE MODIFY COMPONENT_ID NUMBER(10, 0) DEFAULT 0 NOT NULL';

EXECUTE IMMEDIATE 'ALTER TABLE CSR.SUPPLIER_SURVEY_RESPONSE DROP CONSTRAINT PK_SUPPLIER_SURVEY_RESPONSE';
EXECUTE IMMEDIATE 'ALTER TABLE CSR.SUPPLIER_SURVEY_RESPONSE ADD CONSTRAINT PK_SUPPLIER_SURVEY_RESPONSE PRIMARY KEY (APP_SID, SUPPLIER_SID, SURVEY_SID, COMPONENT_ID)';

EXECUTE IMMEDIATE 'ALTER TABLE CSR.QUICK_SURVEY DROP CONSTRAINT CHK_QUICK_SURVEY_AUDIENCE';
EXECUTE IMMEDIATE 'ALTER TABLE CSR.QUICK_SURVEY ADD CONSTRAINT CHK_QUICK_SURVEY_AUDIENCE CHECK (AUDIENCE IN (''everyone'',''existing'',''chain'', ''chain.product'',''audit'')) ENABLE NOVALIDATE';
	EXCEPTION 
		WHEN OTHERS THEN
			NULL;
END;
/
-- ALTER TABLE CSR.SUPPLIER_SURVEY_RESPONSE ADD COMPONENT_ID NUMBER(10, 0);
-- UPDATE CSR.SUPPLIER_SURVEY_RESPONSE SET COMPONENT_ID = 0;
-- ALTER TABLE CSR.SUPPLIER_SURVEY_RESPONSE MODIFY COMPONENT_ID NUMBER(10, 0) DEFAULT 0 NOT NULL;

-- ALTER TABLE CSR.SUPPLIER_SURVEY_RESPONSE DROP CONSTRAINT PK_SUPPLIER_SURVEY_RESPONSE
-- ALTER TABLE CSR.SUPPLIER_SURVEY_RESPONSE ADD CONSTRAINT PK_SUPPLIER_SURVEY_RESPONSE PRIMARY KEY (APP_SID, SUPPLIER_SID, SURVEY_SID, COMPONENT_ID)

-- ALTER TABLE CSR.QUICK_SURVEY DROP CONSTRAINT CHK_QUICK_SURVEY_AUDIENCE;
-- ALTER TABLE CSR.QUICK_SURVEY ADD CONSTRAINT CHK_QUICK_SURVEY_AUDIENCE CHECK (AUDIENCE IN ('everyone','existing','chain', 'chain.product','audit')) ENABLE NOVALIDATE;

/*************************
ADDED CHAIN BASEDATA
************************/
BEGIN

	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 320 /*COMPLETE_COMP_QUESTIONNAIRE*/, 2 /*SUPPLIER_MSG*/);

	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 321 /*COMP_QUESTIONNAIRE_SUBMITTED*/, 1 /*PURCHASER_MSG*/); 
  
  INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 321 /*COMP_QUESTIONNAIRE_SUBMITTED*/, 2 /*SUPPLIER_MSG*/);  
  
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 326 /*COMP_QNR_SUBMITTED_NO_REVIEW*/, 1 /*PURCHASER_MSG*/);  
  
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 324 /*COMP_QUESTIONNAIRE_REJECTED*/, 1 /*PURCHASER_MSG*/); 

	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 324 /*COMP_QUESTIONNAIRE_REJECTED*/, 2 /*SUPPLIER_MSG*/);
  
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 325 /*COMP_QUESTIONNAIRE_RETURNED*/, 1 /*PURCHASER_MSG*/);

	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 325 /*COMP_QUESTIONNAIRE_RETURNED*/, 2 /*SUPPLIER_MSG*/);   
  
	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 322 /*COMP_QUESTIONNAIRE_APPROVED*/, 1 /*PURCHASER_MSG*/);

	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 322 /*COMP_QUESTIONNAIRE_APPROVED*/, 2 /*SUPPLIER_MSG*/);

	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 323 /*COMP_QUESTIONNAIRE_OVERDUE*/, 1 /*PURCHASER_MSG*/);

	INSERT INTO chain.message_definition_lookup (message_definition_id, primary_lookup_id, secondary_lookup_id)
	VALUES (chain.message_definition_id_seq.nextval, 323 /*COMP_QUESTIONNAIRE_OVERDUE*/, 2 /*SUPPLIER_MSG*/);   
	
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
END;
/

/*************************
PACKAGE RECOMPILES
************************/

@..\chain\chain_pkg
@..\chain\helper_body

@..\chain\purchased_component_pkg
@..\chain\purchased_component_body

@..\chain\questionnaire_pkg
@..\chain\questionnaire_body

@..\chain\invitation_pkg
@..\chain\invitation_body

@..\quick_survey_pkg
@..\quick_survey_body
@..\supplier_body

@update_tail