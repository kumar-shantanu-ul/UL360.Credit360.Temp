-- Please update version.sql too -- this keeps clean builds in sync
define version=1154
@update_header



CREATE OR REPLACE VIEW SUPPLIER.v$questionnaire AS 
	SELECT 	q.questionnaire_id, q.class_name, q.friendly_name, q.description, q.active, q.package_name, 
			qg.group_id, qg.name, qg.workflow_type_id, qg.colour
	  FROM questionnaire q
	  JOIN questionnaire_group_membership qgm ON q.questionnaire_id = qgm.questionnaire_id	
	  JOIN questionnaire_group qg ON qgm.group_id = qg.group_id
	 WHERE qg.app_sid =  SYS_CONTEXT('SECURITY','APP')
;

-- HACK: not constrained this to the csr_user_sid table - as bootssupplier stuff predates app_sid - so would require a lot of propogation of app_sid's 
-- or an equal hack not having app_sid in primary key - don't feel this is worth it for non core code
DECLARE
	v_cnt	NUMBER(10);
BEGIN
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM all_tab_columns
	 WHERE owner = 'SUPPLIER' 
	   AND table_name = 'ALL_PRODUCT_QUESTIONNAIRE'
	   AND column_name ='LAST_SAVED_BY_SID';
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE SUPPLIER.ALL_PRODUCT_QUESTIONNAIRE ADD (LAST_SAVED_BY_SID NUMBER(10))';
	END IF;
	
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM all_tab_columns
	 WHERE owner = 'SUPPLIER' 
	   AND table_name = 'ALL_PRODUCT_QUESTIONNAIRE'
	   AND column_name ='LAST_SAVED_DTM';
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE SUPPLIER.ALL_PRODUCT_QUESTIONNAIRE ADD (LAST_SAVED_DTM DATE)';
	END IF;
END;
/


CREATE OR REPLACE VIEW SUPPLIER.PRODUCT_QUESTIONNAIRE
(PRODUCT_ID, QUESTIONNAIRE_ID, QUESTIONNAIRE_STATUS_ID, DUE_DATE, LAST_SAVED_BY_SID, LAST_SAVED_BY, LAST_SAVED_DTM) AS
SELECT PR.PRODUCT_ID, PR.QUESTIONNAIRE_ID, PR.QUESTIONNAIRE_STATUS_ID, PR.DUE_DATE, PR.LAST_SAVED_BY_SID, CU.FULL_NAME LAST_SAVED_BY, PR.LAST_SAVED_DTM
  FROM ALL_PRODUCT_QUESTIONNAIRE PR, CSR.CSR_USER CU
 WHERE PR.LAST_SAVED_BY_SID = CU.CSR_USER_SID (+)
   AND PR.USED = 1
;

-- Now look in the audit log and update the "last_saved_by" person for each questionnaire
DECLARE
    v_questionaire_id NUMBER;
BEGIN

    FOR a IN (
        select host from supplier.customer_options co, csr.customer c 
         WHERE co.app_sid = c.app_sid
           AND (host like '%boots%' OR host like 'bs.%')
    )
    LOOP
        security.user_pkg.logonadmin(a.host);
        
        DBMS_OUTPUT.PUT_LINE('======================='||a.host);
    
        FOR r IN (
            SELECT param_1, sub_object_id, user_sid, audit_date
              FROM (
                select param_1, sub_object_id, user_sid, audit_date, max(audit_date) OVER (partition by param_1, sub_object_id) max_audit_date
                  from csr.audit_log 
                 WHERE audit_type_id = 72
                   AND (((param_2 = 'Open') AND (param_3 = 'Closed')) OR ((param_2 = 'Closed') AND (param_3 = 'Open')))
                   AND description = '{0} changed from "{1}" to "{2}"'
                   AND app_sid = SYS_CONTEXT('security', 'app')
            )
            WHERE audit_date = max_audit_date
            ORDER BY  sub_object_id
       ) 
       LOOP

       
            SELECT questionnaire_id  
              INTO v_questionaire_id 
              FROM supplier.questionnaire 
             WHERE description = REPLACE(REPLACE(r.param_1, ' - Questionnaire state', ''), 'GT ', '')
               AND rownum=1;
           
           DBMS_OUTPUT.PUT_LINE('p='||r.sub_object_id||', q='||v_questionaire_id||', u='||r.user_sid||', d='||r.audit_date);
       
             UPDATE supplier.all_product_questionnaire p
                SET p.LAST_SAVED_BY_SID = r.user_sid, p.LAST_SAVED_DTM = r.audit_date
              WHERE p.PRODUCT_ID = r.sub_object_id
                AND p.QUESTIONNAIRE_ID = v_questionaire_id;
                
       END LOOP;
    
    END LOOP;


END;
/

-- rebuilds
@..\supplier\product_pkg
@..\supplier\product_body
@..\supplier\questionnaire_body
	
@update_tail

