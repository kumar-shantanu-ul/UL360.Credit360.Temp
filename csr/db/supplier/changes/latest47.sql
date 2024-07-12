-- Please update version.sql too -- this keeps clean builds in sync
define version=47
@update_header
	
-- create an PRODUCT_QUESTIONNAIRE_APPROVER link table equivalent to the PRODUCT_QUESTIONNAIRE_PROVIDER link table

CREATE TABLE PRODUCT_QUESTIONNAIRE_APPROVER(
    PRODUCT_ID          NUMBER(10, 0)    NOT NULL,
    QUESTIONNAIRE_ID    NUMBER(10, 0)    NOT NULL,
    APPROVER_SID        NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK272 PRIMARY KEY (PRODUCT_ID, QUESTIONNAIRE_ID, APPROVER_SID)
);

INSERT INTO product_questionnaire_approver  
	(product_id, questionnaire_id, approver_sid)
SELECT product_id, questionnaire_id, approver_sid FROM product_questionnaire_link
	WHERE approver_sid IS NOT NULL;


-- remove the approver sid from the product
ALTER TABLE SUPPLIER.PRODUCT_QUESTIONNAIRE_LINK DROP COLUMN APPROVER_SID;

ALTER TABLE SUPPLIER.PRODUCT_QUESTIONNAIRE_LINK DROP COLUMN APPROVER_COMPANY_SID;


CREATE OR REPLACE VIEW PRODUCT_QUESTIONNAIRE
(PRODUCT_ID, QUESTIONNAIRE_ID, QUESTIONNAIRE_STATUS_ID,
 DUE_DATE)
AS 
SELECT PR.PRODUCT_ID, PR.QUESTIONNAIRE_ID, PR.QUESTIONNAIRE_STATUS_ID, DUE_DATE
FROM PRODUCT_QUESTIONNAIRE_LINK PR
WHERE USED = 1;
/

-- set stuff up that tells the site how to draw the overview page for diff groups and how they behave
INSERT INTO QUESTIONNAIRE_STATUS (QUESTIONNAIRE_STATUS_ID, STATUS) VALUES (-1, 'Not used');

CREATE TABLE WORKFLOW_TYPE(
    WORKFLOW_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION         VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK274 PRIMARY KEY (WORKFLOW_TYPE_ID)
);

ALTER TABLE SUPPLIER.QUESTIONNAIRE_GROUP
	ADD (WORKFLOW_TYPE_ID      NUMBER(10, 0)  DEFAULT 1   NOT NULL);
	
INSERT INTO SUPPLIER.WORKFLOW_TYPE (WORKFLOW_TYPE_ID, DESCRIPTION) VALUES (1 , 'Standard Workflow');
INSERT INTO SUPPLIER.WORKFLOW_TYPE (WORKFLOW_TYPE_ID, DESCRIPTION) VALUES (2 , 'Open Workflow');

ALTER TABLE QUESTIONNAIRE_GROUP ADD CONSTRAINT RefWORKFLOW_TYPE423 
    FOREIGN KEY (WORKFLOW_TYPE_ID)
    REFERENCES WORKFLOW_TYPE(WORKFLOW_TYPE_ID);
    
-- status on group not product
-- PRODUCT_QUESTIONNAIRE_GROUP and GROUP_STATUS
CREATE TABLE PRODUCT_QUESTIONNAIRE_GROUP(
    PRODUCT_ID                 NUMBER(10, 0)    NOT NULL,
    GROUP_ID                   NUMBER(10, 0)    NOT NULL,
    GROUP_STATUS_ID            NUMBER(10, 0)     DEFAULT 1 NOT NULL,
    DECLARATION_MADE_BY_SID    NUMBER(10, 0),
    STATUS_CHANGED_DTM         TIMESTAMP(6),
    CONSTRAINT PK276 PRIMARY KEY (PRODUCT_ID, GROUP_ID)
);

CREATE TABLE GROUP_STATUS(
    GROUP_STATUS_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION        VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK277 PRIMARY KEY (GROUP_STATUS_ID)
)
;

INSERT INTO SUPPLIER.GROUP_STATUS (GROUP_STATUS_ID, DESCRIPTION) VALUES (-1, 'Open Workflow');
INSERT INTO SUPPLIER.GROUP_STATUS (GROUP_STATUS_ID, DESCRIPTION) VALUES (1, 'Data being entered');
INSERT INTO SUPPLIER.GROUP_STATUS (GROUP_STATUS_ID, DESCRIPTION) VALUES (2, 'Submitted for approval');
INSERT INTO SUPPLIER.GROUP_STATUS (GROUP_STATUS_ID, DESCRIPTION) VALUES (3, 'Approved');
INSERT INTO SUPPLIER.GROUP_STATUS (GROUP_STATUS_ID, DESCRIPTION) VALUES (4, 'Data being reviewed');

ALTER TABLE PRODUCT_QUESTIONNAIRE_GROUP ADD CONSTRAINT RefQUESTIONNAIRE_GROUP432 
    FOREIGN KEY (GROUP_ID)
    REFERENCES QUESTIONNAIRE_GROUP(GROUP_ID)
;

ALTER TABLE PRODUCT_QUESTIONNAIRE_GROUP ADD CONSTRAINT RefGROUP_STATUS433 
    FOREIGN KEY (GROUP_STATUS_ID)
    REFERENCES GROUP_STATUS(GROUP_STATUS_ID)
;

ALTER TABLE PRODUCT_QUESTIONNAIRE_GROUP ADD CONSTRAINT RefALL_PRODUCT434 
    FOREIGN KEY (PRODUCT_ID)
    REFERENCES ALL_PRODUCT(PRODUCT_ID)
;


-- and update the product status data to the groups
INSERT INTO  PRODUCT_QUESTIONNAIRE_GROUP (product_id, group_id)
SELECT product_id,group_id
  FROM all_product p, questionnaire_group qg
WHERE qg.app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bootssupplier.credit360.com')
AND p.APP_SID  = (SELECT app_sid FROM csr.customer WHERE host = 'bootssupplier.credit360.com');

INSERT INTO  PRODUCT_QUESTIONNAIRE_GROUP (product_id, group_id)
SELECT product_id,group_id
  FROM all_product p, questionnaire_group qg
WHERE qg.app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bootstest.credit360.com')
AND p.APP_SID  = (SELECT app_sid FROM csr.customer WHERE host = 'bootstest.credit360.com');

INSERT INTO  PRODUCT_QUESTIONNAIRE_GROUP (product_id, group_id)
SELECT product_id,group_id
  FROM all_product p, questionnaire_group qg
WHERE qg.app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bs.credit360.com')
AND p.APP_SID  = (SELECT app_sid FROM csr.customer WHERE host = 'bs.credit360.com');

INSERT INTO  PRODUCT_QUESTIONNAIRE_GROUP (product_id, group_id)
SELECT product_id,group_id
  FROM all_product p, questionnaire_group qg
WHERE qg.app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bsstage.credit360.com')
AND p.APP_SID  = (SELECT app_sid FROM csr.customer WHERE host = 'bsstage.credit360.com');

BEGIN
    FOR r IN (select * from all_product where app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bootssupplier.credit360.com'))
    LOOP
        UPDATE PRODUCT_QUESTIONNAIRE_GROUP 
            SET 
            GROUP_STATUS_ID = r.product_status_id,
            declaration_made_by_sid = r.declaration_made_by_sid,
            status_changed_dtm = r.status_changed_dtm
        WHERE product_id = r.product_id
        AND group_id = 1;
    --    dbms_output.put_line(r.product_id);
    END LOOP;    
END;
/


BEGIN
    FOR r IN (select * from all_product where app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bootstest.credit360.com'))
    LOOP
        UPDATE PRODUCT_QUESTIONNAIRE_GROUP 
            SET 
            GROUP_STATUS_ID = r.product_status_id,
            declaration_made_by_sid = r.declaration_made_by_sid,
            status_changed_dtm = r.status_changed_dtm
        WHERE product_id = r.product_id
        AND group_id = 2;
       -- dbms_output.put_line(r.product_id);
    END LOOP;    
END;
/

BEGIN
    FOR r IN (select * from all_product where app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bs.credit360.com'))
    LOOP
        UPDATE PRODUCT_QUESTIONNAIRE_GROUP 
            SET 
            GROUP_STATUS_ID = r.product_status_id,
            declaration_made_by_sid = r.declaration_made_by_sid,
            status_changed_dtm = r.status_changed_dtm
        WHERE product_id = r.product_id
        AND group_id = 2;
       -- dbms_output.put_line(r.product_id);
    END LOOP;    
END;
/

BEGIN
    FOR r IN (select * from all_product where app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bsstage.credit360.com'))
    LOOP
        UPDATE PRODUCT_QUESTIONNAIRE_GROUP 
            SET 
            GROUP_STATUS_ID = r.product_status_id,
            declaration_made_by_sid = r.declaration_made_by_sid,
            status_changed_dtm = r.status_changed_dtm
        WHERE product_id = r.product_id
        AND group_id = 2;
       -- dbms_output.put_line(r.product_id);
    END LOOP;    
END;
/

@..\build

@update_tail
