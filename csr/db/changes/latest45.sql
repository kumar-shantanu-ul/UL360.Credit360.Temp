-- Please update version.sql too -- this keeps clean builds in sync
define version=45
@update_header


CREATE UNIQUE INDEX PK_ALT_TAG_GROUP ON TAG_GROUP(CSR_ROOT_SID, LOWER(NAME))
TABLESPACE INDX
;


ALTER TABLE SHEET_VALUE ADD (
  UNIQUE (SHEET_ID, IND_SID, REGION_SID));


-- TABLE: PERIOD_LOCK 
--

CREATE TABLE PERIOD_LOCK(
    CSR_ROOT_SID    NUMBER(10, 0)    NOT NULL,
    START_DTM       DATE             NOT NULL,
    END_DTM         DATE             NOT NULL,
    CONSTRAINT PK204 PRIMARY KEY (CSR_ROOT_SID, START_DTM, END_DTM)
)
;


ALTER TABLE PERIOD_LOCK ADD CONSTRAINT RefCUSTOMER349 
    FOREIGN KEY (CSR_ROOT_SID)
    REFERENCES CUSTOMER(CSR_ROOT_SID)
;


-- insert a bunch of period locks
DECLARE
	v_extent_start_dtm		PERIOD_LOCK.start_dtm%TYPE;
	v_extent_end_dtm		PERIOD_LOCK.end_dtm%TYPE;
BEGIN
	FOR r IN (
		SELECT csr_root_sid, TRUNC(period_start_dtm, 'q') start_dtm, TRUNC(ADD_MONTHS(period_end_dtm,3),'q') end_dtm
		  FROM VAL v, IND i
		 WHERE v.ind_sid = i.ind_sid
		   AND LOCKED = 1                   
		   GROUP BY csr_root_sid, TRUNC(period_start_dtm, 'q'), TRUNC(ADD_MONTHS(period_end_dtm,3),'q')
		  ORDER BY TRUNC(period_start_dtm, 'q')	)
	LOOP
		SELECT NVL(MIN(start_dtm), r.start_dtm), NVL(MAX(end_dtm), r.end_dtm)
		  INTO v_extent_start_dtm, v_extent_end_dtm
		  FROM PERIOD_LOCK
		 WHERE csr_root_sid = r.csr_root_sid
		   AND start_dtm <= r.end_dtm
		   AND end_dtm >= r.start_dtm;		
		-- delete any locks
		DELETE FROM PERIOD_LOCK
		 WHERE csr_root_sid = r.csr_root_sid
		   AND start_dtm >= v_extent_start_dtm
		   AND end_dtm <= v_extent_end_dtm;		
		-- replace with single lock covering the extent
		INSERT INTO PERIOD_LOCK 
			(csr_root_sid, start_dtm, end_dtm)
		VALUES
			(r.csr_root_sid, v_extent_start_dtm, v_extent_end_dtm);
	END LOOP;
END;
/
COMMIT;

-- drop locked column
alter table val drop column locked;

@update_tail
