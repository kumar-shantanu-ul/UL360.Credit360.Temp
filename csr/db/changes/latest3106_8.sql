-- Please update version.sql too -- this keeps clean builds in sync
define version=3106
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

DROP TABLE CSR.T_FLOW_STATE_TRANS;

CREATE GLOBAL TEMPORARY TABLE CSR.T_FLOW_STATE_TRANS
(
	FLOW_SID					NUMBER(10) NOT NULL,
	POS							NUMBER(10) NOT NULL,
	FLOW_STATE_TRANSITION_ID	NUMBER(10) NOT NULL,
	FROM_STATE_ID				NUMBER(10) NOT NULL,
	TO_STATE_ID					NUMBER(10) NOT NULL,
	ASK_FOR_COMMENT				VARCHAR2(16) NOT NULL,
	MANDATORY_FIELDS_MESSAGE	VARCHAR2(255),
	AUTO_TRANS_TYPE				NUMBER(10) NOT NULL,
	HOURS_BEFORE_AUTO_TRAN		NUMBER(10),
	AUTO_SCHEDULE_XML			XMLTYPE,
	BUTTON_ICON_PATH			VARCHAR2(255),
	VERB						VARCHAR2(255) NOT NULL,
	LOOKUP_KEY					VARCHAR2(255),
	HELPER_SP					VARCHAR2(255),
	ROLE_SIDS					VARCHAR2(2000),
	COLUMN_SIDS					VARCHAR2(2000),
	INVOLVED_TYPE_IDS			VARCHAR2(2000),
	GROUP_SIDS					VARCHAR2(2000),
	ATTRIBUTES_XML				XMLTYPE
)
ON COMMIT DELETE ROWS;

-- Alter tables

ALTER TABLE csr.flow_state_transition ADD (
	AUTO_SCHEDULE_XML	SYS.XMLType,
	AUTO_TRANS_TYPE		NUMBER(10) DEFAULT 0 NOT NULL,
	LAST_RUN_DTM		DATE
);

ALTER TABLE csrimp.flow_state_transition ADD (
	AUTO_SCHEDULE_XML	SYS.XMLType,
	AUTO_TRANS_TYPE		NUMBER(10) NOT NULL,
	LAST_RUN_DTM		DATE
);


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../recurrence_pattern_pkg
@../flow_pkg

@../recurrence_pattern_body
@../flow_body
@../schema_body

@../csrimp/imp_body

@update_tail
