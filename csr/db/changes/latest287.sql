-- Please update version.sql too -- this keeps clean builds in sync
define version=287
@update_header

ALTER TABLE APPROVAL_STEP_SHEET ADD (
	REMINDER_DTM                 DATE,
    REMINDER_SENT_DTM            DATE,
    OVERDUE_SENT_DTM             DATE
);


BEGIN
	FOR r IN (
		select apsh.rowid rid, default_due_dtm 
		  from pending_period pp, approval_step_sheet apsh 
		 where pp.pending_period_id = apsh.pending_period_Id
		   and due_dtm is null
	)
	LOOP
		UPDATE APPROVAL_STEP_SHEET 
		   SET DUE_DTM = r.default_due_Dtm
		 WHERE ROWID = r.rid;
	END LOOP;
END;
/


-- 5 days will do
UPDATE APPROVAL_STEP_SHEET SET REMINDER_DTM = pending_pkg.SubtractWorkingDays(DUE_DTM, 5);
		 

ALTER TABLE APPROVAL_STEP_SHEET MODIFY REMINDER_DTM NOT NULL;


-- (change for supplier)
ALTER TABLE CSR_USER ADD (                        
   PHONE_NUMBER                   VARCHAR2(100),
   JOB_TITLE                      VARCHAR2(100)
);
 
 
ALTER TABLE SNAPSHOT ADD(
    TITLE                    VARCHAR2(1024),
    DESCRIPTION              VARCHAR2(1024),
    NEXT_UPDATE_AFTER_DTM    DATE    ,
    REFRESH_FREQ             NUMBER(10, 0)     DEFAULT 7 ,
    START_DTM                DATE          ,
    END_DTM                  DATE          ,
    INTERVAL                 CHAR(1)          DEFAULT 'y' 
); 

BEGIN
    UPDATE snapshot 
       SET title = name, refresh_freq = 7, next_update_after_dtm = sysdate;
    FOR r IN (
        SELECT substr(table_name,4) name
          FROM user_tables 
         WHERE table_name 
          LIKE 'SS$_%' ESCAPE '$' 
           AND table_name NOT LIKE '%$_PERIOD' ESCAPE '$'
    )
    LOOP
        EXECUTE IMMEDIATE 'UPDATE snapshot SET (start_dtm, end_dtm, interval) = ('||
            'SELECT MIN(start_dtm) start_dtm, MAX(end_dtm) end_dtm, '||
            '    CASE '||
            '        WHEN AVG(end_dtm - start_dtm) BETWEEN 29 AND 33 THEN ''m'''||
            '        WHEN AVG(end_dtm - start_dtm) BETWEEN 88 AND 94 THEN ''q'''||
            '        WHEN AVG(end_dtm - start_dtm) BETWEEN 180 AND 190 THEN ''h'''||
            '        WHEN AVG(end_dtm - start_dtm) BETWEEN 360 AND 370 THEN ''y'''||
            '    END interval'||
            '  FROM SS_'||r.name||'_PERIOD'||
            ') WHERE name = :1' USING r.name;
    END LOOP;
END;
/


ALTER TABLE SNAPSHOT MODIFY TITLE   				 VARCHAR2(1024)    NOT NULL;
ALTER TABLE SNAPSHOT MODIFY NEXT_UPDATE_AFTER_DTM   DATE             NOT NULL;
ALTER TABLE SNAPSHOT MODIFY REFRESH_FREQ            NUMBER(10, 0)     DEFAULT 7 NOT NULL;
ALTER TABLE SNAPSHOT MODIFY START_DTM               DATE              NOT NULL;
ALTER TABLE SNAPSHOT MODIFY END_DTM                 DATE              NOT NULL;
ALTER TABLE SNAPSHOT MODIFY INTERVAL               CHAR(1)          DEFAULT 'y' NOT NULL;
 

-- TABLE: SNAPSHOT_REGION 
CREATE TABLE SNAPSHOT_REGION(
    APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    NAME               VARCHAR2(255)    NOT NULL,
    REGION_SID         NUMBER(10, 0)    NOT NULL,
    ALL_DESCENDENTS    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK567 PRIMARY KEY (APP_SID, NAME, REGION_SID)
)
;

ALTER TABLE SNAPSHOT_REGION ADD CONSTRAINT RefREGION1097 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
;

ALTER TABLE SNAPSHOT_REGION ADD CONSTRAINT RefSNAPSHOT1098 
    FOREIGN KEY (APP_SID, NAME)
    REFERENCES SNAPSHOT(APP_SID, NAME)
;

SET DEFINE OFF

@..\pending_pkg
@..\pending_body


SET DEFINE ON

@update_tail
