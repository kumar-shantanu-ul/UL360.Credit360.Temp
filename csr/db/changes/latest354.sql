-- Please update version.sql too -- this keeps clean builds in sync
define version=354
@update_header

connect security/security@&_CONNECT_IDENTIFIER
grant select, references on security.web_resource to csr;


connect csr/csr@&_CONNECT_IDENTIFIER
ALTER TABLE QUICK_SURVEY ADD (
	label		VARCHAR2(256),
	start_dtm	DATE,
	end_dtm		DATE,
	created_dtm	DATE DEFAULT SYSDATE
);

ALTER TABLE QUICK_SURVEY_RESPONSE_ANSWER
 MODIFY QUESTION_CODE VARCHAR2(64);

@../quick_survey_pkg
@../quick_survey_body

@update_tail
