-- Please update version.sql too -- this keeps clean builds in sync
define version=725
@update_header

INSERT INTO csr.QS_QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('files', 'Files', null);
INSERT INTO csr.QS_QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('richtext', 'Text area', null);

@update_tail
