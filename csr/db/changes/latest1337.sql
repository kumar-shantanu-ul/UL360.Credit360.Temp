-- Please update version.sql too -- this keeps clean builds in sync
define version=1337
@update_header

CREATE TABLE csrimp.map_issue_survey_answer (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_issue_survey_answer_id		NUMBER(10)	NOT NULL,
	new_issue_survey_answer_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_issue_survey_answer PRIMARY KEY (old_issue_survey_answer_id) USING INDEX,
	CONSTRAINT uk_map_issue_survey_answer UNIQUE (new_issue_survey_answer_id) USING INDEX,
    CONSTRAINT FK_MAP_ISSUE_SURVEY_ANSWER_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_issue_non_compliance (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_issue_non_compliance_id		NUMBER(10)	NOT NULL,
	new_issue_non_compliance_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_issue_non_compliance PRIMARY KEY (old_issue_non_compliance_id) USING INDEX,
	CONSTRAINT uk_map_issue_non_compliance UNIQUE (new_issue_non_compliance_id) USING INDEX,
    CONSTRAINT FK_MAP_ISSUE_NON_COMPL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

@../schema_pkg
@../schema_body
@../csrimp/imp_pkg
@../csrimp/imp_body

@update_tail
