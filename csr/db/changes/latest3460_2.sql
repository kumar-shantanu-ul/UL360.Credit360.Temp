-- Please update version.sql too -- this keeps clean builds in sync
define version=3460
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

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

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

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


-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../csrimp/imp_body
@../schema_body
@../flow_pkg
@../flow_body

@update_tail
