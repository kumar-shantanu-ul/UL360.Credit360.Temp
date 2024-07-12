-- Please update version.sql too -- this keeps clean builds in sync
define version=1400
@update_header

CREATE TABLE CSR.QUICK_SURVEY_SCORE_THRESHOLD(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SURVEY_SID            NUMBER(10, 0)    NOT NULL,
    SCORE_THRESHOLD_ID    NUMBER(10, 0)    NOT NULL,
    MAPS_TO_IND_SID       NUMBER(10, 0),
    CONSTRAINT PK_QUICK_SURVEY_SCORE_THRESHOL PRIMARY KEY (APP_SID, SURVEY_SID, SCORE_THRESHOLD_ID)
)
;

ALTER TABLE CSR.QUICK_SURVEY ADD (
	SUBMISSION_PERIOD_START         DATE,
	SUBMISSION_PERIOD_END_OFFSET    NUMBER(10, 0),
    SUBMISSION_PERIOD_END_UOM       VARCHAR2(1),
    CONSTRAINT CHK_QS_END_UOM_VALID CHECK (SUBMISSION_PERIOD_END_UOM IN ('D', 'M', 'Y')),
	CONSTRAINT CHK_QUICK_SURVEY_PERIOD_OFFSET CHECK (
		(SUBMISSION_PERIOD_END_OFFSET IS NULL AND SUBMISSION_PERIOD_END_UOM IS NULL)
		OR
		(SUBMISSION_PERIOD_END_OFFSET IS NOT NULL AND SUBMISSION_PERIOD_END_UOM IS NOT NULL)
	),
    CONSTRAINT CHK_QS_END_OFFSET_POSITIVE CHECK (SUBMISSION_PERIOD_END_OFFSET > 0)
);

ALTER TABLE CSR.QUICK_SURVEY_SUBMISSION ADD (
	PERIOD_START_DTM         DATE,
    PERIOD_END_DTM           DATE
);

ALTER TABLE CSR.QUICK_SURVEY_QUESTION ADD (
	IND_FOR_SCORE_THRESHOLD_ID    NUMBER(10, 0)
);

-- i don't think that we need to tie to the most recent submission - all current and 
-- historic submissions can have the period set to the current region_survey_response period
UPDATE CSR.QUICK_SURVEY_SUBMISSION o
   SET (period_start_dtm, period_end_dtm) = (
   		SELECT period_start_dtm, period_end_dtm
   		  FROM CSR.REGION_SURVEY_RESPONSE i
   		 WHERE i.app_sid = o.app_sid
   		   AND i.survey_response_id = o.survey_response_id
   )
 WHERE (app_sid, survey_response_id) IN (
 	SELECT app_sid, survey_response_id
 	  FROM CSR.REGION_SURVEY_RESPONSE
 )
   AND submission_id <> 0;

-- i don't think that we need to tie to the most recent submission - all current and 
-- historic submissions can have the period set to the current supplier_survey_response period
UPDATE CSR.QUICK_SURVEY_SUBMISSION o
   SET (period_start_dtm, period_end_dtm) = (
   		SELECT period_start_dtm, period_end_dtm
   		  FROM CSR.SUPPLIER_SURVEY_RESPONSE i
   		 WHERE i.app_sid = o.app_sid
   		   AND i.survey_response_id = o.survey_response_id
   )
 WHERE (app_sid, survey_response_id) IN (
  	SELECT app_sid, survey_response_id
  	  FROM CSR.SUPPLIER_SURVEY_RESPONSE 
 )
   AND submission_id <> 0;
   
-- clean up historic entries 
DELETE FROM csr.supplier_survey_response 
 WHERE survey_response_id IN (
 	SELECT min_response_id 
 	  FROM (
 	  	SELECT app_sid, supplier_sid, survey_sid, min(survey_response_id) min_response_id, COUNT(*) cnt 
 	  	  FROM csr.supplier_survey_response 
 	  	 GROUP BY app_sid, supplier_sid, survey_sid
 	  	) 
 	 WHERE cnt>1
 );

UPDATE CSR.QUICK_SURVEY o
   SET (submission_period_start, submission_period_end_offset, submission_period_end_uom) = (
   		SELECT UNIQUE period_start_dtm, 1, 'Y'
   		  FROM CSR.SUPPLIER_SURVEY_RESPONSE i
   		 WHERE i.survey_sid = o.survey_sid
   		   AND period_start_dtm IS NOT NULL
   )
 WHERE o.survey_sid IN (
	SELECT survey_sid
 	  FROM CSR.SUPPLIER_SURVEY_RESPONSE
     WHERE period_start_dtm IS NOT NULL
 );

ALTER TABLE CSR.SUPPLIER_SURVEY_RESPONSE DROP CONSTRAINT PK_SUPPLIER_SURVEY_RESPONSE;

DECLARE
	v_count number;
BEGIN
	SELECT count(*) 
	  INTO v_count
	  FROM all_indexes 
	 WHERE index_name = 'PK_SUPPLIER_SURVEY_RESPONSE'
	   AND owner = 'CSR';
	
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'DROP INDEX CSR.PK_SUPPLIER_SURVEY_RESPONSE';
	END IF;
END;
/

ALTER TABLE CSR.SUPPLIER_SURVEY_RESPONSE ADD CONSTRAINT PK_SUPPLIER_SURVEY_RESPONSE PRIMARY KEY (APP_SID, SUPPLIER_SID, SURVEY_SID);

-- these columns can be removed once Xpj is happy with the changes
ALTER TABLE CSR.SUPPLIER_SURVEY_RESPONSE MODIFY PERIOD_START_DTM NULL;
ALTER TABLE CSR.SUPPLIER_SURVEY_RESPONSE MODIFY PERIOD_END_DTM NULL;
ALTER TABLE CSR.SUPPLIER_SURVEY_RESPONSE RENAME COLUMN PERIOD_START_DTM TO DEP_PERIOD_START_DTM;
ALTER TABLE CSR.SUPPLIER_SURVEY_RESPONSE RENAME COLUMN PERIOD_END_DTM TO DEP_PERIOD_END_DTM;

ALTER TABLE CSR.QUICK_SURVEY_SCORE_THRESHOLD ADD CONSTRAINT FK_IND_QSST 
    FOREIGN KEY (APP_SID, MAPS_TO_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.QUICK_SURVEY_SCORE_THRESHOLD ADD CONSTRAINT FK_QS_QSST 
    FOREIGN KEY (APP_SID, SURVEY_SID)
    REFERENCES CSR.QUICK_SURVEY(APP_SID, SURVEY_SID)
;

ALTER TABLE CSR.QUICK_SURVEY_SCORE_THRESHOLD ADD CONSTRAINT FK_ST_QSST 
    FOREIGN KEY (APP_SID, SCORE_THRESHOLD_ID)
    REFERENCES CSR.SCORE_THRESHOLD(APP_SID, SCORE_THRESHOLD_ID)
;

ALTER TABLE CSR.QUICK_SURVEY_QUESTION ADD CONSTRAINT FK_ST_QS_QUESTION 
    FOREIGN KEY (APP_SID, IND_FOR_SCORE_THRESHOLD_ID)
    REFERENCES CSR.SCORE_THRESHOLD(APP_SID, SCORE_THRESHOLD_ID)
;

DROP TABLE CSR.TEMP_RESPONSE_REGION;

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_RESPONSE_REGION
(
	RESPONSE_ID			NUMBER(10)	NOT NULL,
	REGION_SID			NUMBER(10)	NOT NULL,
	SUBMISSION_ID		NUMBER(10)  NOT NULL,
	PERIOD_START_DTM	DATE		NOT NULL,
	PERIOD_END_DTM		DATE		NOT NULL,
	CONSTRAINT PK_TEMP_RESPONSE_REGION PRIMARY KEY (RESPONSE_ID)
) ON COMMIT DELETE ROWS;

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'QUICK_SURVEY_SCORE_THRESHOLD',
		policy_name     => 'QUICK_SURVEY_SCORE_THRE_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/


@..\quick_survey_body
@..\supplier_body

@update_tail
