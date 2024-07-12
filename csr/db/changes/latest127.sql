-- Please update version.sql too -- this keeps clean builds in sync
define version=127
@update_header

VARIABLE version NUMBER
BEGIN :version := 127; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
	
	SELECT db_version INTO v_version FROM security.version;
	IF v_version < 10 THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A *** SECURITY *** DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/

alter table pending_aggregate rename to pending_val_cache;


-- this is now provided by security
DROP TYPE T_SID_TABLE;

DROP TYPE T_DEP_SCAN_TABLE;
DROP TYPE T_DEP_SCAN_ROW;


DROP TYPE T_CALC_DEP_TABLE;
CREATE OR REPLACE TYPE T_CALC_DEP_ROW AS 
  OBJECT ( 
	DEP_TYPE					NUMBER(10,0),
	IND_SID						NUMBER(10,0),
	IND_TYPE					NUMBER(10,0),
	CALC_START_DTM_ADJUSTMENT	NUMBER(10,0)
  );
/
CREATE OR REPLACE TYPE T_CALC_DEP_TABLE AS 
  TABLE OF T_CALC_DEP_ROW;
/


DROP TYPE T_DATASOURCE_DEP_TABLE;
CREATE OR REPLACE TYPE T_DATASOURCE_DEP_ROW AS 
  OBJECT ( 
	SEEK_IND_SID    			NUMBER(10, 0),
	CALC_DEP_TYPE				NUMBER(10, 0),
	DEP_IND_SID     			NUMBER(10, 0),
	LVL         				NUMBER(10, 0),
	CALC_START_DTM_ADJUSTMENT	NUMBER(10,0)
  );
/
CREATE OR REPLACE TYPE T_DATASOURCE_DEP_TABLE AS 
  TABLE OF T_DATASOURCE_DEP_ROW;
/

--DROP TYPE T_RECALC_LOG_TABLE;
CREATE OR REPLACE TYPE T_RECALC_LOG_ROW AS 
  OBJECT ( 
	PENDING_IND_ID 			NUMBER(10, 0),
	PENDING_REGION_ID		NUMBER(10, 0),
	PENDING_PERIOD_ID     	NUMBER(10, 0),
	VAL_NUMBER		NUMBER(24,10)
  );
/
CREATE OR REPLACE TYPE T_RECALC_LOG_TABLE AS 
  TABLE OF T_RECALC_LOG_ROW;
/



alter table calc_ind_recalc_job rename to stored_calc_job;

-- 
-- TABLE: PVC_STORED_CALC_JOB 
--

CREATE TABLE PVC_STORED_CALC_JOB(
    PENDING_DATASET_ID     NUMBER(10, 0)    NOT NULL,
    CALC_PENDING_IND_ID    NUMBER(10, 0)    NOT NULL,
    PENDING_REGION_ID      NUMBER(10, 0)    NOT NULL,
    PENDING_PERIOD_ID      NUMBER(10, 0)    NOT NULL,
    PROCESSING             NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    CONSTRAINT PK378 PRIMARY KEY (PENDING_DATASET_ID, CALC_PENDING_IND_ID, PENDING_REGION_ID, PENDING_PERIOD_ID, PROCESSING)
)
;



-- 
-- TABLE: PVC_REGION_RECALC_JOB 
--

CREATE TABLE PVC_REGION_RECALC_JOB(
    PENDING_IND_ID        NUMBER(10, 0)    NOT NULL,
    PENDING_DATASET_ID    NUMBER(10, 0)    NOT NULL,
    PROCESSING            NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    CONSTRAINT PK379 PRIMARY KEY (PENDING_IND_ID, PENDING_DATASET_ID, PROCESSING)
)
;

-- 
-- TABLE: PVC_STORED_CALC_JOB 
--

ALTER TABLE PVC_STORED_CALC_JOB ADD CONSTRAINT RefPENDING_IND715 
    FOREIGN KEY (CALC_PENDING_IND_ID)
    REFERENCES PENDING_IND(PENDING_IND_ID)
;

ALTER TABLE PVC_STORED_CALC_JOB ADD CONSTRAINT RefPENDING_REGION716 
    FOREIGN KEY (PENDING_REGION_ID)
    REFERENCES PENDING_REGION(PENDING_REGION_ID)
;

ALTER TABLE PVC_STORED_CALC_JOB ADD CONSTRAINT RefPENDING_PERIOD717 
    FOREIGN KEY (PENDING_PERIOD_ID)
    REFERENCES PENDING_PERIOD(PENDING_PERIOD_ID)
;

ALTER TABLE PVC_STORED_CALC_JOB ADD CONSTRAINT RefPENDING_DATASET721 
    FOREIGN KEY (PENDING_DATASET_ID)
    REFERENCES PENDING_DATASET(PENDING_DATASET_ID)
;




-- 
-- TABLE: PVC_REGION_RECALC_JOB 
--

ALTER TABLE PVC_REGION_RECALC_JOB ADD CONSTRAINT RefPENDING_IND712 
    FOREIGN KEY (PENDING_IND_ID)
    REFERENCES PENDING_IND(PENDING_IND_ID)
;

ALTER TABLE PVC_REGION_RECALC_JOB ADD CONSTRAINT RefPENDING_DATASET722 
    FOREIGN KEY (PENDING_DATASET_ID)
    REFERENCES PENDING_DATASET(PENDING_DATASET_ID)
;





UPDATE version SET db_version = :version;
COMMIT;

@..\create_triggers
@..\create_views

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
 

@update_tail
