--Please update version.sql too -- this keeps clean builds in sync
define version=2647
@update_header

ALTER TABLE CSR.AUDIT_CLOSURE_TYPE DROP CONSTRAINT CHK_CHK_DUE_AFTER_VALID;

ALTER TABLE CSR.AUDIT_CLOSURE_TYPE DROP CONSTRAINT CHK_DUE_AFTER_TYPE_VLD;

ALTER TABLE CSR.AUDIT_CLOSURE_TYPE DROP CONSTRAINT CHK_RPRTBLE_MNTHS_POS;

ALTER TABLE CSR.INTERNAL_AUDIT DROP CONSTRAINT FK_INT_AUD_CLSR_TYPE;

ALTER TABLE CSR.AUDIT_CLOSURE_TYPE DROP CONSTRAINT FK_AUDIT_CLSR_IAT;

--PK_AUDIT_CLOSURE_TYPE

ALTER TABLE CSR.AUDIT_CLOSURE_TYPE DROP PRIMARY KEY DROP INDEX;

ALTER TABLE CSR.AUDIT_CLOSURE_TYPE MODIFY (INTERNAL_AUDIT_TYPE_ID NUMBER(10) NULL);

CREATE TABLE CSR.AUDIT_TYPE_CLOSURE_TYPE(
    APP_SID                    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    INTERNAL_AUDIT_TYPE_ID     NUMBER(10, 0)    NOT NULL,
    AUDIT_CLOSURE_TYPE_ID      NUMBER(10, 0)    NOT NULL,
    RE_AUDIT_DUE_AFTER         NUMBER(10, 0),
    RE_AUDIT_DUE_AFTER_TYPE    CHAR(1),
    REMINDER_OFFSET_DAYS       NUMBER(10, 0),
    REPORTABLE_FOR_MONTHS      NUMBER(10, 0),
    CONSTRAINT CHK_CHK_DUE_AFTER_VALID CHECK ((RE_AUDIT_DUE_AFTER IS NULL AND RE_AUDIT_DUE_AFTER_TYPE IS NULL) OR (RE_AUDIT_DUE_AFTER IS NOT NULL AND RE_AUDIT_DUE_AFTER_TYPE IS NOT NULL)),
    CONSTRAINT CHK_DUE_AFTER_TYPE_VLD CHECK (RE_AUDIT_DUE_AFTER_TYPE IN ('d','w','m','y')),
    CONSTRAINT CHK_RPRTBLE_MNTHS_POS CHECK (REPORTABLE_FOR_MONTHS > 0),
    CONSTRAINT PK_AUDIT_TYPE_CLOSURE_TYPE PRIMARY KEY (APP_SID, INTERNAL_AUDIT_TYPE_ID, AUDIT_CLOSURE_TYPE_ID)
);

CREATE TABLE CSR.FB63770_AUDIT_CLOSURE_TYPE(
    APP_SID                		NUMBER(10, 0)    NOT NULL,
    AUDIT_CLOSURE_TYPE_ID 		NUMBER(10, 0)    NOT NULL,
    LABEL                  		VARCHAR2(255)    NOT NULL,
    ICON_IMAGE             		BLOB,
    ICON_IMAGE_FILENAME			VARCHAR2(255),
    ICON_IMAGE_MIME_TYPE		VARCHAR2(255),
	IS_FAILURE					NUMBER(1)	NOT NULL
);

DECLARE
	v_audit_closure_type_id	CSR.AUDIT_CLOSURE_TYPE.AUDIT_CLOSURE_TYPE_ID%TYPE;
BEGIN
	INSERT INTO CSR.AUDIT_TYPE_CLOSURE_TYPE (APP_SID, INTERNAL_AUDIT_TYPE_ID, AUDIT_CLOSURE_TYPE_ID, RE_AUDIT_DUE_AFTER, RE_AUDIT_DUE_AFTER_TYPE, REMINDER_OFFSET_DAYS, REPORTABLE_FOR_MONTHS)
	SELECT APP_SID, INTERNAL_AUDIT_TYPE_ID, AUDIT_CLOSURE_TYPE_ID, RE_AUDIT_DUE_AFTER, RE_AUDIT_DUE_AFTER_TYPE, REMINDER_OFFSET_DAYS, REPORTABLE_FOR_MONTHS
	  FROM CSR.AUDIT_CLOSURE_TYPE;
	
	FOR r IN (
		SELECT APP_SID, LABEL
		  FROM CSR.AUDIT_CLOSURE_TYPE
		 GROUP BY APP_SID, LABEL
	) LOOP
		v_audit_closure_type_id := NULL;
		
		FOR s IN (
			SELECT APP_SID, CSR.AUDIT_CLOSURE_TYPE_ID_SEQ.NEXTVAL AUDIT_CLOSURE_TYPE_ID, LABEL, ICON_IMAGE, ICON_IMAGE_FILENAME, ICON_IMAGE_MIME_TYPE, IS_FAILURE
			  FROM CSR.AUDIT_CLOSURE_TYPE
			 WHERE APP_SID = r.APP_SID
			   AND LABEL = r.LABEL
			   AND rownum = 1
		) LOOP
			INSERT INTO CSR.FB63770_AUDIT_CLOSURE_TYPE (APP_SID, AUDIT_CLOSURE_TYPE_ID, LABEL, ICON_IMAGE, ICON_IMAGE_FILENAME, ICON_IMAGE_MIME_TYPE, IS_FAILURE)
			VALUES (s.APP_SID, s.AUDIT_CLOSURE_TYPE_ID, s.LABEL, s.ICON_IMAGE, s.ICON_IMAGE_FILENAME, s.ICON_IMAGE_MIME_TYPE, s.IS_FAILURE)
		 RETURNING AUDIT_CLOSURE_TYPE_ID INTO v_audit_closure_type_id;
		END LOOP;
		
		UPDATE CSR.AUDIT_TYPE_CLOSURE_TYPE
		   SET AUDIT_CLOSURE_TYPE_ID = v_audit_closure_type_id
		 WHERE APP_SID = r.APP_SID
		   AND AUDIT_CLOSURE_TYPE_ID IN (
			SELECT AUDIT_CLOSURE_TYPE_ID
			  FROM CSR.AUDIT_CLOSURE_TYPE
			 WHERE APP_SID = r.APP_SID
			   AND LABEL = r.LABEL
		);
		
		UPDATE CSR.INTERNAL_AUDIT
		   SET AUDIT_CLOSURE_TYPE_ID = v_audit_closure_type_id
		 WHERE APP_SID = r.APP_SID
		   AND AUDIT_CLOSURE_TYPE_ID IN (
			SELECT AUDIT_CLOSURE_TYPE_ID
			  FROM CSR.AUDIT_CLOSURE_TYPE
			 WHERE APP_SID = r.APP_SID
			   AND LABEL = r.LABEL
		);
	END LOOP;
	
	DELETE FROM CSR.AUDIT_CLOSURE_TYPE;
	
	INSERT INTO CSR.AUDIT_CLOSURE_TYPE (APP_SID, AUDIT_CLOSURE_TYPE_ID, LABEL, ICON_IMAGE, ICON_IMAGE_FILENAME, ICON_IMAGE_MIME_TYPE, IS_FAILURE)
	SELECT APP_SID, AUDIT_CLOSURE_TYPE_ID, LABEL, ICON_IMAGE, ICON_IMAGE_FILENAME, ICON_IMAGE_MIME_TYPE, IS_FAILURE
	  FROM CSR.FB63770_AUDIT_CLOSURE_TYPE;
END;
/

ALTER TABLE CSR.AUDIT_CLOSURE_TYPE
DROP (INTERNAL_AUDIT_TYPE_ID, RE_AUDIT_DUE_AFTER, RE_AUDIT_DUE_AFTER_TYPE, REMINDER_OFFSET_DAYS, REPORTABLE_FOR_MONTHS);

ALTER TABLE CSR.AUDIT_CLOSURE_TYPE ADD CONSTRAINT PK_AUDIT_CLOSURE_TYPE PRIMARY KEY (APP_SID, AUDIT_CLOSURE_TYPE_ID);

ALTER TABLE CSR.AUDIT_TYPE_CLOSURE_TYPE ADD CONSTRAINT FK_AUDIT_TYPE_CLOSURE_TYPE
    FOREIGN KEY (APP_SID, AUDIT_CLOSURE_TYPE_ID)
    REFERENCES CSR.AUDIT_CLOSURE_TYPE(APP_SID, AUDIT_CLOSURE_TYPE_ID);

ALTER TABLE CSR.AUDIT_TYPE_CLOSURE_TYPE ADD CONSTRAINT FK_AUDIT_CLSR_IAT
    FOREIGN KEY (APP_SID, INTERNAL_AUDIT_TYPE_ID)
    REFERENCES CSR.INTERNAL_AUDIT_TYPE(APP_SID, INTERNAL_AUDIT_TYPE_ID);

ALTER TABLE CSR.INTERNAL_AUDIT ADD CONSTRAINT FK_INT_AUD_CLSR_TYPE
    FOREIGN KEY (APP_SID, INTERNAL_AUDIT_TYPE_ID, AUDIT_CLOSURE_TYPE_ID)
    REFERENCES CSR.AUDIT_TYPE_CLOSURE_TYPE(APP_SID, INTERNAL_AUDIT_TYPE_ID, AUDIT_CLOSURE_TYPE_ID);

CREATE UNIQUE INDEX CSR.UX_AUDIT_CLOSURE_TYPE_LABEL ON CSR.AUDIT_CLOSURE_TYPE (APP_SID, LABEL);

--DROP TABLE CSR.FB63770_AUDIT_CLOSURE_TYPE;

CREATE OR REPLACE VIEW csr.v$audit_validity AS
SELECT ia.internal_audit_sid, ia.internal_audit_type_id, ia.region_sid,
ia.audit_dtm previous_audit_dtm, act.audit_closure_type_id, ia.app_sid,
CASE (atct.re_audit_due_after_type)
	WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
	WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
	WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
	WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
END next_audit_due_dtm, atct.reminder_offset_days, act.label closure_label,
act.is_failure, ia.label previous_audit_label, act.icon_image_filename,
ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id
  FROM csr.internal_audit ia
  JOIN csr.audit_type_closure_type atct
	ON ia.internal_audit_type_id = atct.internal_audit_type_id
   AND ia.audit_closure_type_id = atct.audit_closure_type_id
   AND ia.app_sid = atct.app_sid
  JOIN csr.audit_closure_type act
	ON atct.audit_closure_type_id = act.audit_closure_type_id
   AND atct.app_sid = act.app_sid
 WHERE ia.deleted = 0;


CREATE OR REPLACE VIEW csr.v$audit_next_due AS
SELECT ia.internal_audit_sid, ia.internal_audit_type_id, ia.region_sid,
	   ia.audit_dtm previous_audit_dtm, act.audit_closure_type_id, ia.app_sid,
	   CASE (atct.re_audit_due_after_type)
			WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
			WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
			WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
			WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
	   END next_audit_due_dtm, atct.reminder_offset_days, act.label closure_label,
	   act.is_failure, ia.label previous_audit_label, act.icon_image_filename,
	   ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id
  FROM (
	SELECT internal_audit_sid, internal_audit_type_id, region_sid, audit_dtm,
		   ROW_NUMBER() OVER (
				PARTITION BY internal_audit_type_id, region_sid
				ORDER BY audit_dtm DESC) rn, -- take most recent audit of each type/region
		   audit_closure_type_id, app_sid, label, auditor_user_sid, flow_item_id, deleted, ovw_validity_dtm
	  FROM csr.internal_audit
	 WHERE deleted = 0
	   ) ia
  JOIN csr.audit_type_closure_type atct
	ON ia.internal_audit_type_id = atct.internal_audit_type_id
   AND ia.audit_closure_type_id = atct.audit_closure_type_id
   AND ia.app_sid = atct.app_sid
  JOIN csr.audit_closure_type act
	ON atct.audit_closure_type_id = act.audit_closure_type_id
   AND atct.app_sid = act.app_sid
  JOIN csr.region r ON ia.region_sid = r.region_sid AND ia.app_sid = r.app_sid
 WHERE rn = 1
   AND atct.re_audit_due_after IS NOT NULL
   AND r.active=1
   AND ia.audit_closure_type_id IS NOT NULL
   AND ia.deleted = 0;

--begin CSRIMP

grant insert on csr.audit_type_closure_type to csrimp;

ALTER TABLE CSRIMP.AUDIT_CLOSURE_TYPE DROP CONSTRAINT CHK_CHK_DUE_AFTER_VALID;
ALTER TABLE CSRIMP.AUDIT_CLOSURE_TYPE DROP CONSTRAINT CHK_DUE_AFTER_TYPE_VLD;
ALTER TABLE CSRIMP.AUDIT_CLOSURE_TYPE DROP CONSTRAINT CHK_RPRTBLE_MNTHS_POS;
ALTER TABLE CSRIMP.AUDIT_CLOSURE_TYPE DROP PRIMARY KEY DROP INDEX;

CREATE TABLE CSRIMP.AUDIT_TYPE_CLOSURE_TYPE(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    INTERNAL_AUDIT_TYPE_ID     NUMBER(10, 0)    NOT NULL,
    AUDIT_CLOSURE_TYPE_ID      NUMBER(10, 0)    NOT NULL,
    RE_AUDIT_DUE_AFTER         NUMBER(10, 0),
    RE_AUDIT_DUE_AFTER_TYPE    CHAR(1),
    REMINDER_OFFSET_DAYS       NUMBER(10, 0),
    REPORTABLE_FOR_MONTHS      NUMBER(10, 0),
    CONSTRAINT CHK_CHK_DUE_AFTER_VALID CHECK ((RE_AUDIT_DUE_AFTER IS NULL AND RE_AUDIT_DUE_AFTER_TYPE IS NULL) OR (RE_AUDIT_DUE_AFTER IS NOT NULL AND RE_AUDIT_DUE_AFTER_TYPE IS NOT NULL)),
    CONSTRAINT CHK_DUE_AFTER_TYPE_VLD CHECK (RE_AUDIT_DUE_AFTER_TYPE IN ('d','w','m','y')),
    CONSTRAINT CHK_RPRTBLE_MNTHS_POS CHECK (REPORTABLE_FOR_MONTHS > 0),
    CONSTRAINT PK_AUDIT_TYPE_CLOSURE_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, INTERNAL_AUDIT_TYPE_ID, AUDIT_CLOSURE_TYPE_ID),
    CONSTRAINT FK_AUDIT_TYPE_CLOSURE_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
)
;

ALTER TABLE CSRIMP.AUDIT_CLOSURE_TYPE
DROP (INTERNAL_AUDIT_TYPE_ID, RE_AUDIT_DUE_AFTER, RE_AUDIT_DUE_AFTER_TYPE, REMINDER_OFFSET_DAYS, REPORTABLE_FOR_MONTHS);

ALTER TABLE CSRIMP.AUDIT_CLOSURE_TYPE ADD CONSTRAINT PK_AUDIT_CLOSURE_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, AUDIT_CLOSURE_TYPE_ID);

grant select,insert,update,delete on csrimp.audit_type_closure_type to web_user;

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CSRIMP') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
		   AND t.table_name IN ('AUDIT_TYPE_CLOSURE_TYPE')
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => 'CSRIMP',
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive);
	END LOOP;
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/

@../csrimp/imp_body

--end CSRIMP

@../audit_pkg
@../audit_body
@../audit_report_body
@../csr_app_body
@../quick_survey_body
@../schema_body

@update_tail
