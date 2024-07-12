-- Please update version.sql too -- this keeps clean builds in sync
define version=3009
define minor_version=22
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSR.TEMPOR_QUESTION ADD ACTION VARCHAR2(50);
ALTER TABLE CSR.QUICK_SURVEY_QUESTION ADD ACTION VARCHAR2(50);
ALTER TABLE CSR.QUICK_SURVEY_TYPE ADD (
	OTHER_TEXT_REQ_FOR_SCORE NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_QST_OTH_TXT_REQ_FOR_SCORE CHECK (OTHER_TEXT_REQ_FOR_SCORE IN (0,1))
);

CREATE INDEX CSR.IX_QS_QUESTION_ACTION ON CSR.QUICK_SURVEY_QUESTION (APP_SID, ACTION);
CREATE INDEX CSR.IX_QS_Q_OPT_ACTION ON CSR.QS_QUESTION_OPTION (APP_SID, OPTION_ACTION);

ALTER TABLE CSRIMP.QUICK_SURVEY_QUESTION ADD ACTION VARCHAR2(50);
ALTER TABLE CSRIMP.QUICK_SURVEY_TYPE ADD OTHER_TEXT_REQ_FOR_SCORE NUMBER(1);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

DECLARE
	v_count			number(10);
	
BEGIN
	SELECT count(*) 
	  INTO v_count
	  FROM all_tables 
	 WHERE owner = 'CSR'
	   AND table_name = 'TT_QS_CHECKBOX_ACTION';
	
	IF v_count = 0 THEN
		-- Ideally this would be a temporary table, but because of some long running queries we want
		-- to insert the bulk of the data into it before the release. Will need a separate story
		-- to get rid of this once the data has been verified.
		EXECUTE IMMEDIATE '
			CREATE TABLE csr.tt_qs_checkbox_action (
				APP_SID							NUMBER(10) NOT NULL,
				SURVEY_VERSION					NUMBER(10) NOT NULL,
				QUESTION_ID						NUMBER(10) NOT NULL,
				ACTION							VARCHAR2(255) NOT NULL,
				CONSTRAINT PK_TT_QS_CHKBOX_ACTION PRIMARY KEY (APP_SID, SURVEY_VERSION, QUESTION_ID)
			)';
	END IF;
END;
/

BEGIN
	security.user_pkg.LogonAdmin;
	
	DELETE
	  FROM csr.tt_qs_checkbox_action
	 WHERE survey_version = 0;
	
	-- On Wembley this took about 4 minutes but only updates drafts. We will need to update
	-- old versions in a separate script (these cannot be edited so won't change between that
	-- script and the release) and then update any versions created between this script and
	-- the release.
	INSERT INTO csr.tt_qs_checkbox_action (app_sid, survey_version, question_id, action)
	SELECT qsv.app_sid, qsv.survey_version, t.question_id, t.action
	  FROM csr.quick_survey_version qsv, 
		XMLTABLE('//checkbox[@action]' PASSING XMLTYPE(qsv.question_xml) 
			COLUMNS question_id number(10) path '@id', 
					action varchar2(255) path '@action'
		) t
	 WHERE qsv.survey_version = 0
	   AND qsv.survey_sid NOT IN (SELECT trash_sid FROM csr.trash);
	
	UPDATE csr.quick_survey_question qsq
	   SET qsq.action = (
			SELECT action
			  FROM csr.tt_qs_checkbox_action t
			 WHERE t.question_id = qsq.question_id 
			   AND t.app_sid = qsq.app_sid
			   AND t.survey_version = qsq.survey_version
		)
	  WHERE EXISTS (
		SELECT 1
		  FROM csr.tt_qs_checkbox_action t
		 WHERE t.question_id = qsq.question_id 
		   AND t.app_sid = qsq.app_sid
		   AND t.survey_version = qsq.survey_version
	  );
	
	-- There's no constraint requiring all checkboxes to have a value for 'action'
	-- and the code should handle action being null, but if you create a survey in the
	-- system it will always pass something for action for checkboxes, so might as
	-- well start with consistent data.
	UPDATE csr.quick_survey_question
	   SET action = 'none'
	 WHERE action IS NULL AND question_type = 'checkbox';
	
	
	UPDATE csr.quick_survey_type
	   SET other_text_req_for_score = 1
	 WHERE quick_survey_type_id IN (
		SELECT qs.quick_survey_type_id
		  FROM chain.higg_config hc
		  JOIN csr.quick_survey qs ON qs.survey_sid = hc.survey_sid
	 );
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\quick_survey_pkg

@..\quick_survey_body
@..\enable_body
@..\schema_body
@..\testdata_body
@..\chain\higg_setup_body
@..\csrimp\imp_body

@update_tail
