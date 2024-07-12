-- Please update version.sql too -- this keeps clean builds in sync
define version=15
@update_header

PROMPT Enter connection (e.g. ASPEN)
connect csr/csr@&&1

grant select, references on measure to actions;
grant execute on calc_pkg to actions;
grant select, references, insert, delete on calc_dependency to actions;
grant select, references, update, delete on val to actions;
grant select, references, delete on val_change to actions;

connect actions/actions@&&1

-- Add the region column
ALTER TABLE TASK_PERIOD ADD (
	REGION_SID NUMBER(10,0) NULL,
	NEEDS_AGGREGATION NUMBER(1,0)  DEFAULT(0) NOT NULL
);

-- Insert the correct root region sid into the task period table
DECLARE
	v_act			security_pkg.T_ACT_ID;
	v_region_root	security_pkg.T_SID_ID;
BEGIN
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	FOR r IN (
		SELECT tp.start_dtm, t.task_sid, t.project_sid, c.app_sid
		  FROM task_period tp, task t, project p, csr.customer c
		 WHERE p.project_sid = t.project_sid
		   AND t.task_sid = tp.task_sid
		   AND c.app_sid = p.app_sid
	) LOOP
		v_region_root := securableobject_pkg.GetSidFromPath(v_act, r.app_sid, 'Regions');
		UPDATE task_period 
		   SET region_sid = v_region_root
		 WHERE task_sid = r.task_sid
		   AND start_dtm = r.start_dtm;
	END LOOP;
END;
/

COMMIT;

-- Add the region sid column to the primary key for the table
ALTER TABLE TASK_PERIOD MODIFY (REGION_SID NUMBER(10,0) NOT NULL);
ALTER TABLE TASK_PERIOD DROP CONSTRAINT PK7;
ALTER TABLE TASK_PERIOD DROP CONSTRAINT REFPROJECT_TASK_PERIOD_STATU26;
ALTER TABLE TASK_PERIOD ADD CONSTRAINT REFPROJECT_TASK_PERIOD_STATU26 PRIMARY KEY (TASK_SID, START_DTM, REGION_SID);


-- Add input/output indicatros and weighting to task table
ALTER TABLE TASK ADD(
	INPUT_IND_SID	NUMBER(10, 0)	NULL,
    TARGET_IND_SID	NUMBER(10, 0)	NULL,
    OUTPUT_IND_SID	NUMBER(10, 0)	NULL,
    WEIGHTING		NUMBER(3, 2)	NULL,
    ACTION_TYPE		VARCHAR2(1)		NULL,
    ENTRY_TYPE		VARCHAR2(1)		NULL
);

UPDATE task 
   SET action_type = 'A',
       entry_type = 'R';
   
UPDATE task 
   SET action_type = 'M'
 WHERE task_sid IN (
 	SELECT task_sid
 	  FROM task
 	 WHERE CONNECT_BY_ISLEAF = 1
 		START WITH parent_task_sid IS NULL
 		CONNECT BY PRIOR task_sid = parent_task_sid
);

ALTER TABLE TASK MODIFY ACTION_TYPE VARCHAR2(1) NOT NULL;
ALTER TABLE TASK MODIFY ENTRY_TYPE VARCHAR2(1) NOT NULL;

ALTER TABLE TASK_PERIOD_STATUS ADD (
	MEANS_PCT_COMPLETE	NUMBER(3, 2)	NULL
);


CREATE GLOBAL TEMPORARY TABLE AGGREGATE_TASKS
(
	LVL					NUMBER(10, 0)	NOT NULL,
	TASK_SID			NUMBER(10, 0)	NOT NULL,
	TASK_START_DTM		DATE			NOT NULL,	
	TASK_END_DTM		DATE			NOT NULL,
	TASK_INTERVAL		NUMBER(10, 0)	NOT NULL,
	REGION_SID			NUMBER(10, 0)	NOT NULL,
	IND_SID				NUMBER(10, 0)	NOT NULL,
	PERIOD_START_DTM	DATE			NOT NULL,
	PERIOD_END_DTM		DATE			NOT NULL
)
ON COMMIT DELETE ROWS
;


ALTER TABLE customer_options ADD (
	BROWSE_SHOWS_CHILDREN	NUMBER(1)	DEFAULT 0	NOT NULL
);

ALTER TABLE TASK ADD(
	VALUE_SCRIPT            CLOB,
    AGGREGATE_SCRIPT        CLOB
);

CREATE TABLE TASK_IND_DEPENDENCY(
    TASK_SID    NUMBER(10, 0)    NOT NULL,
    IND_SID     NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK43 PRIMARY KEY (TASK_SID, IND_SID)
);

ALTER TABLE TASK_IND_DEPENDENCY ADD CONSTRAINT RefTASK55 
    FOREIGN KEY (TASK_SID)
    REFERENCES TASK(TASK_SID)
;


CREATE TABLE TASK_TASK_DEPENDENCY(
    TASK_SID               NUMBER(10, 0)    NOT NULL,
    DEPENDS_ON_TASK_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK47 PRIMARY KEY (TASK_SID, DEPENDS_ON_TASK_SID)
);

ALTER TABLE TASK_TASK_DEPENDENCY ADD CONSTRAINT RefTASK59 
    FOREIGN KEY (DEPENDS_ON_TASK_SID)
    REFERENCES TASK(TASK_SID)
;

ALTER TABLE TASK_TASK_DEPENDENCY ADD CONSTRAINT RefTASK60 
    FOREIGN KEY (TASK_SID)
    REFERENCES TASK(TASK_SID)
;


CREATE TABLE TASK_RECALC_JOB(
    TASK_SID      NUMBER(10, 0)    NOT NULL,
    APP_SID		  NUMBER(10, 0)	   NOT NULL,
    PROCESSING    NUMBER(1, 0)     NOT NULL,
    CONSTRAINT PK44 PRIMARY KEY (TASK_SID)
);

ALTER TABLE TASK_RECALC_JOB ADD CONSTRAINT RefTASK56 
    FOREIGN KEY (TASK_SID)
    REFERENCES TASK(TASK_SID)
;


@..\dependency_pkg
@..\dependency_body

@..\task_pkg
@..\task_body

grant execute on dependency_pkg to csr;

@update_tail