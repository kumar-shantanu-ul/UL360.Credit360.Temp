-- Please update version.sql too -- this keeps clean builds in sync
define version=1318
@update_header

BEGIN
	FOR r IN (
		SELECT constraint_name FROM all_constraints WHERE owner='CSR' AND table_name = 'ISSUE' AND r_constraint_name = 'PK642'
	) LOOP
		-- Account for constraint_name being different on live than create script
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.ISSUE DROP CONSTRAINT '||r.constraint_name;
	END LOOP;
END;
/

ALTER TABLE CSR.ISSUE_SURVEY_ANSWER DROP CONSTRAINT RefQUICK_SURVEY_ANSWER1301;

ALTER TABLE CSR.ISSUE_SURVEY_ANSWER DROP CONSTRAINT RefCUSTOMER1302;

ALTER TABLE CSR.QS_ANSWER_FILE DROP CONSTRAINT RefQUICK_SURVEY_ANSWER2193;

ALTER TABLE CSR.QS_ANSWER_LOG DROP CONSTRAINT RefQUICK_SURVEY_ANSWER1306;

ALTER TABLE CSR.QUICK_SURVEY_ANSWER DROP CONSTRAINT RefQUICK_SURVEY_RESPONSE1308;

ALTER TABLE CSR.QUICK_SURVEY_RESPONSE DROP CONSTRAINT FK_QS_RESP_THRESHOLD;

CREATE SEQUENCE CSR.QS_SUBMISSION_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

ALTER TABLE CSR.QS_ANSWER_LOG ADD (
    SUBMISSION_ID         NUMBER(10, 0)     DEFAULT 0 NOT NULL
);

CREATE TABLE CSR.QS_SUBMISSION_FILE(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    QS_ANSWER_FILE_ID     NUMBER(10, 0)    NOT NULL,
    SURVEY_RESPONSE_ID    NUMBER(10, 0)    NOT NULL,
    SUBMISSION_ID         NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    CONSTRAINT PK_QS_SUBMISSION_FILE PRIMARY KEY (APP_SID, QS_ANSWER_FILE_ID, SURVEY_RESPONSE_ID, SUBMISSION_ID)
)
;

BEGIN
	FOR r IN (
		SELECT constraint_name FROM all_constraints WHERE owner='CSR' AND table_name = 'QUICK_SURVEY_ANSWER' AND constraint_type = 'P'
	) LOOP
		-- Account for constraint_name being different on live than create script
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.QUICK_SURVEY_ANSWER DROP CONSTRAINT '||r.constraint_name||' DROP INDEX';
	END LOOP;
END;
/

ALTER TABLE CSR.QUICK_SURVEY_ANSWER ADD (
    SUBMISSION_ID            NUMBER(10, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT PK_QUICK_SURVEY_RESP_ANSWR PRIMARY KEY (APP_SID, SURVEY_RESPONSE_ID, QUESTION_ID, SUBMISSION_ID)
);

ALTER TABLE CSR.QUICK_SURVEY_RESPONSE ADD (
	LAST_SUBMISSION_ID       NUMBER(10, 0)
);

CREATE TABLE CSR.QUICK_SURVEY_SUBMISSION(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SURVEY_RESPONSE_ID    NUMBER(10, 0)    NOT NULL,
    SUBMISSION_ID         NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    SUBMITTED_DTM         DATE,
    SUBMITTED_BY_USER_SID NUMBER(10, 0),
    OVERALL_SCORE         NUMBER(15, 5),
    OVERALL_MAX_SCORE     NUMBER(15, 5),
    SCORE_THRESHOLD_ID    NUMBER(10, 0),
    CONSTRAINT PK_QUICK_SURVEY_SUBMISSION PRIMARY KEY (APP_SID, SURVEY_RESPONSE_ID, SUBMISSION_ID)
)
;

CREATE INDEX CSR.IX_ISS_SURV_ANS_RESP_ID ON CSR.ISSUE_SURVEY_ANSWER(APP_SID, SURVEY_RESPONSE_ID)
;

CREATE INDEX CSR.IX_ISS_SURV_ANS_QSN_ID ON CSR.ISSUE_SURVEY_ANSWER(APP_SID, QUESTION_ID)
;

CREATE INDEX CSR.IX_QS_ANS_FILE_RESP_ID ON CSR.QS_ANSWER_FILE(APP_SID, SURVEY_RESPONSE_ID)
;

CREATE INDEX CSR.IX_QS_ANS_FILE_QSN_ID ON CSR.QS_ANSWER_FILE(APP_SID, QUESTION_ID)
;

CREATE INDEX CSR.IX_QS_ANS_LOG_ANS ON CSR.QS_ANSWER_LOG(APP_SID, SURVEY_RESPONSE_ID, QUESTION_ID, SUBMISSION_ID)
;

CREATE INDEX CSR.IX_QS_ANSWER_SUBMSN ON CSR.QUICK_SURVEY_ANSWER(APP_SID, SURVEY_RESPONSE_ID, SUBMISSION_ID)
;

CREATE INDEX CSR.IX_QSR_LAST_SUBMSN_ID ON CSR.QUICK_SURVEY_RESPONSE(APP_SID, SURVEY_RESPONSE_ID, LAST_SUBMISSION_ID)
;

CREATE INDEX CSR.IX_QSS_THRES_ID ON CSR.QUICK_SURVEY_SUBMISSION(APP_SID, SCORE_THRESHOLD_ID)
;

INSERT INTO csr.quick_survey_submission (app_sid, survey_response_id, submission_id, submitted_dtm, overall_score, overall_max_score, score_threshold_id)
SELECT app_sid, survey_response_id, 0, null, overall_score, overall_max_score, score_threshold_id
  FROM csr.quick_survey_response;

INSERT INTO csr.quick_survey_submission (app_sid, survey_response_id, submission_id, submitted_dtm, overall_score, overall_max_score, score_threshold_id)
SELECT app_sid, survey_response_id, csr.qs_submission_id_seq.NEXTVAL, submitted_dtm, overall_score, overall_max_score, score_threshold_id
  FROM csr.quick_survey_response
 WHERE submitted_dtm IS NOT NULL;

UPDATE csr.quick_survey_response u
   SET last_submission_id = (
	SELECT qss.submission_id
	  FROM csr.quick_survey_submission qss
	 WHERE qss.survey_response_id = u.survey_response_id AND qss.app_sid = u.app_sid
	   AND qss.submission_id > 0
   );

INSERT INTO csr.quick_survey_answer (app_sid, survey_response_id, submission_id, question_id, note, score, question_option_id, val_number, measure_conversion_id, measure_sid, region_sid, answer, html_display, max_score, version_stamp)
SELECT qsa.app_sid, qsa.survey_response_id, qss.submission_id, qsa.question_id, qsa.note, qsa.score, qsa.question_option_id, qsa.val_number, qsa.measure_conversion_id, qsa.measure_sid, qsa.region_sid, qsa.answer, qsa.html_display, qsa.max_score, qsa.version_stamp
  FROM csr.quick_survey_answer qsa
  JOIN csr.quick_survey_submission qss ON qsa.survey_response_id = qss.survey_response_id AND qsa.app_sid = qss.app_sid
 WHERE qss.submission_id > 0;

INSERT INTO csr.qs_submission_file (app_sid, qs_answer_file_id, survey_response_id, submission_id)
SELECT af.app_sid, af.qs_answer_file_id, af.survey_response_id, qss.submission_id
  FROM csr.qs_answer_file af
  JOIN csr.quick_survey_submission qss ON af.survey_response_id = qss.survey_response_id;

ALTER TABLE CSR.ISSUE ADD CONSTRAINT FK_ISS_ISS_SURV_ANS 
    FOREIGN KEY (APP_SID, ISSUE_SURVEY_ANSWER_ID)
    REFERENCES CSR.ISSUE_SURVEY_ANSWER(APP_SID, ISSUE_SURVEY_ANSWER_ID)
;

ALTER TABLE CSR.ISSUE_SURVEY_ANSWER ADD CONSTRAINT FK_ISS_SURV_ANS_APP 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.ISSUE_SURVEY_ANSWER ADD CONSTRAINT FK_ISS_SURV_ANS_QSTN 
    FOREIGN KEY (APP_SID, QUESTION_ID)
    REFERENCES CSR.QUICK_SURVEY_QUESTION(APP_SID, QUESTION_ID)
;

ALTER TABLE CSR.ISSUE_SURVEY_ANSWER ADD CONSTRAINT FK_ISS_SURV_ANS_RESP 
    FOREIGN KEY (APP_SID, SURVEY_RESPONSE_ID)
    REFERENCES CSR.QUICK_SURVEY_RESPONSE(APP_SID, SURVEY_RESPONSE_ID)
;

ALTER TABLE CSR.QS_ANSWER_FILE ADD CONSTRAINT FK_QS_ANS_FILE_QSTN_ID 
    FOREIGN KEY (APP_SID, QUESTION_ID)
    REFERENCES CSR.QUICK_SURVEY_QUESTION(APP_SID, QUESTION_ID)
;

ALTER TABLE CSR.QS_ANSWER_FILE ADD CONSTRAINT FK_QS_ANS_FILE_RESP_ID 
    FOREIGN KEY (APP_SID, SURVEY_RESPONSE_ID)
    REFERENCES CSR.QUICK_SURVEY_RESPONSE(APP_SID, SURVEY_RESPONSE_ID)
;

ALTER TABLE CSR.QS_ANSWER_LOG ADD CONSTRAINT FK_QSA_LOG_QSA 
    FOREIGN KEY (APP_SID, SURVEY_RESPONSE_ID, QUESTION_ID, SUBMISSION_ID)
    REFERENCES CSR.QUICK_SURVEY_ANSWER(APP_SID, SURVEY_RESPONSE_ID, QUESTION_ID, SUBMISSION_ID)
;

ALTER TABLE CSR.QS_SUBMISSION_FILE ADD CONSTRAINT FK_QS_SUBMSN_FILE_FILE 
    FOREIGN KEY (APP_SID, QS_ANSWER_FILE_ID)
    REFERENCES CSR.QS_ANSWER_FILE(APP_SID, QS_ANSWER_FILE_ID)
;

ALTER TABLE CSR.QS_SUBMISSION_FILE ADD CONSTRAINT FK_SUBMSN_FILE_QSS 
    FOREIGN KEY (APP_SID, SURVEY_RESPONSE_ID, SUBMISSION_ID)
    REFERENCES CSR.QUICK_SURVEY_SUBMISSION(APP_SID, SURVEY_RESPONSE_ID, SUBMISSION_ID)
;

ALTER TABLE CSR.QUICK_SURVEY_ANSWER ADD CONSTRAINT FK_QSA_SUBMSN_ID 
    FOREIGN KEY (APP_SID, SURVEY_RESPONSE_ID, SUBMISSION_ID)
    REFERENCES CSR.QUICK_SURVEY_SUBMISSION(APP_SID, SURVEY_RESPONSE_ID, SUBMISSION_ID)
;

ALTER TABLE CSR.QUICK_SURVEY_RESPONSE ADD CONSTRAINT FK_QS_RESP_LAST_SUBMSN 
    FOREIGN KEY (APP_SID, SURVEY_RESPONSE_ID, LAST_SUBMISSION_ID)
    REFERENCES CSR.QUICK_SURVEY_SUBMISSION(APP_SID, SURVEY_RESPONSE_ID, SUBMISSION_ID)
;

ALTER TABLE CSR.QUICK_SURVEY_SUBMISSION ADD CONSTRAINT FK_QSS_RESP_ID 
    FOREIGN KEY (APP_SID, SURVEY_RESPONSE_ID)
    REFERENCES CSR.QUICK_SURVEY_RESPONSE(APP_SID, SURVEY_RESPONSE_ID)
;

ALTER TABLE CSR.QUICK_SURVEY_SUBMISSION ADD CONSTRAINT FK_QSS_SCORE_THRESH 
    FOREIGN KEY (APP_SID, SCORE_THRESHOLD_ID)
    REFERENCES CSR.SCORE_THRESHOLD(APP_SID, SCORE_THRESHOLD_ID)
;

CREATE OR REPLACE VIEW csr.v$quick_survey_response AS
	SELECT qsr.app_sid, qsr.survey_response_id, qsr.survey_sid, qsr.user_sid, qsr.user_name,
		   qsr.created_dtm, qsr.guid, qss.submitted_dtm, qsr.qs_response_status_id,
		   qsr.qs_campaign_sid, qss.overall_score, qss.overall_max_score, qss.score_threshold_id,
		   qss.submission_id
	  FROM quick_survey_response qsr 
	  JOIN quick_survey_submission qss ON NVL(qsr.last_submission_id, 0) = qss.submission_id;

CREATE OR REPLACE VIEW csr.v$qs_answer_file AS
	SELECT af.app_sid, af.qs_answer_file_id, af.survey_response_id, af.question_id, af.filename,
		   af.mime_type, af.data, af.sha1, af.uploaded_dtm, sf.submission_id
	  FROM qs_answer_file af
	  JOIN qs_submission_file sf ON af.qs_answer_file_id = sf.qs_answer_file_id;

CREATE OR REPLACE VIEW csr.v$quick_survey_answer AS
	SELECT qsa.app_sid, qsa.survey_response_id, qsa.question_id, qsa.note, qsa.score, qsa.question_option_id,
		   qsa.val_number, qsa.measure_conversion_id, qsa.measure_sid, qsa.region_sid, qsa.answer,
		   qsa.html_display, qsa.max_score, qsa.version_stamp, qsa.submission_id
	  FROM quick_survey_answer qsa
	  JOIN v$quick_survey_response qsr ON qsa.survey_response_id = qsr.survey_response_id AND qsa.submission_id = qsr.submission_id;

@..\quick_survey_pkg
@..\supplier_pkg

@..\supplier_body
@..\quick_survey_body
@..\audit_body
@..\campaign_body
@..\chain\questionnaire_body

-- Finally - will run this in a follow-up change script just in case we need to roll back
--ALTER TABLE CSR.QUICK_SURVEY_RESPONSE DROP COLUMN SUBMITTED_DTM;
--ALTER TABLE CSR.QUICK_SURVEY_RESPONSE DROP COLUMN OVERALL_SCORE;
--ALTER TABLE CSR.QUICK_SURVEY_RESPONSE DROP COLUMN OVERALL_MAX_SCORE;
--ALTER TABLE CSR.QUICK_SURVEY_RESPONSE DROP COLUMN SCORE_THRESHOLD_ID;
--ALTER TABLE CSR.QUICK_SURVEY_RESPONSE DROP COLUMN FIRST_RESPONSE_DTM;


@update_tail
