define version=3462
define minor_version=0
define is_combined=1
@update_header

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

CREATE GLOBAL TEMPORARY TABLE CMS.TT_REGION_PATH
(
	REGION_SID		NUMBER(10),
	DESCRIPTION		VARCHAR2(1023),
	PATH			VARCHAR2(4000),
	GEO_COUNTRY		VARCHAR2(2)
) ON COMMIT PRESERVE ROWS;
CREATE GLOBAL TEMPORARY TABLE CMS.TT_IND_PATH
(
	IND_SID			NUMBER(10),
	DESCRIPTION		VARCHAR2(1023),
	PATH			VARCHAR2(4000)
) ON COMMIT PRESERVE ROWS;


ALTER TABLE aspen2.application ADD (MEGA_MENU_ENABLED NUMBER(1) DEFAULT 0 NOT NULL);
ALTER TABLE aspen2.application ADD CONSTRAINT CK_MEGA_MENU_ENABLED CHECK (MEGA_MENU_ENABLED IN (0,1));
ALTER TABLE csrimp.aspen2_application ADD (MEGA_MENU_ENABLED NUMBER(1) DEFAULT 0 NOT NULL);
ALTER TABLE csrimp.aspen2_application ADD CONSTRAINT CK_MEGA_MENU_ENABLED CHECK (MEGA_MENU_ENABLED IN (0,1));
UPDATE aspen2.application a
   SET mega_menu_enabled = (SELECT use_beta_menu FROM csr.customer WHERE app_sid = a.app_sid)
 WHERE EXISTS (SELECT 1 FROM csr.customer WHERE app_sid = a.app_sid);
ALTER TABLE csr.customer DROP COLUMN use_beta_menu;
ALTER TABLE csr.customer DROP COLUMN preview_beta_menu;
ALTER TABLE csrimp.customer DROP COLUMN use_beta_menu;
ALTER TABLE csrimp.customer DROP COLUMN preview_beta_menu;
drop type csr.T_FLOW_STATE_TRANS_TABLE;
create or replace TYPE csr.T_FLOW_STATE_TRANS_ROW AS
	OBJECT (
		POS							NUMBER(10),
		ID							NUMBER(10),
		FROM_STATE_ID				NUMBER(10),
		TO_STATE_ID					NUMBER(10),
		ASK_FOR_COMMENT				VARCHAR2(16),
		MANDATORY_FIELDS_MESSAGE	VARCHAR2(255),
		HOURS_BEFORE_AUTO_TRAN		NUMBER(10),
		BUTTON_ICON_PATH			VARCHAR2(255),
		VERB						VARCHAR2(255),
		LOOKUP_KEY					VARCHAR2(255),
		HELPER_SP					VARCHAR2(255),
		ROLE_SIDS					VARCHAR2(2000),
		COLUMN_SIDS					VARCHAR2(2000),
		INVOLVED_TYPE_IDS			VARCHAR2(2000),
		ENFORCE_VALIDATION			NUMBER(1), 
		ATTRIBUTES_XML				XMLType
	);
/
create or replace TYPE csr.T_FLOW_STATE_TRANS_TABLE AS
	TABLE OF CSR.T_FLOW_STATE_TRANS_ROW;
/
ALTER TABLE csr.t_flow_state_trans ADD enforce_validation NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.flow_state_transition ADD enforce_validation NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.flow_state_transition ADD CONSTRAINT CK_ENFORCE_VALIDATION CHECK (ENFORCE_VALIDATION IN (0,1));
ALTER TABLE csrimp.flow_state_transition ADD enforce_validation NUMBER(1) NOT NULL;
ALTER TABLE csrimp.flow_state_transition ADD CONSTRAINT CK_ENFORCE_VALIDATION CHECK (ENFORCE_VALIDATION IN (0,1));






CREATE OR REPLACE VIEW csr.v$flow_item_transition AS 
  SELECT fst.app_sid, fi.flow_sid, fi.flow_item_Id, fst.flow_state_transition_id, fst.verb,
		 fs.flow_state_id from_state_id, fs.label from_state_label, fs.state_colour from_state_colour,
		 tfs.flow_state_id to_state_id, tfs.label to_state_label, tfs.state_colour to_state_colour,
		 fst.ask_for_comment, fst.pos transition_pos, fst.button_icon_path, fst.enforce_validation,
		 tfs.flow_state_nature_id,
		 fi.survey_response_id, fi.dashboard_instance_id -- these are deprecated
	FROM flow_item fi
		JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
		JOIN flow_state_transition fst ON fs.flow_state_id = fst.from_state_id AND fs.app_sid = fst.app_sid
		JOIN flow_state tfs ON fst.to_state_id = tfs.flow_state_id AND fst.app_sid = tfs.app_sid AND tfs.is_deleted = 0;
CREATE OR REPLACE VIEW csr.v$flow_item_trans_role_member AS 
  SELECT fit.app_sid,fit.flow_sid,fit.flow_item_id,fit.flow_state_transition_id,fit.verb,fit.from_state_id,fit.from_state_label,
  		 fit.from_state_colour,fit.to_state_id,fit.to_state_label,fit.to_state_colour,fit.ask_for_comment,fit.transition_pos,
		 fit.button_icon_path,fit.survey_response_id,fit.dashboard_instance_id, r.role_sid, r.name role_name, rrm.region_sid, fit.flow_state_nature_id, fit.enforce_validation
	FROM v$flow_item_transition fit
		 JOIN flow_state_transition_role fstr ON fit.flow_state_transition_id = fstr.flow_state_transition_id AND fit.app_sid = fstr.app_sid
		 JOIN role r ON fstr.role_sid = r.role_sid AND fstr.app_sid = r.app_sid
		 JOIN region_role_member rrm ON r.role_sid = rrm.role_sid AND r.app_sid = rrm.app_sid
   WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID');




DECLARE
	v_tag_id						csr.tag.tag_id%TYPE;
BEGIN
	security.user_pkg.logonadmin;
	
	FOR r IN (
		SELECT DISTINCT host, tag_group_id
		  FROM csr.tag_group tg
		  JOIN csr.customer c ON c.app_sid = tg.app_sid
		 WHERE lookup_key = 'RBA_AUDIT_STATUS'
	) LOOP
		security.user_pkg.logonadmin(r.host);
				
		INSERT INTO csr.tag (tag_id, lookup_key, parent_id)
		VALUES (csr.tag_id_seq.nextval, 'RBA_CLOSED', NULL)
		RETURNING tag_id INTO v_tag_id;
			
		INSERT INTO csr.tag_description (tag_id, lang, tag)
		VALUES (v_tag_id, 'en', 'Closed');
		INSERT INTO csr.tag_group_member (tag_group_id, tag_id, pos, active)
		VALUES (r.tag_group_id, v_tag_id, 0, 1);
		
		security.user_pkg.logonadmin;
	END LOOP;
	security.user_pkg.logonadmin;
END;
/






@..\schema_pkg
@..\branding_pkg
@..\flow_pkg


@..\enable_body
@..\schema_body
@..\..\..\aspen2\db\aspenapp_body
@..\branding_body
@..\customer_body
@..\csrimp\imp_body
@..\flow_body



@update_tail
