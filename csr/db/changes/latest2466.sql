-- Please update version.sql too -- this keeps clean builds in sync
define version=2466
@update_header

DECLARE
	v_cnt	NUMBER(10);
BEGIN
	SELECT count(*) 
		  INTO v_cnt
		  FROM all_sequences
		 WHERE sequence_name = 'USER_RELATIONSHIP_TYPE_ID_SEQ'
			AND sequence_owner = 'CSR';
			
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE SEQUENCE CSR.USER_RELATIONSHIP_TYPE_ID_SEQ
	  START WITH 1
		INCREMENT BY 1
		NOMINVALUE
		NOMAXVALUE
		CACHE 20
		NOORDER';	
	END IF;
	 
	SELECT count(*) 
		  INTO v_cnt
		  FROM all_sequences
		 WHERE sequence_name = 'FUNCTION_ID_SEQ'
			AND sequence_owner = 'CSR';
			
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE SEQUENCE CSR.FUNCTION_ID_SEQ
	  START WITH 1
		INCREMENT BY 1
		NOMINVALUE
		NOMAXVALUE
		CACHE 20
		NOORDER';	
	END IF;
	
	SELECT count(*) 
		  INTO v_cnt
		  FROM all_sequences
		 WHERE sequence_name = 'PLACE_ID_SEQ'
			AND sequence_owner = 'CSR';
			
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE SEQUENCE CSR.PLACE_ID_SEQ
	  START WITH 1
		INCREMENT BY 1
		NOMINVALUE
		NOMAXVALUE
		CACHE 20
		NOORDER';	
	END IF;
	
	SELECT count(*) 
		  INTO v_cnt
		  FROM all_sequences
		 WHERE sequence_name = 'TRAINER_ID_SEQ'
			AND sequence_owner = 'CSR';
			
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE SEQUENCE CSR.TRAINER_ID_SEQ
	  START WITH 1
		INCREMENT BY 1
		NOMINVALUE
		NOMAXVALUE
		CACHE 20
		NOORDER';	
	END IF;
	
	SELECT count(*) 
		  INTO v_cnt
		  FROM all_sequences
		 WHERE sequence_name = 'COURSE_ID_SEQ'
			AND sequence_owner = 'CSR';
			
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE SEQUENCE CSR.COURSE_ID_SEQ
	  START WITH 1
		INCREMENT BY 1
		NOMINVALUE
		NOMAXVALUE
		CACHE 20
		NOORDER';	
	END IF;
	
	SELECT count(*) 
		  INTO v_cnt
		  FROM all_sequences
		 WHERE sequence_name = 'COURSE_TYPE_ID_SEQ'
			AND sequence_owner = 'CSR';
			
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE SEQUENCE CSR.COURSE_TYPE_ID_SEQ
	  START WITH 1
		INCREMENT BY 1
		NOMINVALUE
		NOMAXVALUE
		CACHE 20
		NOORDER';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'USER_RELATIONSHIP_TYPE'
	   AND owner = 'CSR';
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.USER_RELATIONSHIP_TYPE (
		APP_SID NUMBER(10) NOT NULL,
		USER_RELATIONSHIP_TYPE_ID NUMBER(10) NOT NULL,
		LABEL VARCHAR2(50) NOT NULL,
		CONSTRAINT PK_USER_RELATIONSHIP_TYPE PRIMARY KEY (APP_SID, USER_RELATIONSHIP_TYPE_ID)
		)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'USERS_RELATIONSHIP'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.USERS_RELATIONSHIP (
		APP_SID NUMBER(10) NOT NULL,
		CHILD_USER_SID NUMBER(10) NOT NULL,
		PARENT_USER_SID NUMBER(10)NOT NULL,
		USER_RELATIONSHIP_TYPE_ID NUMBER(10) NOT NULL,
		CONSTRAINT PK_USERS_RELATIONSHIP PRIMARY KEY (APP_SID, CHILD_USER_SID, PARENT_USER_SID, USER_RELATIONSHIP_TYPE_ID)
		)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'FUNCTION'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.FUNCTION (
		APP_SID NUMBER(10) NOT NULL,
		FUNCTION_ID NUMBER(10) NOT NULL,
		LABEL VARCHAR2(50) NOT NULL,
		CONSTRAINT PK_FUNCTION PRIMARY KEY (APP_SID, FUNCTION_ID)
		)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'USER_FUNCTION'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.USER_FUNCTION (
		APP_SID NUMBER(10) NOT NULL,
		CSR_USER_SID NUMBER(10) NOT NULL,
		FUNCTION_ID NUMBER(10) NOT NULL,
		CONSTRAINT PK_USER_FUNCTION PRIMARY KEY (APP_SID, CSR_USER_SID, FUNCTION_ID)
		)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'PLACE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.PLACE (
		APP_SID NUMBER(10) NOT NULL,
		PLACE_ID NUMBER(10) NOT NULL,
		STREET_ADDR_1 VARCHAR2(200) NOT NULL,
		STREET_ADDR_2 VARCHAR2(200),
		TOWN VARCHAR2(200) NOT NULL,
		STATE VARCHAR2(200),
		POSTCODE VARCHAR2(200),
		COUNTRY_ID NUMBER(10) NOT NULL,
		CONSTRAINT PK_LOCATION PRIMARY KEY (APP_SID, PLACE_ID)
		)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'TRAINER'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.TRAINER (
		APP_SID NUMBER(10) NOT NULL,
		TRAINER_ID NUMBER(10) NOT NULL,
		NAME VARCHAR2(256) NOT NULL,
		CONSTRAINT PK_TRAINER PRIMARY KEY (APP_SID, TRAINER_ID),
		CONSTRAINT UNQ_TRAINER UNIQUE (APP_SID, NAME)
		)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'COURSE_TYPE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.COURSE_TYPE (
		APP_SID NUMBER(10) NOT NULL,
		COURSE_TYPE_ID NUMBER(10) NOT NULL,
		LABEL VARCHAR2(50) NOT NULL,
		CONSTRAINT PK_COURSE_TYPE PRIMARY KEY (APP_SID, COURSE_TYPE_ID),
		CONSTRAINT UNQ_COURSE_TYPE UNIQUE (APP_SID, LABEL)
		)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'DELIVERY_METHOD'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.DELIVERY_METHOD (
		DELIVERY_METHOD_ID NUMBER(10) NOT NULL,
		LABEL VARCHAR2(40) NOT NULL,
		CONSTRAINT PK_DELIVERY_METHOD PRIMARY KEY (DELIVERY_METHOD_ID)
		)';	
		EXECUTE IMMEDIATE 'INSERT INTO CSR.DELIVERY_METHOD (DELIVERY_METHOD_ID, LABEL) VALUES (1, ''online'')';
		EXECUTE IMMEDIATE 'INSERT INTO CSR.DELIVERY_METHOD (DELIVERY_METHOD_ID, LABEL) VALUES (2, ''on location'')';
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'PROVISION'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.PROVISION (
		PROVISION_ID NUMBER(10) NOT NULL,
		LABEL VARCHAR2(40) NOT NULL,
		CONSTRAINT PK_PROVISION PRIMARY KEY (PROVISION_ID)
		)';	
		EXECUTE IMMEDIATE 'INSERT INTO CSR.PROVISION (PROVISION_ID, LABEL) VALUES (1, ''internal'')';
		EXECUTE IMMEDIATE 'INSERT INTO CSR.PROVISION (PROVISION_ID, LABEL) VALUES (2, ''external'')';
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'STATUS'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.STATUS (
		STATUS_ID NUMBER(10) NOT NULL,
		LABEL VARCHAR2(50) NOT NULL,
		CONSTRAINT PK_STATUS PRIMARY KEY (STATUS_ID)
		)';	
		EXECUTE IMMEDIATE 'INSERT INTO CSR.STATUS (STATUS_ID, LABEL) VALUES (1, ''active'')';
		EXECUTE IMMEDIATE 'INSERT INTO CSR.STATUS (STATUS_ID, LABEL) VALUES (2, ''inactive'')';
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = 'COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.COURSE (
		APP_SID NUMBER(10) NOT NULL,
		COURSE_ID NUMBER(10) NOT NULL,
		TITLE VARCHAR2(50) NOT NULL,
		REFERENCE VARCHAR2(40),
		DESCRIPTION VARCHAR2(4000),
		VERSION NUMBER(5) NOT NULL,
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
		REMIDER_NOTICE_PERIOD NUMBER(5),
		PASS_SCORE NUMBER(5),
		SURVEY_SID NUMBER(10),
		QUIZ_SID NUMBER(10),
		CONSTRAINT PK_COURSE PRIMARY KEY (APP_SID, COURSE_ID)
		)';	
	END IF;


	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'USERS_REL_REL_TYPE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.USERS_RELATIONSHIP ADD CONSTRAINT USERS_REL_REL_TYPE 
		FOREIGN KEY (APP_SID, USER_RELATIONSHIP_TYPE_ID) REFERENCES CSR.USER_RELATIONSHIP_TYPE (APP_SID,USER_RELATIONSHIP_TYPE_ID)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'USER_REL_CHILD_USER'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.USERS_RELATIONSHIP ADD CONSTRAINT USER_REL_CHILD_USER 
		FOREIGN KEY (APP_SID, CHILD_USER_SID) REFERENCES CSR.CSR_USER (APP_SID,CSR_USER_SID)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'USER_REL_PARENT_USER'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.USERS_RELATIONSHIP ADD CONSTRAINT USER_REL_PARENT_USER 
		FOREIGN KEY (APP_SID, PARENT_USER_SID) REFERENCES CSR.CSR_USER (APP_SID,CSR_USER_SID)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'JOB_FUNCTION_USER_FUNCTION'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_FUNCTION ADD CONSTRAINT JOB_FUNCTION_USER_FUNCTION 
		FOREIGN KEY (APP_SID, FUNCTION_ID) REFERENCES CSR.FUNCTION (APP_SID,FUNCTION_ID)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'FUNCTION_USER_USER'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_FUNCTION ADD CONSTRAINT FUNCTION_USER_USER 
		FOREIGN KEY (APP_SID, CSR_USER_SID) REFERENCES CSR.CSR_USER (APP_SID,CSR_USER_SID)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'DELIVERY_METHOD_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE ADD CONSTRAINT DELIVERY_METHOD_COURSE 
		FOREIGN KEY (DELIVERY_METHOD_ID) REFERENCES CSR.DELIVERY_METHOD (DELIVERY_METHOD_ID)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'TRAINING_TYPE_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE ADD CONSTRAINT TRAINING_TYPE_COURSE 
		FOREIGN KEY (APP_SID, COURSE_TYPE_ID) REFERENCES CSR.COURSE_TYPE (APP_SID,COURSE_TYPE_ID)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'PROVISION_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE ADD CONSTRAINT PROVISION_COURSE 
		FOREIGN KEY (PROVISION_ID) REFERENCES CSR.PROVISION (PROVISION_ID)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'STATUS_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE ADD CONSTRAINT STATUS_COURSE 
		FOREIGN KEY (STATUS_ID) REFERENCES CSR.STATUS (STATUS_ID)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'QUICK_SURVEY_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE ADD CONSTRAINT QUICK_SURVEY_COURSE 
		FOREIGN KEY (SURVEY_SID, APP_SID) REFERENCES CSR.QUICK_SURVEY (SURVEY_SID,APP_SID)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'QUICK_SURVEY_COURSE_QUIZ'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE ADD CONSTRAINT QUICK_SURVEY_COURSE_QUIZ 
		FOREIGN KEY (APP_SID, QUIZ_SID) REFERENCES CSR.QUICK_SURVEY (APP_SID,SURVEY_SID)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'TRAINER_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE ADD CONSTRAINT TRAINER_COURSE 
		FOREIGN KEY (APP_SID, DEFAULT_TRAINER_ID) REFERENCES CSR.TRAINER (APP_SID,TRAINER_ID)';	
	END IF;
	
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = 'PLACE_COURSE'
	   AND owner = 'CSR';	
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COURSE ADD CONSTRAINT PLACE_COURSE 
		FOREIGN KEY (APP_SID, DEFAULT_PLACE_ID) REFERENCES CSR.PLACE (APP_SID,PLACE_ID)';	
	END IF;
			
	BEGIN
		INSERT INTO csr.capability (name, allow_by_default) VALUES ('Edit user relationships', 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- it's on live already
			NULL;
	END;

	BEGIN
		INSERT INTO csr.capability (name, allow_by_default) VALUES ('Edit user job functions', 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- it's on live already
			NULL;
	END;

END;
/

commit;

@../csr_user_pkg 
@../csr_user_body

@../training_pkg
@../training_body

GRANT EXECUTE ON CSR.TRAINING_PKG TO WEB_USER;

@update_tail