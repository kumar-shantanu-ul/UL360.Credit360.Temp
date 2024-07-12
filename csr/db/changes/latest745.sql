-- Please update version.sql too -- this keeps clean builds in sync
define version=745
@update_header

DROP TYPE csr.T_QS_QUESTION_TABLE;

CREATE OR REPLACE TYPE csr.T_QS_QUESTION_ROW AS
	OBJECT (
		QUESTION_ID		NUMBER(10),
		PARENT_ID		NUMBER(10),
		POS				NUMBER(10), 
		LABEL			VARCHAR2(4000), 
		QUESTION_TYPE	VARCHAR2(40), 
		SCORE			NUMBER(10),
		LOOKUP_KEY		VARCHAR2(255),
		INVERT_SCORE	NUMBER(1)
	);
/
CREATE OR REPLACE TYPE csr.T_QS_QUESTION_TABLE AS
  TABLE OF csr.T_QS_QUESTION_ROW;
/


@..\quick_survey_pkg
@..\quick_survey_body

@update_tail
