define version=3388
define minor_version=0
define is_combined=1
@update_header

@@latestUD-11792_packages

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;

CREATE TABLE CSR.MODULE_HISTORY(
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	MODULE_ID			NUMBER(10, 0)	NOT NULL,
	ENABLED_DTM			DATE,
	LAST_ENABLED_DTM	DATE,
	DISABLED_DTM		DATE,
	CONSTRAINT PK_MODULE_HSTORY_MODULE_ID PRIMARY KEY (APP_SID, MODULE_ID)
)
;
ALTER TABLE CSR.MODULE_HISTORY ADD CONSTRAINT FK_MODULE_HISTORY_ID
	FOREIGN KEY (MODULE_ID)
	REFERENCES CSR.MODULE(MODULE_ID)
;
CREATE INDEX CSR.IX_MODULE_HISTORY_MODULE_ID ON CSR.MODULE_HISTORY (MODULE_ID);
CREATE TABLE CSRIMP.MODULE_HISTORY (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	MODULE_ID					NUMBER(10, 0)	NOT NULL,
	ENABLED_DTM					DATE,
	LAST_ENABLED_DTM			DATE,
	DISABLED_DTM				DATE,
	CONSTRAINT PK_MODULE_HSTORY_MODULE_ID PRIMARY KEY (CSRIMP_SESSION_ID, MODULE_ID),
	CONSTRAINT FK_MODULE_HISTORY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
DROP TABLE CSRIMP.CREDENTIAL_MANAGEMENT;
CREATE TABLE CSRIMP.CREDENTIAL_MANAGEMENT (
	CSRIMP_SESSION_ID	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CREDENTIAL_ID		NUMBER(10, 0)		NOT NULL,
	LABEL				VARCHAR2(255)		NOT NULL,
	AUTH_TYPE_ID		NUMBER(10, 0)		NOT NULL,
	AUTH_SCOPE_ID		NUMBER(10, 0)		NOT NULL,
	CREATED_DTM			DATE				NOT NULL,
	UPDATED_DTM			DATE				NOT NULL,
	LOGIN_HINT			VARCHAR2(500),
	CONSTRAINT PK_CREDENTIAL_MANAGEMENT PRIMARY KEY (CSRIMP_SESSION_ID, CREDENTIAL_ID),
	CONSTRAINT UK_CREDENTIAL_MANAGEMENT_LABEL UNIQUE (CSRIMP_SESSION_ID, LABEL),
	CONSTRAINT FK_CREDENTIAL_MANAGEMENT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
DROP TABLE CSRIMP.INTEGRATION_QUESTION_ANSWER;
CREATE TABLE CSRIMP.INTEGRATION_QUESTION_ANSWER(
	CSRIMP_SESSION_ID	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PARENT_REF			VARCHAR2(255)	NOT NULL,
	QUESTION_REF		VARCHAR2(255)	NOT NULL,
	INTERNAL_AUDIT_SID	NUMBER(10, 0),
	SECTION_NAME		VARCHAR2(1024),
	SECTION_CODE		VARCHAR2(1024),
	SECTION_SCORE		NUMBER(10, 5),
	SUBSECTION_NAME		VARCHAR2(1024),
	SUBSECTION_CODE		VARCHAR2(1024),
	QUESTION_TEXT		VARCHAR2(4000),
	RATING				VARCHAR2(1024),
	CONCLUSION			CLOB,
	ANSWER				CLOB,
	DATA_POINTS			CLOB,
	LAST_UPDATED		DATE,
	ID					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_INTEGRATION_QUESTION_ANSWER PRIMARY KEY (CSRIMP_SESSION_ID, PARENT_REF, QUESTION_REF),
	CONSTRAINT UK_INTEGRATION_QUESTION_ANSWER_ID UNIQUE (CSRIMP_SESSION_ID, ID),
	CONSTRAINT FK_INTEGRATION_QUESTION_ANSWER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
DROP TABLE CSRIMP.REGION_CERTIFICATE;
CREATE TABLE CSRIMP.REGION_CERTIFICATE (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	REGION_CERTIFICATE_ID		NUMBER(24,0) NOT NULL,
	REGION_SID					NUMBER(10,0) NOT NULL,
	CERTIFICATION_ID			NUMBER(10,0) NOT NULL,
	CERTIFICATION_LEVEL_ID		NUMBER(10,0),
	CERTIFICATE_NUMBER			NUMBER(10,0),
	FLOOR_AREA					NUMBER(10,2) NOT NULL,
	ISSUED_DTM					DATE,
	EXPIRY_DTM					DATE,
	EXTERNAL_CERTIFICATE_ID		NUMBER(10,0),
	DELETED						NUMBER(1, 0) NOT NULL,
	CONSTRAINT PK_REGION_CERTS PRIMARY KEY (CSRIMP_SESSION_ID, REGION_CERTIFICATE_ID),
	CONSTRAINT UK_REG_CERT_EXT_ID UNIQUE (CSRIMP_SESSION_ID, REGION_SID, CERTIFICATION_ID, CERTIFICATION_LEVEL_ID, EXTERNAL_CERTIFICATE_ID),
	CONSTRAINT CK_REGION_CERT_DELETED CHECK (DELETED in (0,1)),
	CONSTRAINT FK_REGION_CERTIFICATE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
DROP TABLE CSRIMP.REGION_ENERGY_RATING;
CREATE TABLE CSRIMP.REGION_ENERGY_RATING (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	REGION_SID					NUMBER(10,0) NOT NULL,
	ENERGY_RATING_ID			NUMBER(10,0) NOT NULL,
	FLOOR_AREA					NUMBER(10,2) NOT NULL,
	ISSUED_DTM					DATE NOT NULL,
	EXPIRY_DTM					DATE,
	CONSTRAINT PK_REGION_ENERGY_RAT PRIMARY KEY (CSRIMP_SESSION_ID, REGION_SID),
	CONSTRAINT CHK_REGION_ENERGY_RAT_EXP_AFTER_ISS CHECK ((ISSUED_DTM IS NULL OR EXPIRY_DTM IS NULL) OR (ISSUED_DTM IS NOT NULL AND EXPIRY_DTM IS NOT NULL AND ISSUED_DTM < EXPIRY_DTM)),
	CONSTRAINT FK_REGION_ENERGY_RATING_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


ALTER TABLE csrimp.home_page DROP PRIMARY KEY DROP INDEX;
ALTER TABLE csrimp.home_page ADD (
	priority	NUMBER(10, 0)
);
ALTER TABLE csrimp.home_page RENAME COLUMN host TO created_by_host;
ALTER TABLE csrimp.home_page ADD CONSTRAINT PK_HOME_PAGE PRIMARY KEY (csrimp_session_id, sid_id);
ALTER TABLE csr.integration_question_answer ADD questionnaire_name VARCHAR2(255);
ALTER TABLE csrimp.integration_question_answer ADD questionnaire_name VARCHAR2(255);


CREATE OR REPLACE PACKAGE csr.landing_page_pkg AS
    PROCEDURE DUMMY;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.landing_page_pkg AS
    PROCEDURE DUMMY
AS
    BEGIN
        NULL;
    END;
END;
/
grant execute on csr.landing_page_pkg to web_user;
grant select,insert, update on csr.module_history to csrimp;
grant select,insert,update,delete on csrimp.module_history to tool_user;
grant select,insert,update,delete on CSRIMP.CREDENTIAL_MANAGEMENT to tool_user;
grant select,insert,update,delete on CSRIMP.INTEGRATION_QUESTION_ANSWER to tool_user;
grant select,insert,update,delete on CSRIMP.REGION_CERTIFICATE to tool_user;
grant select,insert,update,delete on CSRIMP.REGION_ENERGY_RATING to tool_user;








BEGIN
	UPDATE csr.certification SET name = 'Milj'||UNISTR('\00F6')||'byggnad/Existing Buildings' WHERE certification_id = 113;
	UPDATE csr.certification SET name = 'Milj'||UNISTR('\00F6')||'byggnad/New Buildings' WHERE certification_id = 114;
	UPDATE csr.certification SET name = 'NF Habitat/HQE R'||UNISTR('\00E9')||'novation' WHERE certification_id = 122;
	UPDATE csr.certification SET name = 'NF HQE/B'||UNISTR('\00E2')||'timents Tertiaires en Exploitation' WHERE certification_id = 123;
	UPDATE csr.certification SET name =  'NF HQE/B'||UNISTR('\00E2')||'timents Tertiaires - Neuf ou R'||UNISTR('\00E9')||'novation' WHERE certification_id = 124;
	UPDATE csr.certification SET name =  'Svanen/Milj'||UNISTR('\00F6')||'m'||UNISTR('\00E4')||'rkta - Design '|| chr(38) ||' Construction' WHERE certification_id = 140;
	UPDATE csr.certification SET name =  'Svanen/Milj'||UNISTR('\00F6')||'m'||UNISTR('\00E4')||'rkta - Operational' WHERE certification_id = 141;
	UPDATE csr.energy_rating SET name =  'BBC Effinergie R'||UNISTR('\00E9')||'novation' WHERE energy_rating_id = 4;
	UPDATE csr.energy_rating SET name = 'DPE (Diagnostic de performance '||UNISTR('\00E9')||'nerg'||UNISTR('\00E9')||'tique)' WHERE energy_rating_id = 10;
	UPDATE csr.energy_rating SET name =  'HPE (Haute Performance Energ'||UNISTR('\00E9')||'tique)' WHERE energy_rating_id = 59;
	UPDATE csr.energy_rating SET name = 'THPE (Tr'||UNISTR('\00E8')||'s Haute Performance Energ'||UNISTR('\00E9')||'tique)' WHERE energy_rating_id = 81;
END;
/
DECLARE
	PROCEDURE ReplaceAuditTypeByLookUpKey(
		in_old_audit_lookup_key IN csr.internal_audit_type.lookup_key%TYPE,
		in_new_audit_lookup_key IN csr.internal_audit_type.lookup_key%TYPE
	)
	AS
		v_new_audit_type_id 	NUMBER 							:= -1;
		v_old_audit_type_id 	NUMBER 							:= -1;
		v_app_sid				SECURITY.SECURITY_PKG.T_SID_ID	:= SYS_CONTEXT('SECURITY', 'APP');
	BEGIN
		BEGIN
			SELECT internal_audit_type_id
			  INTO v_old_audit_type_id
			  FROM csr.internal_audit_type
			 WHERE app_sid = v_app_sid
			   AND lookup_key = in_old_audit_lookup_key;
		EXCEPTION 
			WHEN NO_DATA_FOUND THEN
				RETURN;
		END;
		BEGIN
			SELECT internal_audit_type_id
			  INTO v_new_audit_type_id
			  FROM csr.internal_audit_type
			 WHERE app_sid = v_app_sid
			   AND lookup_key = in_new_audit_lookup_key;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN;
		END;
		If (v_new_audit_type_id > 0 AND v_old_audit_type_id > 0) THEN
			UPDATE csr.quick_survey
			   SET auditing_audit_type_id = v_new_audit_type_id
			 WHERE auditing_audit_type_id = v_old_audit_type_id
			   AND app_sid = v_app_sid;
			   
			UPDATE csr.internal_audit_type_survey
			   SET internal_audit_type_id = v_new_audit_type_id
			 WHERE internal_audit_type_id = v_old_audit_type_id
			   AND app_sid = v_app_sid;
			   
			UPDATE csr.flow_state_audit_ind
			   SET internal_audit_type_id = v_new_audit_type_id
			 WHERE internal_audit_type_id = v_old_audit_type_id 
			   AND app_sid = v_app_sid;
			   
			UPDATE csr.internal_audit
			   SET internal_audit_type_id = v_new_audit_type_id
			 WHERE internal_audit_type_id = v_old_audit_type_id
			   AND app_sid = v_app_sid;
			DELETE FROM csr.score_type_audit_type
			 WHERE internal_audit_type_id = v_old_audit_type_id 
			   AND app_sid = v_app_sid;
			   
			DELETE FROM csr.region_internal_audit
			 WHERE internal_audit_type_id = v_old_audit_type_id 
			   AND app_sid = v_app_sid;
			   
			DELETE FROM csr.internal_audit_type_tag_group
			 WHERE internal_audit_type_id = v_old_audit_type_id
			   AND app_sid = v_app_sid;
			   
			DELETE FROM csr.audit_type_non_comp_default 
			 WHERE internal_audit_type_id = v_old_audit_type_id
			   AND app_sid = v_app_sid;
			   
			DELETE FROM csr.audit_type_flow_inv_type
			 WHERE internal_audit_type_id = v_old_audit_type_id 
			   AND app_sid= v_app_sid;
			   
			csr.temp_audit_pkg.DeleteInternalAuditType(v_old_audit_type_id);
		END IF;
	END;
BEGIN
	security.user_pkg.logonadmin();
	FOR apps IN (
		SELECT app_sid, host
		  FROM csr.customer c
		  JOIN security.website w ON c.host = w.website_name
	)
	LOOP
		security.user_pkg.logonadmin(apps.host);
		ReplaceAuditTypeByLookUpKey('RBA_PRIORITY_CLOSURE_AUDIT','RBA_INITIAL_AUDIT');
		ReplaceAuditTypeByLookUpKey('RBA_CLOSURE_AUDIT','RBA_INITIAL_AUDIT');
		
		UPDATE csr.internal_audit_type
		   SET label = 'RBA', lookup_key = 'RBA_AUDIT_TYPE' 
		 WHERE app_sid = apps.app_sid
		   AND lookup_key = 'RBA_INITIAL_AUDIT';
		
		DELETE FROM csr.internal_audit_tag iat
		 WHERE EXISTS (
			SELECT NULL
			  FROM csr.tag
			 WHERE lookup_key IN ('RBA_VAP', 'RBA_VAP_MEDIUM_BUSINESS', 'RBA_EMPLOYMENT_SITE_SVA_ONLY')
			   AND tag_id = iat.tag_id
		);
		
		-- Rename Audit Category Tags
		UPDATE csr.tag
		   SET lookup_key = 'RBA_INITIAL_AUDIT' 
		 WHERE app_sid = apps.app_sid
		   AND lookup_key = 'RBA_VAP';
		
		UPDATE csr.tag_description td
		   SET tag = 'Initial Audit'
		 WHERE EXISTS(
			SELECT NULL
			  FROM csr.tag
			 WHERE tag_id = td.tag_id
			   AND lookup_key = 'RBA_INITIAL_AUDIT'
			);
		
		UPDATE csr.tag
		   SET lookup_key = 'RBA_PRIORITY_CLOSURE_AUDIT' 
		 WHERE app_sid = apps.app_sid
		   AND lookup_key = 'RBA_VAP_MEDIUM_BUSINESS';
		
		UPDATE csr.tag_description td
		   SET tag = 'Priority Closure Audit'
		 WHERE EXISTS(
			SELECT NULL
			  FROM csr.tag
			 WHERE tag_id = td.tag_id
			   AND lookup_key = 'RBA_PRIORITY_CLOSURE_AUDIT'
			);
		
		UPDATE csr.tag
		   SET lookup_key = 'RBA_CLOSURE_AUDIT' 
		 WHERE app_sid = apps.app_sid
		   AND lookup_key = 'RBA_EMPLOYMENT_SITE_SVA_ONLY';
		   
		UPDATE csr.tag_description td
		   SET tag = 'Closure Audit'
		 WHERE EXISTS(
			SELECT NULL
			  FROM csr.tag
			 WHERE tag_id = td.tag_id
			   AND lookup_key = 'RBA_CLOSURE_AUDIT'
			);
		security.user_pkg.logonadmin();
	END LOOP;	
END;
/
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (122, 'Landing Pages', 'EnableLandingPages', 'Enable Landing Pages');
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (306,'Landing Page',6);
ALTER TABLE CSR.REGION_CERTIFICATE DISABLE CONSTRAINT FK_REG_CERT_CERT_LVL;
DELETE FROM CSR.CERTIFICATION_LEVEL;
BEGIN
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (1, 3, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (2, 3, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (3, 3, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (4, 3, 3, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (5, 4, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (6, 4, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (7, 4, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (8, 4, 3, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (9, 5, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (10, 5, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (11, 5, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (12, 5, 3, 'Green');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (13, 7, 0, '5 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (14, 7, 1, '4 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (15, 7, 2, '3 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (16, 7, 3, '2 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (17, 7, 4, '1 Star');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (18, 8, 0, 'Excellence Label');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (19, 8, 1, 'Performance Label');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (20, 8, 2, 'Label');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (21, 9, 0, 'Excellence Label');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (22, 9, 1, 'Performance Label');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (23, 9, 2, 'Label');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (24, 10, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (25, 10, 1, 'GoldPlus');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (26, 10, 2, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (27, 10, 3, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (28, 11, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (29, 11, 1, 'GoldPlus');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (30, 11, 2, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (31, 11, 3, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (32, 12, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (33, 12, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (34, 12, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (35, 12, 3, 'Bronze');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (36, 13, 0, 'Excellent');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (37, 13, 1, 'Very Good');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (38, 13, 2, 'Good');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (39, 13, 3, 'Satisfactory');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (40, 14, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (41, 14, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (42, 14, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (43, 14, 3, 'Bronze');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (44, 15, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (45, 15, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (46, 15, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (47, 15, 3, 'Bronze');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (48, 16, 0, '5 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (49, 16, 1, '4 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (50, 16, 2, '3 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (51, 16, 3, '2 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (52, 16, 4, '1 Star');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (53, 17, 0, '5 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (54, 17, 1, '4 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (55, 17, 2, '3 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (56, 17, 3, '2 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (57, 17, 4, '1 Star');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (58, 18, 0, '5 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (59, 18, 1, '4 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (60, 18, 2, '3 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (61, 18, 3, '2 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (62, 18, 4, '1 Star');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (63, 20, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (64, 20, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (65, 20, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (66, 20, 3, 'Bronze');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (67, 20, 4, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (68, 23, 0, 'Code Level 6');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (69, 23, 1, 'Code Level 5');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (70, 23, 2, 'Code Level 4');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (71, 23, 3, 'Code Level 3');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (72, 23, 4, 'Code Level 2');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (73, 23, 5, 'Code Level 1');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (74, 24, 0, 'Outstanding');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (75, 24, 1, 'Excellent');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (76, 24, 2, 'Very Good');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (77, 24, 3, 'Good');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (78, 24, 4, 'Pass');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (79, 26, 0, 'Outstanding');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (80, 26, 1, 'Excellent');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (81, 26, 2, 'Very Good');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (82, 26, 3, 'Good');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (83, 26, 4, 'Pass');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (84, 26, 5, 'Acceptable');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (85, 27, 0, 'Outstanding');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (86, 27, 1, 'Excellent');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (87, 27, 2, 'Very Good');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (88, 27, 3, 'Good');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (89, 27, 4, 'Pass');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (90, 28, 0, 'Outstanding');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (91, 28, 1, 'Excellent');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (92, 28, 2, 'Very Good');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (93, 28, 3, 'Good');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (94, 28, 4, 'Pass');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (95, 31, 0, '5 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (96, 31, 1, '4 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (97, 31, 2, '3 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (98, 34, 0, 'Superior (S)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (99, 34, 1, 'Very Good (A)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (100, 34, 2, 'Good (B+)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (101, 34, 3, 'Slightly Poor (B-)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (102, 34, 4, 'Poor (C)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (103, 35, 0, 'Superior (S)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (104, 35, 1, 'Very Good (A)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (105, 35, 2, 'Good (B+)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (106, 35, 3, 'Slightly Poor (B-)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (107, 35, 4, 'Poor (C)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (108, 36, 0, 'Superior (S)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (109, 36, 1, 'Very Good (A)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (110, 36, 2, 'Good (B+)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (111, 36, 3, 'Slightly Poor (B-)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (112, 36, 4, 'Poor (C)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (113, 37, 0, 'Superior (S)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (114, 37, 1, 'Very Good (A)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (115, 37, 2, 'Good (B+)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (116, 37, 3, 'Slightly Poor (B-)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (117, 37, 4, 'Poor (C)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (118, 38, 0, 'Superior (S)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (119, 38, 1, 'Very Good (A)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (120, 38, 2, 'Good (B+)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (121, 38, 3, 'Slightly Poor (B-)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (122, 38, 4, 'Poor (C)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (123, 39, 0, 'Superior (S)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (124, 39, 1, 'Very Good (A)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (125, 39, 2, 'Good (B+)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (126, 39, 3, 'Slightly Poor (B-)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (127, 39, 4, 'Poor (C)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (128, 40, 0, 'Superior (S)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (129, 40, 1, 'Very Good (A)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (130, 40, 2, 'Good (B+)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (131, 40, 3, 'Slightly Poor (B-)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (132, 40, 4, 'Poor (C)');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (133, 41, 0, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (134, 41, 1, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (135, 41, 2, 'Bronze');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (136, 43, 0, 'Three Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (137, 43, 1, 'Two Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (138, 43, 2, 'One Star');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (139, 44, 0, 'Three Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (140, 44, 1, 'Two Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (141, 44, 2, 'One Star');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (142, 45, 0, 'Grade 1');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (143, 45, 1, 'Grade 2');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (144, 45, 2, 'Grade 3');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (145, 46, 0, '3 Star');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (146, 47, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (147, 47, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (148, 47, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (149, 47, 3, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (150, 48, 0, '5 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (151, 48, 1, '4 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (152, 48, 2, '3 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (153, 48, 3, '2 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (154, 48, 4, '1 Star');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (155, 49, 0, '5 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (156, 49, 1, '4 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (157, 49, 2, '3 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (158, 49, 3, '2 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (159, 49, 4, '1 Star');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (160, 51, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (161, 51, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (162, 51, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (163, 51, 3, 'Bronze');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (164, 52, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (165, 52, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (166, 52, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (167, 52, 3, 'Bronze');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (168, 53, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (169, 53, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (170, 53, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (171, 53, 3, 'Bronze');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (172, 57, 0, 'Advanced');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (173, 57, 1, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (174, 60, 0, '3 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (175, 60, 1, '2 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (176, 60, 2, '1 Star');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (177, 61, 0, '3 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (178, 61, 1, '2 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (179, 61, 2, '1 Star');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (180, 62, 0, 'Approved with Distinction');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (181, 62, 1, 'Approved');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (182, 69, 0, '4 Green Globes');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (183, 69, 1, '3 Green Globes');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (184, 69, 2, '2 Green Globes');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (185, 69, 3, '1 Green Globe');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (186, 70, 0, '4 Green Globes');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (187, 70, 1, '3 Green Globes');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (188, 70, 2, '2 Green Globes');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (189, 70, 3, '1 Green Globe');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (190, 71, 0, '4 Green Globes');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (191, 71, 1, '3 Green Globes');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (192, 71, 2, '2 Green Globes');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (193, 71, 3, '1 Green Globe');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (194, 78, 0, '6 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (195, 78, 1, '5 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (196, 78, 2, '4 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (197, 79, 0, '6 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (198, 79, 1, '5 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (199, 79, 2, '4 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (200, 80, 0, '6 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (201, 80, 1, '5 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (202, 80, 2, '4 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (203, 81, 0, '6 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (204, 81, 1, '5 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (205, 81, 2, '4 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (206, 82, 0, '6 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (207, 82, 1, '5 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (208, 82, 2, '4 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (209, 83, 0, '6 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (210, 83, 1, '5 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (211, 83, 2, '4 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (212, 83, 3, '3 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (213, 83, 4, '2 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (214, 83, 5, '1 Star');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (215, 84, 0, '6 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (216, 84, 1, '5 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (217, 84, 2, '4 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (218, 84, 3, '3 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (219, 84, 4, '2 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (220, 84, 5, '1 Star');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (221, 85, 0, '6 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (222, 85, 1, '5 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (223, 85, 2, '4 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (224, 86, 0, '6 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (225, 86, 1, '5 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (226, 86, 2, '4 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (227, 86, 3, '3 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (228, 86, 4, '2 Stars');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (229, 86, 5, '1 Star');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (230, 90, 0, 'Excellent Class');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (231, 90, 1, 'Good Class');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (232, 98, 0, 'Living');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (233, 98, 1, 'Petal');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (234, 100, 0, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (235, 100, 1, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (236, 101, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (237, 101, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (238, 101, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (239, 101, 3, 'Bronze');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (240, 102, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (241, 102, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (242, 102, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (243, 102, 3, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (244, 103, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (245, 103, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (246, 103, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (247, 103, 3, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (248, 104, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (249, 104, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (250, 104, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (251, 104, 3, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (252, 105, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (253, 105, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (254, 105, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (255, 105, 3, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (256, 106, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (257, 106, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (258, 106, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (259, 106, 3, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (260, 107, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (261, 107, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (262, 107, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (263, 107, 3, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (264, 108, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (265, 108, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (266, 108, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (267, 108, 3, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (268, 109, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (269, 109, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (270, 109, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (271, 109, 3, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (272, 110, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (273, 110, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (274, 110, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (275, 110, 3, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (276, 111, 0, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (277, 111, 1, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (278, 111, 2, 'Bronze');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (279, 112, 0, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (280, 112, 1, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (281, 112, 2, 'Bronze');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (282, 113, 0, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (283, 113, 1, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (284, 113, 2, 'Bronze');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (285, 122, 0, 'EXCEPTIONNEL');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (286, 122, 1, 'EXCELLENT');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (287, 122, 2, 'TRES BON');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (288, 122, 3, 'BON');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (289, 122, 4, 'PASS');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (290, 123, 0, 'EXCEPTIONNEL');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (291, 123, 1, 'EXCELLENT');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (292, 123, 2, 'TRES BON');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (293, 123, 3, 'BON');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (294, 123, 4, 'PASS');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (295, 124, 0, 'Emerald');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (296, 124, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (297, 124, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (298, 124, 3, 'Bronze');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (299, 125, 0, 'Emerald');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (300, 125, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (301, 125, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (302, 125, 3, 'Bronze');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (303, 126, 0, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (304, 126, 1, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (305, 126, 2, 'Bronze');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (306, 126, 3, 'Pioneer');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (307, 128, 0, 'Premium');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (308, 128, 1, 'Plus');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (309, 128, 2, 'Classic');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (310, 129, 0, 'Premium');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (311, 129, 1, 'Plus');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (312, 129, 2, 'Classic');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (313, 141, 0, 'Tier 4');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (314, 141, 1, 'Tier 3');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (315, 141, 2, 'Tier 2');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (316, 142, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (317, 142, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (318, 142, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (319, 142, 3, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (320, 143, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (321, 143, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (322, 143, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (323, 143, 3, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (324, 144, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (325, 144, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (326, 144, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (327, 144, 3, 'Bronze');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (328, 144, 4, 'GreenPartner');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (329, 145, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (330, 145, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (331, 145, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (332, 145, 3, 'Certified');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (333, 146, 0, 'for Indoor Environmental Quality');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (334, 146, 1, 'for Indoor Air and Water');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (335, 146, 2, 'for Indoor Air');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (336, 147, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (337, 147, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (338, 147, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (339, 148, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (340, 148, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (341, 148, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (342, 149, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (343, 149, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (344, 149, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (345, 150, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (346, 150, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (347, 150, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (348, 151, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (349, 151, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (350, 151, 2, 'Silver');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (351, 152, 0, 'Platinum');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (352, 152, 1, 'Gold');
	INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (353, 152, 2, 'Silver');
END;
/
ALTER TABLE CSR.REGION_CERTIFICATE ENABLE CONSTRAINT FK_REG_CERT_CERT_LVL;
UPDATE csr.batch_job bj
   SET retry_dtm = SYSDATE + 1,
	   updated_dtm = SYSDATE,
	   completed_dtm = NULL,
	   failed = 0
 WHERE bj.failed = 1
   AND bj.requested_dtm > '01-JAN-2022'
   AND EXISTS (
	SELECT NULL
	  FROM chain.company_request_action
	 WHERE batch_job_id = bj.batch_job_id
	);




DROP PACKAGE csr.temp_audit_pkg;


@..\region_certificate_pkg
@..\csr_data_pkg
@..\enable_pkg
@..\landing_page_pkg
@..\schema_pkg
@..\csrimp\imp_pkg
@..\sustain_essentials_pkg
@..\integration_question_answer_pkg


@..\audit_body
@..\enable_body
@..\unit_test_body
@..\region_certificate_body
@..\integration_question_answer_report_body
@..\csr_app_body
@..\landing_page_body
@..\schema_body
@..\csrimp\imp_body
@..\sustain_essentials_body
@..\indicator_api_body
@..\chain\filter_body
@..\site_name_management_body
@..\integration_question_answer_body



@update_tail
