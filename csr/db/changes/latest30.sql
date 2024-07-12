-- Please update version.sql too -- this keeps clean builds in sync
define version=30
@update_header

alter table region add (
    PCT_OWNERSHIP         NUMBER(8, 4)      DEFAULT 1 NOT NULL);


INSERT INTO alert_template
SELECT a.alert_type_id, c.csr_root_sid, REPLACE(a.mail_body,'starbucks.credit360.com', c.host), 'Data you are involved with has changed in CRedit360' , mail_from_name, once_only, active
  FROM alert_template a, customer c
 WHERE a.csr_root_sid = 713559 AND c.csr_root_sid != a.csr_root_sid 
   AND alert_type_id = 4;





alter table source_type add (
    ERROR_URL         VARCHAR2(128) null);


CREATE TABLE SOURCE_TYPE_ERROR_CODE(
    SOURCE_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    ERROR_CODE        NUMBER(10, 0)    NOT NULL,
    LABEL	      VARCHAR2(128)    NOT NULL,
    DETAIL_URL        VARCHAR2(128),
    CONSTRAINT PK158 PRIMARY KEY (SOURCE_TYPE_ID, ERROR_CODE)
);



ALTER TABLE ERROR_LOG ADD (
    ERROR_CODE        NUMBER(10, 0)     NULL
);

BEGIN
INSERT INTO SOURCE_TYPE_ERROR_CODE ( SOURCE_TYPE_ID, ERROR_CODE, LABEL, DETAIL_URL ) VALUES	(5, 0, 'Blocked', '/csr/site/dataExplorer/dataNavigator.acds?valId=%VALID%');
INSERT INTO SOURCE_TYPE_ERROR_CODE ( SOURCE_TYPE_ID, ERROR_CODE, LABEL, DETAIL_URL ) VALUES	(5, 1, 'Aggregation failure', NULL);
END;
/


UPDATE ERROR_LOG SET ERROR_CODE = 0;

ALTER TABLE ERROR_LOG MODIFY ERROR_CODE NOT NULL;


ALTER TABLE ERROR_LOG DROP CONSTRAINT REFSOURCE_TYPE196;

ALTER TABLE ERROR_LOG ADD CONSTRAINT RefSOURCE_TYPE_ERROR_CODE254 
    FOREIGN KEY (SOURCE_TYPE_ID, ERROR_CODE)
    REFERENCES SOURCE_TYPE_ERROR_CODE(SOURCE_TYPE_ID, ERROR_CODE);

       
-- Queue a job for the aggregation package
DECLARE
    job BINARY_INTEGER;
BEGIN
	-- now and every 60 seconds afterwards
    -- 10g w/low_priority_job created
	DBMS_SCHEDULER.CREATE_JOB (
	   job_name             => 'csr.AggregateAllTrees',
	   job_type             => 'PLSQL_BLOCK',
	   job_action           => 'region_pkg.AggregateAllTrees;',
	   job_class		=> 'low_priority_job',
	   repeat_interval	=> 'FREQ=MINUTELY',
	   enabled              => TRUE,
	   auto_drop            => FALSE,
	   comments             => 'Aggregate CSR region trees');
   	COMMIT;
END;
/


alter table customer add (aggregate_active number(1) default 1);

CREATE INDEX CSR.IND_PARENT_SID ON CSR.IND
(PARENT_SID);

@update_tail
