-- Please update version.sql too -- this keeps clean builds in sync
define version=1933
@update_header

CREATE TABLE CSRIMP.DELEGATION_DATE_SCHEDULE ( 
	CSRIMP_SESSION_ID				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DELEGATION_DATE_SCHEDULE_ID 	NUMBER(10,0) 	NOT NULL, 
	START_DTM 						DATE 			NOT NULL, 
	END_DTM 						DATE 			NOT NULL, 
	CONSTRAINT PK_DELEGATION_DATE_SCHEDULE PRIMARY KEY (DELEGATION_DATE_SCHEDULE_ID),
	CONSTRAINT CK_DATES CHECK (START_DTM = TRUNC(START_DTM, 'MON') AND END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM),
	CONSTRAINT FK_DELEGATION_DATE_SCHEDULE_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);
		
CREATE TABLE CSRIMP.SHEET_DATE_SCHEDULE(
    CSRIMP_SESSION_ID					NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    DELEGATION_DATE_SCHEDULE_ID 		NUMBER(10, 0)   NOT NULL,
	START_DTM 							DATE 			NOT NULL,
	CREATION_DTM						DATE 			NOT NULL,
	SUBMISSION_DTM						DATE 			NOT NULL,
	REMINDER_DTM						DATE 			NOT NULL,
    CONSTRAINT PK_SHEET_DATE_SCHEDULE	PRIMARY KEY (DELEGATION_DATE_SCHEDULE_ID, START_DTM),
	CONSTRAINT CK_START_DTM CHECK (START_DTM = TRUNC(START_DTM, 'MON')), 
	CONSTRAINT CK_SUBMISSION_DTM CHECK (SUBMISSION_DTM > START_DTM), 
	CONSTRAINT CK_REMINDER_DTM CHECK (REMINDER_DTM <= SUBMISSION_DTM), 
	CONSTRAINT FK_SHEET_DATE_SCHEDULE_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);
  
CREATE TABLE CSRIMP.DELEG_PLAN_DATE_SCHEDULE(
    CSRIMP_SESSION_ID				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    DELEG_PLAN_SID    				NUMBER(10, 0)	NOT NULL,
    ROLE_SID						NUMBER(10, 0),
	DELEG_PLAN_COL_ID               NUMBER(10, 0),
    SCHEDULE_XML					CLOB,
	REMINDER_OFFSET					NUMBER(10,0), 
	DELEGATION_DATE_SCHEDULE_ID 	NUMBER(10, 0),
	CONSTRAINT UK_DELEG_PLAN_DATE_SCHEDULE  UNIQUE (DELEG_PLAN_SID, ROLE_SID, DELEG_PLAN_COL_ID),
	CONSTRAINT CK_SCHEDULE CHECK ((DELEGATION_DATE_SCHEDULE_ID IS NULL AND REMINDER_OFFSET IS NOT NULL AND SCHEDULE_XML IS NOT NULL) OR (DELEGATION_DATE_SCHEDULE_ID IS NOT NULL AND REMINDER_OFFSET IS NULL AND SCHEDULE_XML IS NULL)), 
	CONSTRAINT FK_DELEG_PLAN_DATE_SCHEDULE_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

ALTER TABLE CSRIMP.DELEGATION ADD DELEGATION_DATE_SCHEDULE_ID NUMBER(10, 0);

CREATE TABLE CSRIMP.MAP_DELEG_DATE_SCHEDULE (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_deleg_date_schedule_id		NUMBER(10)	NOT NULL,
	new_deleg_date_schedule_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_deleg_date_schedule PRIMARY KEY (old_deleg_date_schedule_id) USING INDEX,
	CONSTRAINT uk_map_deleg_date_schedule UNIQUE (new_deleg_date_schedule_id) USING INDEX,
    CONSTRAINT fk_map_deleg_date_schedule_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

grant insert on csr.delegation_date_schedule to csrimp;
grant select on csr.delegation_date_schedule_seq to csrimp;
grant insert on csr.sheet_date_schedule to csrimp;
grant insert on csr.deleg_plan_date_schedule to csrimp;

grant select,insert,update,delete on csrimp.delegation_date_schedule to web_user;
grant select,insert,update,delete on csrimp.sheet_date_schedule to web_user;
grant select,insert,update,delete on csrimp.deleg_plan_date_schedule to web_user;

@..\schema_pkg
@..\schema_body
@..\csrimp\imp_body


@update_tail