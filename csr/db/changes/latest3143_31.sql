-- Please update version.sql too -- this keeps clean builds in sync
define version=3143
define minor_version=31
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.FLOW_ITEM_REGION(
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	FLOW_ITEM_ID					NUMBER(10, 0)	NOT NULL,
	REGION_SID						NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_FLOW_ITEM_REGION PRIMARY KEY (APP_SID, FLOW_ITEM_ID, REGION_SID)
)
;

ALTER TABLE CSR.FLOW_ITEM_REGION ADD CONSTRAINT FK_FLOW_ITEM_REGION_FLOW_ITEM
	FOREIGN KEY (APP_SID, FLOW_ITEM_ID) 
	REFERENCES CSR.FLOW_ITEM (APP_SID, FLOW_ITEM_ID)
;

ALTER TABLE CSR.FLOW_ITEM_REGION ADD CONSTRAINT FK_FLOW_ITEM_REGION_REGION 
	FOREIGN KEY (APP_SID, REGION_SID) 
	REFERENCES CSR.REGION (APP_SID, REGION_SID)
;

BEGIN
	security.user_pkg.LogonAdmin;

	INSERT INTO csr.flow_item_region (app_sid, flow_item_id, region_sid) 
	SELECT app_sid, flow_item_id, region_sid
	  FROM csr.flow_item
	 WHERE region_sid IS NOT NULL;

	 
	INSERT INTO csr.flow_item_region (app_sid, flow_item_id, region_sid) 
	SELECT app_sid, flow_item_id, region_sid
	  FROM surveys.response
	 WHERE flow_item_id IS NOT NULL 
	   AND region_sid IS NOT NULL;
END;
/

ALTER TABLE CSR.FLOW_ITEM DROP CONSTRAINT FK_FLOW_ITEM_REGION;
ALTER TABLE CSR.FLOW_ITEM DROP COLUMN REGION_SID;

CREATE INDEX CSR.IX_FLOW_ITEM_REG_REGION_SID ON CSR.FLOW_ITEM_REGION (APP_SID, REGION_SID);

-- Alter tables
ALTER TABLE SURVEYS.RESPONSE_SUBMISSION ADD 
(
	IS_SUBMISSION NUMBER(1) DEFAULT 0 NOT NULL,
	FLOW_STATE_LOG_ID NUMBER(10),
	FLOW_STATE_TRANSITION_ID NUMBER(10),
	TRANSITION_OCCURRENCE_ID VARCHAR2(50),
	CONSTRAINT CHK_RS_IS_SUBMISSION CHECK (IS_SUBMISSION IN (0,1))
);

-- *** Grants ***
grant references on csr.flow_state_log to surveys;
grant references on csr.flow_state_transition to surveys;

-- ** Cross schema constraints ***


-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.LogonAdmin;

	UPDATE SURVEYS.RESPONSE_SUBMISSION
	   SET IS_SUBMISSION = 1
	 WHERE SUBMITTED_DTM IS NOT NULL;

	INSERT INTO CSR.FLOW_STATE_NATURE (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) 
		VALUES (37, 'campaign', 'Promoted to Submission'); 
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../flow_pkg
@../flow_body
@../schema_body
@../csrimp/imp_body

--@../surveys/survey_pkg
--@../surveys/survey_body

@update_tail
