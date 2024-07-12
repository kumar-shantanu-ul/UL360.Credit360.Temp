-- Please update version.sql too -- this keeps clean builds in sync
define version=2493
@update_header

-------------------
-- Lukasz - FB49557
-------------------

INSERT INTO CSR.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (1050, 'Button', 'Credit360.Portlets.Button', '/csr/site/portal/portlets/Button.js');

--------------------------
-- Steve - FB56078 UI work
--------------------------

ALTER TABLE CSR.RULESET ADD (
    NAME VARCHAR2(255)
);

-- There are currently only two rulesets in the database
-- Both of them are for Greenprint
update csr.ruleset set name = '2012 ruleset' where ruleset_sid = 15981620;
update csr.ruleset set name = '2013 ruleset' where ruleset_sid = 21545403;
update csr.ruleset set name = '2014 ruleset' where ruleset_sid = 27884372;


CREATE UNIQUE INDEX "CSR"."IX_APP_SID_NAME" ON "CSR"."RULESET" ("APP_SID", "NAME");
  
ALTER TABLE CSR.RULESET MODIFY (
    NAME VARCHAR2(255) NOT NULL
);

-------------------------------
-- Marcin 
-------------------------------
DECLARE
	v_cnt	NUMBER(10);
BEGIN
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'TRAINING_OPTIONS'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE CSR.TRAINING_OPTIONS (
        APP_SID NUMBER(10) DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
        GEO_MAP_SID NUMBER(10),
        CONSTRAINT PK_TRAINING_OPTIONS PRIMARY KEY (APP_SID)
    )';
  ELSE
    EXECUTE IMMEDIATE 'ALTER TABLE CSR.TRAINING_OPTIONS MODIFY APP_SID DEFAULT SYS_CONTEXT(''SECURITY'',''APP'')';
  END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'USERS_RELATIONSHIP'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
		EXECUTE IMMEDIATE 'DROP TABLE CSR.USERS_RELATIONSHIP';	
	END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'USER_RELATIONSHIP'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.USER_RELATIONSHIP (
		APP_SID NUMBER(10) DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
		CHILD_USER_SID NUMBER(10) NOT NULL,
		PARENT_USER_SID NUMBER(10)NOT NULL,
		USER_RELATIONSHIP_TYPE_ID NUMBER(10) NOT NULL,
		CONSTRAINT PK_USER_RELATIONSHIP PRIMARY KEY (APP_SID, CHILD_USER_SID, PARENT_USER_SID, USER_RELATIONSHIP_TYPE_ID)
		)';	
	END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'USER_RELATIONSHIP_TYPE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
     EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_RELATIONSHIP_TYPE MODIFY APP_SID DEFAULT SYS_CONTEXT(''SECURITY'',''APP'')';
  END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'FUNCTION'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
     EXECUTE IMMEDIATE 'ALTER TABLE CSR.FUNCTION MODIFY APP_SID DEFAULT SYS_CONTEXT(''SECURITY'',''APP'')';
  END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'USER_FUNCTION'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
     EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_FUNCTION MODIFY APP_SID DEFAULT SYS_CONTEXT(''SECURITY'',''APP'')';
  END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'TRAINER'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
     EXECUTE IMMEDIATE 'ALTER TABLE CSR.TRAINER MODIFY APP_SID DEFAULT SYS_CONTEXT(''SECURITY'',''APP'')';
  END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'COURSE_TYPE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
     EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE_TYPE MODIFY APP_SID DEFAULT SYS_CONTEXT(''SECURITY'',''APP'')';
  END IF;

  SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'PLACE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE CSR.PLACE (
      APP_SID NUMBER(10) DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
      PLACE_ID NUMBER(10) NOT NULL,
      STREET_ADDR1 VARCHAR2(200) NOT NULL,
      STREET_ADDR2 VARCHAR2(200),
      TOWN VARCHAR2(200) NOT NULL,
      STATE VARCHAR2(200),
      POSTCODE VARCHAR2(200),
      COUNTRY_CODE VARCHAR2(10) NOT NULL,
      LAT NUMBER(10, 8) NOT NULL,
      LNG NUMBER(10, 8) NOT NULL,
      CONSTRAINT PK_LOCATION PRIMARY KEY (APP_SID, PLACE_ID)
    )';
  ELSE
    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE CSR.PLACE MODIFY APP_SID DEFAULT SYS_CONTEXT(''SECURITY'',''APP'')';
      
      SELECT COUNT(*)
        INTO v_cnt  
        FROM all_tab_cols
       WHERE table_name = 'PLACE'
         AND owner = 'CSR'
         AND COLUMN_NAME = 'COUNTRY_ID';
      
      IF v_cnt = 1 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE CSR.PLACE DROP COLUMN COUNTRY_ID';
      END IF;
      
      SELECT COUNT(*)
        INTO v_cnt 
        FROM all_tab_cols
       WHERE table_name = 'PLACE'
         AND owner = 'CSR'
         AND COLUMN_NAME = 'COUNTRY_CODE';
      
      IF v_cnt = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE CSR.PLACE ADD COUNTRY_CODE VARCHAR2(10) NOT NULL';
      END IF;
      
      SELECT COUNT(*)
        INTO v_cnt 
        FROM all_tab_cols
       WHERE table_name = 'PLACE'
         AND owner = 'CSR'
         AND COLUMN_NAME = 'COUNTRY_CODE';
      
      IF v_cnt = 0 THEN
        EXECUTE IMMEDIATE 'TRUNCATE TABLE CSR.PLACE';
        EXECUTE IMMEDIATE 'ALTER TABLE CSR.PLACE ADD COUNTRY_CODE VARCHAR2(10) NOT NULL';
      END IF;
      
      SELECT COUNT(*)
        INTO v_cnt 
        FROM all_tab_cols
       WHERE table_name = 'PLACE'
         AND owner = 'CSR'
         AND COLUMN_NAME = 'LAT';
      
      IF v_cnt = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE CSR.PLACE ADD LAT NUMBER(10, 8) NOT NULL';
      END IF;
      
      SELECT COUNT(*)
        INTO v_cnt 
        FROM all_tab_cols
       WHERE table_name = 'PLACE'
         AND owner = 'CSR'
         AND COLUMN_NAME = 'LNG';
      
      IF v_cnt = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE CSR.PLACE ADD LNG NUMBER(10, 8) NOT NULL';
      END IF;
      
      SELECT COUNT(*)
        INTO v_cnt 
        FROM all_tab_cols
       WHERE table_name = 'PLACE'
         AND owner = 'CSR'
         AND COLUMN_NAME = 'STREET_ADDR_1';
    
      IF v_cnt = 1 THEN
         EXECUTE IMMEDIATE 'ALTER TABLE CSR.PLACE RENAME COLUMN STREET_ADDR_1 TO STREET_ADDR1';
      END IF;
      
      SELECT COUNT(*)
        INTO v_cnt 
        FROM all_tab_cols
       WHERE table_name = 'PLACE'
         AND owner = 'CSR'
         AND COLUMN_NAME = 'STREET_ADDR_2';
    
      IF v_cnt = 1 THEN
         EXECUTE IMMEDIATE 'ALTER TABLE CSR.PLACE RENAME COLUMN STREET_ADDR_2 TO STREET_ADDR2';
      END IF;
    END;
	END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'FUNCTION_COURSE'
	   AND owner = 'CSR';
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.FUNCTION_COURSE (
      APP_SID NUMBER(10) DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
      FUNCTION_ID NUMBER(10) NOT NULL,
      COURSE_ID NUMBER(10) NOT NULL,
      TRAINING_PRIORITY_ID NUMBER(10)NOT NULL,
      CONSTRAINT PK_FUNCTION_COURSE PRIMARY KEY (APP_SID, FUNCTION_ID, COURSE_ID)
    )';
  ELSE
     EXECUTE IMMEDIATE 'ALTER TABLE CSR.FUNCTION_COURSE MODIFY APP_SID DEFAULT SYS_CONTEXT(''SECURITY'',''APP'')';
  END IF;

  SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'TRAINING_PRIORITY'
	   AND owner = 'CSR';
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.TRAINING_PRIORITY (
        TRAINING_PRIORITY_ID NUMBER(10) NOT NULL,
        LABEL VARCHAR2(50) NOT NULL,
        CONSTRAINT PK_TRAINING_PRIORITY PRIMARY KEY (TRAINING_PRIORITY_ID)
    )';
    EXECUTE IMMEDIATE 'INSERT INTO CSR.TRAINING_PRIORITY (TRAINING_PRIORITY_ID, LABEL) VALUES (1, ''Recommended'')';
    EXECUTE IMMEDIATE 'INSERT INTO CSR.TRAINING_PRIORITY (TRAINING_PRIORITY_ID, LABEL) VALUES (2, ''Mandatory'')';
  END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'PROVISION'
	   AND owner = 'CSR';
  
  IF v_cnt = 1 THEN
    SELECT count(*) 
      INTO v_cnt
      FROM CSR.PROVISION;
    
    IF v_cnt = 0 THEN
      EXECUTE IMMEDIATE 'INSERT INTO CSR.PROVISION (PROVISION_ID, LABEL) VALUES (1, ''Internal'')';
      EXECUTE IMMEDIATE 'INSERT INTO CSR.PROVISION (PROVISION_ID, LABEL) VALUES (2, ''External'')';
    END IF;
  END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.COURSE (
      APP_SID NUMBER(10) DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
      COURSE_ID NUMBER(10) NOT NULL,
      TITLE VARCHAR2(50) NOT NULL,
      REFERENCE VARCHAR2(40),
      DESCRIPTION VARCHAR2(4000),
      VERSION NUMBER(5),
      COURSE_TYPE_ID NUMBER(10) NOT NULL,
      COURSE_GROUP VARCHAR2(40),
      DELIVERY_METHOD_ID NUMBER(10) NOT NULL,
      PROVISION_ID NUMBER(10) NOT NULL,
      STATUS_ID NUMBER(10) NOT NULL,
      DEFAULT_TRAINER_ID NUMBER(10),
      DEFAULT_PLACE_ID NUMBER(10),
      DURATION NUMBER(5) NOT NULL,
      EXPIRY_PERIOD NUMBER(5),
      EXPIRY_NOTICE_PERIOD NUMBER(5),
      ESCALATION_NOTICE_PERIOD NUMBER(5),
      REMINDER_NOTICE_PERIOD NUMBER(5),
      PASS_SCORE NUMBER(5),
      SURVEY_SID NUMBER(10),
      QUIZ_SID NUMBER(10),
      CONSTRAINT PK_COURSE PRIMARY KEY (APP_SID, COURSE_ID)
		)';
  ELSE
    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE MODIFY APP_SID DEFAULT SYS_CONTEXT(''SECURITY'',''APP'')';
      
      SELECT COUNT(*)
        INTO v_cnt 
        FROM all_tab_cols
       WHERE table_name = 'COURSE'
         AND owner = 'CSR'
         AND COLUMN_NAME = 'REMIDER_NOTICE_PERIOD';
    
      IF v_cnt = 1 THEN
         EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE RENAME COLUMN REMIDER_NOTICE_PERIOD TO REMINDER_NOTICE_PERIOD';
      END IF;
	  
	  SELECT COUNT(*)
        INTO v_cnt 
        FROM all_tab_cols
       WHERE table_name = 'COURSE'
         AND owner = 'CSR'
         AND COLUMN_NAME = 'VERSION';
    
      IF v_cnt = 1 THEN
         EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE MODIFY VERSION NULL ';
      END IF;
    END;
	END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_USER_REL_REL_TYPE'
	   AND owner = 'CSR';	
  
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_RELATIONSHIP ADD CONSTRAINT FK_USER_REL_REL_TYPE 
		FOREIGN KEY (APP_SID, USER_RELATIONSHIP_TYPE_ID) REFERENCES CSR.USER_RELATIONSHIP_TYPE (APP_SID,USER_RELATIONSHIP_TYPE_ID)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_USER_REL_CHILD_USER'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_RELATIONSHIP ADD CONSTRAINT FK_USER_REL_CHILD_USER 
		FOREIGN KEY (APP_SID, CHILD_USER_SID) REFERENCES CSR.CSR_USER (APP_SID,CSR_USER_SID)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_USER_REL_PARENT_USER'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_RELATIONSHIP ADD CONSTRAINT FK_USER_REL_PARENT_USER 
		FOREIGN KEY (APP_SID, PARENT_USER_SID) REFERENCES CSR.CSR_USER (APP_SID,CSR_USER_SID)';	
	END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'JOB_FUNCTION_USER_FUNCTION'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_FUNCTION DROP CONSTRAINT JOB_FUNCTION_USER_FUNCTION';
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_JOB_FUNCTION_USER_FUNCTION'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_FUNCTION ADD CONSTRAINT FK_JOB_FUNCTION_USER_FUNCTION 
		FOREIGN KEY (APP_SID, FUNCTION_ID) REFERENCES CSR.FUNCTION (APP_SID,FUNCTION_ID)';	
	END IF;
	
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FUNCTION_USER_USER'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_FUNCTION DROP CONSTRAINT FUNCTION_USER_USER';
	END IF;
  
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_FUNCTION_USER_USER'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_FUNCTION ADD CONSTRAINT FK_FUNCTION_USER_USER 
		FOREIGN KEY (APP_SID, CSR_USER_SID) REFERENCES CSR.CSR_USER (APP_SID,CSR_USER_SID)';	
	END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'DELIVERY_METHOD_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE DROP CONSTRAINT DELIVERY_METHOD_COURSE';
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_DELIVERY_METHOD_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE ADD CONSTRAINT FK_DELIVERY_METHOD_COURSE 
		FOREIGN KEY (DELIVERY_METHOD_ID) REFERENCES CSR.DELIVERY_METHOD (DELIVERY_METHOD_ID)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'TRAINING_TYPE_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE DROP CONSTRAINT TRAINING_TYPE_COURSE'; 
	END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_COURSE_TYPE_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE ADD CONSTRAINT FK_COURSE_TYPE_COURSE 
		FOREIGN KEY (APP_SID, COURSE_TYPE_ID) REFERENCES CSR.COURSE_TYPE (APP_SID,COURSE_TYPE_ID)';	
	END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'PROVISION_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE DROP CONSTRAINT PROVISION_COURSE';
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_PROVISION_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE ADD CONSTRAINT FK_PROVISION_COURSE 
		FOREIGN KEY (PROVISION_ID) REFERENCES CSR.PROVISION (PROVISION_ID)';
	END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'STATUS_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE DROP CONSTRAINT STATUS_COURSE';
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_STATUS_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE ADD CONSTRAINT FK_STATUS_COURSE 
		FOREIGN KEY (STATUS_ID) REFERENCES CSR.STATUS (STATUS_ID)';	
	END IF;
	
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'QUICK_SURVEY_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE DROP CONSTRAINT QUICK_SURVEY_COURSE';
	END IF;
  
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_QUICK_SURVEY_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE ADD CONSTRAINT FK_QUICK_SURVEY_COURSE 
		FOREIGN KEY (SURVEY_SID, APP_SID) REFERENCES CSR.QUICK_SURVEY (SURVEY_SID, APP_SID)';
	END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'QUICK_SURVEY_COURSE_QUIZ'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE DROP CONSTRAINT QUICK_SURVEY_COURSE_QUIZ';
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_QUICK_SURVEY_COURSE_QUIZ'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE ADD CONSTRAINT FK_QUICK_SURVEY_COURSE_QUIZ 
		FOREIGN KEY (APP_SID, QUIZ_SID) REFERENCES CSR.QUICK_SURVEY (APP_SID, SURVEY_SID)';	
	END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'TRAINER_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE DROP CONSTRAINT TRAINER_COURSE';
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_TRAINER_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE ADD CONSTRAINT FK_TRAINER_COURSE 
		FOREIGN KEY (APP_SID, DEFAULT_TRAINER_ID) REFERENCES CSR.TRAINER (APP_SID, TRAINER_ID)';	
	END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'PLACE_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE DROP CONSTRAINT PLACE_COURSE';
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_PLACE_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE ADD CONSTRAINT FK_PLACE_COURSE 
		FOREIGN KEY (APP_SID, DEFAULT_PLACE_ID) REFERENCES CSR.PLACE (APP_SID, PLACE_ID)';	
	END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'TRAINING_OPTIONS_CUSTOMER'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.TRAINING_OPTIONS DROP CONSTRAINT TRAINING_OPTIONS_CUSTOMER';
  END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_TRAINING_OPTIONS_CUSTOMER'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.TRAINING_OPTIONS ADD CONSTRAINT FK_TRAINING_OPTIONS_CUSTOMER 
    FOREIGN KEY (APP_SID) REFERENCES CSR.CUSTOMER (APP_SID)';
  END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'PROVISION_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE DROP CONSTRAINT PROVISION_COURSE';
  END IF;

  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_PROVISION_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE ADD CONSTRAINT FK_PROVISION_COURSE 
    FOREIGN KEY (PROVISION_ID) REFERENCES CSR.PROVISION (PROVISION_ID)';
  END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FUNCTION_COURSE_PRIORITY'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.FUNCTION_COURSE DROP CONSTRAINT FUNCTION_COURSE_PRIORITY';
  END IF;
    
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_FUNCTION_COURSE_PRIORITY'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.FUNCTION_COURSE ADD CONSTRAINT FK_FUNCTION_COURSE_PRIORITY 
    FOREIGN KEY (TRAINING_PRIORITY_ID) REFERENCES CSR.TRAINING_PRIORITY (TRAINING_PRIORITY_ID)';
  END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FUNCTION_COURSE_FUNCTION'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.FUNCTION_COURSE DROP CONSTRAINT FUNCTION_COURSE_FUNCTION';
  END IF;

  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_FUNCTION_COURSE_FUNCTION'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.FUNCTION_COURSE ADD CONSTRAINT FK_FUNCTION_COURSE_FUNCTION 
    FOREIGN KEY (APP_SID, FUNCTION_ID) REFERENCES CSR.FUNCTION (APP_SID,FUNCTION_ID)';
  END IF;
  
  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FUNCTION_COURSE_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.FUNCTION_COURSE DROP CONSTRAINT FUNCTION_COURSE_COURSE';
  END IF;

  SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FK_FUNCTION_COURSE_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.FUNCTION_COURSE ADD CONSTRAINT FK_FUNCTION_COURSE_COURSE 
    FOREIGN KEY (APP_SID, COURSE_ID) REFERENCES CSR.COURSE (APP_SID,COURSE_ID)';
  END IF;
END;
/
commit;

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
	v_nullable VARCHAR2(1);
BEGIN	
	v_list := t_tabs(
    'USER_RELATIONSHIP_TYPE',
    'USER_RELATIONSHIP',
    'FUNCTION',
    'USER_FUNCTION',
    'PLACE',
    'TRAINER',
    'COURSE_TYPE',
    'COURSE',
    'TRAINING_OPTIONS',
    'FUNCTION_COURSE'
  );
	
  for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin					
					-- check if policy exists
          for r in (select object_name, policy_name from all_policies where object_owner='CSR' AND object_name = v_list(i)) loop
            dbms_rls.drop_policy(
                  object_schema   => 'CSR',
                  object_name     => r.object_name,
                  policy_name     => r.policy_name
              );
          end loop;
          
          -- verify that the table has an app_sid column (dev helper)
					BEGIN
						SELECT nullable 
						  INTO v_nullable
						  FROM all_tab_columns 
						 WHERE owner = 'CSR' 
						   AND table_name = UPPER(v_list(i))
						   AND column_name = 'APP_SID';
					EXCEPTION
						WHEN no_data_found THEN
							raise_application_error(-20001, 'CSR.'||v_list(i)||' does not have an app_sid column');
					END;
					
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
					dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CSR',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CSR',
				        policy_function => (CASE WHEN v_nullable ='N' THEN 'appSidCheck' ELSE 'nullableAppSidCheck' END),
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				    --dbms_output.put_line('done  '||v_name);
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
					WHEN FEATURE_NOT_ENABLED THEN
						DBMS_OUTPUT.PUT_LINE('RLS policy '||v_name||' not applied as feature not enabled');
						exit;
				end;
			end loop;
		end;
	end loop;
end;
/

@../csr_user_pkg 
@../csr_user_body

@../place_pkg 
@../place_body

@../training_pkg
@../training_body

GRANT EXECUTE ON CSR.PLACE_PKG TO WEB_USER;

@update_tail
