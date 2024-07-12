-- Please update version.sql too -- this keeps clean builds in sync
define version=1326
@update_header

CREATE SEQUENCE CSR.SUPPLIER_SCORE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

ALTER TABLE CSR.SUPPLIER ADD LAST_SUPPLIER_SCORE_ID    NUMBER(10, 0);

CREATE TABLE CSR.SUPPLIER_SCORE(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SUPPLIER_SCORE_ID     NUMBER(10, 0)    NOT NULL,
    SUPPLIER_SID          NUMBER(10, 0)    NOT NULL,
    SCORE_THRESHOLD_ID    NUMBER(10, 0),
    SET_DTM               DATE             DEFAULT SYSDATE NOT NULL,
    SCORE                 NUMBER(15, 5),
    CONSTRAINT PK_SUPPLIER_SCORE PRIMARY KEY (APP_SID, SUPPLIER_SCORE_ID)
)
;

ALTER TABLE CSR.QUICK_SURVEY_TYPE ADD(
    HELPER_PKG              VARCHAR2(255)
)
;

CREATE INDEX CSR.IX_SUP_LAST_SCORE_ID ON CSR.SUPPLIER(APP_SID, LAST_SUPPLIER_SCORE_ID)
;

CREATE INDEX CSR.IX_SUP_SCORE_THRESH_ID ON CSR.SUPPLIER_SCORE(APP_SID, SCORE_THRESHOLD_ID)
;

CREATE INDEX CSR.IX_SUP_SCORE_SUPPLIER_SID ON CSR.SUPPLIER_SCORE(APP_SID, SUPPLIER_SID)
;

ALTER TABLE CSR.SUPPLIER DROP CONSTRAINT FK_SUPPLIER_THRESHOLD;

ALTER TABLE CSR.SUPPLIER ADD CONSTRAINT FK_SUP_LAST_SCORE_ID 
    FOREIGN KEY (APP_SID, LAST_SUPPLIER_SCORE_ID)
    REFERENCES CSR.SUPPLIER_SCORE(APP_SID, SUPPLIER_SCORE_ID)
;

ALTER TABLE CSR.SUPPLIER_SCORE ADD CONSTRAINT FK_SUP_SCORE_SUPPLIER_SID 
    FOREIGN KEY (APP_SID, SUPPLIER_SID)
    REFERENCES CSR.SUPPLIER(APP_SID, SUPPLIER_SID)
;

ALTER TABLE CSR.SUPPLIER_SCORE ADD CONSTRAINT FK_SUP_SCORE_THRESH_ID 
    FOREIGN KEY (APP_SID, SCORE_THRESHOLD_ID)
    REFERENCES CSR.SCORE_THRESHOLD(APP_SID, SCORE_THRESHOLD_ID)
;

INSERT INTO csr.supplier_score (app_sid, supplier_score_id, supplier_sid, score_threshold_id, set_dtm, score)
SELECT app_sid, csr.supplier_score_id_seq.NEXTVAL, supplier_sid, score_threshold_id, score_last_changed, score
  FROM csr.supplier
 WHERE (score IS NOT NULL OR score_threshold_id IS NOT NULL OR score_last_changed IS NOT NULL);

UPDATE csr.supplier s
   SET last_supplier_score_id = (
	SELECT supplier_score_id
	  FROM csr.supplier_score sc
	 WHERE s.supplier_sid = sc.supplier_sid
);

-- Finally (after I'm sure everything has moved over)
--ALTER TABLE CSR.SUPPLIER DROP COLUMN SCORE;
--ALTER TABLE CSR.SUPPLIER DROP COLUMN SCORE_LAST_CHANGED;
--ALTER TABLE CSR.SUPPLIER DROP COLUMN SCORE_THRESHOLD_ID;

CREATE OR REPLACE VIEW csr.v$supplier AS
	SELECT s.app_sid, s.supplier_sid, s.region_sid, s.logo_file_sid, s.recipient_sid, s.last_supplier_score_id,
		   sc.score, sc.set_dtm score_last_changed, sc.score_threshold_id
	  FROM supplier s
	  LEFT JOIN supplier_score sc ON s.supplier_sid = sc.supplier_sid AND s.last_supplier_score_id = sc.supplier_score_id;

GRANT SELECT ON csr.v$supplier TO chain;

@..\quick_survey_pkg
@..\supplier_pkg

@..\quick_survey_body
@..\supplier_body
@..\chain\dashboard_body
@..\chain\report_body

@update_tail
