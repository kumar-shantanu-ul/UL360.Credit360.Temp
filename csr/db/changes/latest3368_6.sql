-- Please update version.sql too -- this keeps clean builds in sync
define version=3368
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE CSR.INTEGRATION_QUESTION_ANSWER_ID_SEQ;

-- Alter tables
ALTER TABLE CSR.INTEGRATION_QUESTION_ANSWER ADD (ID	NUMBER(10, 0));

UPDATE CSR.INTEGRATION_QUESTION_ANSWER
   SET ID = CSR.INTEGRATION_QUESTION_ANSWER_ID_SEQ.NEXTVAL;

ALTER TABLE CSR.INTEGRATION_QUESTION_ANSWER MODIFY (ID NOT NULL);

ALTER TABLE CSR.INTEGRATION_QUESTION_ANSWER ADD CONSTRAINT UK_INTEGRATION_QUESTION_ANSWER_ID UNIQUE (APP_SID, ID);

ALTER TABLE CSRIMP.INTEGRATION_QUESTION_ANSWER ADD (ID	NUMBER(10, 0));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
@@latestUD-9655_packages


DECLARE
	v_card_id NUMBER;
BEGIN
	security.user_pkg.logonadmin;
	chain.temp_card_pkg.RegisterCardGroup(68, 'Integration Question/Answers', 'Allows filtering of Integration Question/Answers.', 'csr.integration_question_answer_report_pkg', NULL);

	chain.temp_card_pkg.RegisterCard(
		'Integration Question Answer Filter', 
		'Credit360.Audit.Cards.IntegrationQuestionAnswerFilter',
		'/csr/site/audit/IntegrationQuestionAnswerFilter.js', 
		'Credit360.Audit.Filters.IntegrationQuestionAnswerFilter'
	);
	
	SELECT card_id INTO v_card_id FROM chain.card WHERE js_class_type = 'Credit360.Audit.Filters.IntegrationQuestionAnswerFilter'; 
	
	BEGIN
		INSERT INTO chain.filter_type
		(filter_type_id, description, helper_pkg, card_id)
		VALUES
		(chain.filter_type_id_seq.NEXTVAL, 'Integration Question Answer Filter', 'csr.integration_question_answer_report_pkg', v_card_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	chain.temp_card_pkg.RegisterCard(
		'Integration Question Answer Filter Adapter', 
		'Credit360.Audit.Cards.IntegrationQuestionAnswerFilterAdapter',
		'/csr/site/audit/IntegrationQuestionAnswerFilterAdapter.js', 
		'Credit360.Audit.Filters.IntegrationQuestionAnswerFilterAdapter'
	);
	
	SELECT card_id INTO v_card_id FROM chain.card WHERE js_class_type = 'Credit360.Audit.Filters.IntegrationQuestionAnswerFilterAdapter'; 
	
	BEGIN
		INSERT INTO chain.filter_type
		(filter_type_id, description, helper_pkg, card_id)
		VALUES
		(chain.filter_type_id_seq.NEXTVAL, 'Integration Question Answer Filter Adapter', 'csr.integration_question_answer_report_pkg', v_card_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
END;
/

DROP PACKAGE chain.temp_card_pkg;

BEGIN
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (68 /*chain.filter_pkg.FILTER_TYPE_INTEGRATION_QUESTION_ANSWER*/, 2 /*csr.integration_question_answer_report_pkg.AGG_TYPE_COUNT*/, 'Number of records');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	BEGIN
		INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
		VALUES (68 /*chain.filter_pkg.FILTER_TYPE_INTEGRATION_QUESTION_ANSWER*/, 2 /*csr.integration_question_answer_report_pkg.COL_TYPE_LAST_UPDATED*/, 2 /*chain.filter_pkg.COLUMN_TYPE_DATE*/, 'Last updated');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../integration_question_answer_pkg
@../integration_question_answer_report_pkg
@../enable_pkg
@../chain/filter_pkg

@../enable_body
@../integration_question_answer_body
@../integration_question_answer_report_body
@../schema_body
@../csrimp/imp_body

@update_tail
