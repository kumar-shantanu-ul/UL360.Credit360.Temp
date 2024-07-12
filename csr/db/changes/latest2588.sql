-- Please update version.sql too -- this keeps clean builds in sync
define version=2588
@update_header

DECLARE
  FUNCTION MissingTable(
		in_schema IN all_tables.owner%TYPE,
		in_table_name IN all_tables.table_name%TYPE
  ) RETURN BOOLEAN 
  AS
	v_cnt	NUMBER(10);
  BEGIN
    SELECT count(*) 
	  INTO v_cnt
	  FROM all_tables
	 WHERE table_name = UPPER(in_table_name)
	   AND owner = UPPER(in_schema); 
	
	RETURN v_cnt = 0;
  END;
  
  FUNCTION MissingCol(
		in_schema IN all_tab_columns.owner%TYPE,
		in_table_name IN all_tab_columns.table_name%TYPE,
		in_column_name IN all_tab_columns.column_name%TYPE
  ) RETURN BOOLEAN 
  AS
	v_cnt	NUMBER(10);
  BEGIN
	SELECT count(*) 
	  INTO v_cnt
	  FROM all_tab_columns
	 WHERE column_name = UPPER(in_column_name)
	   AND table_name = UPPER(in_table_name)
	   AND owner = UPPER(in_schema);
	   
	RETURN v_cnt = 0;
  END;
  
  FUNCTION MissingFk(
		in_schema IN all_constraints.owner%TYPE,
		in_table_name IN all_constraints.table_name%TYPE,
		in_constraint_name IN all_constraints.constraint_name%TYPE
  ) RETURN BOOLEAN 
  AS
	v_cnt	NUMBER(10);
  BEGIN
    SELECT count(*) 
	  INTO v_cnt
	  FROM all_constraints
	 WHERE constraint_name = UPPER(in_constraint_name)
	   AND table_name = UPPER(in_table_name)
	   AND owner = UPPER(in_schema); 
	   
	RETURN v_cnt = 0;
  END;
  
  FUNCTION MissingPol(
		in_schema IN all_policies.object_owner%TYPE,
		in_table_name IN all_policies.object_name%TYPE,
		in_policy_name IN all_policies.policy_name%TYPE
  ) RETURN BOOLEAN 
  AS
	v_cnt	NUMBER(10);
  BEGIN
    SELECT count(*) 
	  INTO v_cnt
	  FROM all_policies
	 WHERE object_owner = UPPER(in_schema)
	   AND object_name = UPPER(in_table_name)
	   AND policy_name = UPPER(in_policy_name); 
	   
	RETURN v_cnt = 0;
  END;
BEGIN
	
	IF NOT MissingTable('CSR','SECTION_VAL') THEN
		EXECUTE IMMEDIATE 'DROP TABLE CSR.SECTION_VAL CASCADE CONSTRAINTS';
	END IF;


	IF NOT MissingTable('CSR','SECTION_IND') THEN
		EXECUTE IMMEDIATE 'DROP TABLE CSR.SECTION_IND CASCADE CONSTRAINTS';
	END IF;
	
	--NEW TABLES
	
	IF MissingTable('CSR','SECTION_FACT') THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.SECTION_FACT (
			APP_SID								NUMBER(10)		DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
			SECTION_SID							NUMBER(10)	  	NOT NULL,
			FACT_ID								VARCHAR2(255)	NOT NULL,
			MAP_TO_IND_SID						NUMBER(10)		NULL,
			MAP_TO_REGION_SID					NUMBER(10)		NULL,
			STD_MEASURE_CONVERSION_ID	  		NUMBER(10)		NULL,
			DATA_TYPE							VARCHAR2(30)	NULL,
			MAX_LENGTH				  			NUMBER(4)		NULL,
			IS_ACTIVE							NUMBER(1)		DEFAULT (1) NOT NULL,
			CONSTRAINT PK_SECTION_FACT PRIMARY KEY (APP_SID, SECTION_SID, FACT_ID)
		)';
	END IF;	
	
	IF MissingTable('CSR','SECTION_VAL') THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.SECTION_VAL(
			APP_SID								NUMBER(10)		DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
			SECTION_VAL_ID						NUMBER(20)		NOT NULL,
			SECTION_SID							NUMBER(10)		NOT NULL,
			FACT_ID								VARCHAR2(255)	NOT NULL,
			IDX									NUMBER(10)		NOT NULL,
			START_DTM							DATE			NULL,
			END_DTM								DATE			NULL,
			VAL_NUMBER							NUMBER(24,10)	NULL,
			NOTE								CLOB			NULL,
			CONSTRAINT PK_SECTION_VAL PRIMARY KEY (APP_SID, SECTION_VAL_ID),
			CONSTRAINT UK_SECTION_VAL UNIQUE (APP_SID, SECTION_SID, FACT_ID, IDX)
		)';
	END IF;
	
	IF MissingTable('CSR','SECTION_FACT_ATTACH') THEN
		EXECUTE IMMEDIATE 'CREATE TABLE CSR.SECTION_FACT_ATTACH(
				APP_SID					NUMBER(10)		DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
				SECTION_SID				NUMBER(10)		NOT NULL,
				FACT_ID					VARCHAR2(255)	NOT NULL,
				FACT_IDX				NUMBER(10)		NOT NULL,
				ATTACHMENT_ID			NUMBER(10)		NOT NULL,
				CONSTRAINT PK_SECTION_FACT_ATTACH PRIMARY KEY (APP_SID, SECTION_SID, FACT_ID, ATTACHMENT_ID, FACT_IDX)
			)';
	END IF;
	
	--NEW COLUMNS
	
	IF MissingCol('CSR','ATTACHMENT_HISTORY','ATTACH_NAME') THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.ATTACHMENT_HISTORY ADD (
				ATTACH_NAME VARCHAR(255),
				PG_NUM NUMBER(10),
				ATTACH_COMMENT CLOB
			)';
	END IF;
	
	--NEW FKS
	
	IF MissingFk('CSR','SECTION_FACT_ATTACH','FK_SEC_FACT_ATT_SEC_FACT') THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.SECTION_FACT_ATTACH
				ADD CONSTRAINT FK_SEC_FACT_ATT_SEC_FACT FOREIGN KEY (APP_SID, SECTION_SID, FACT_ID)
					REFERENCES CSR.SECTION_FACT(APP_SID, SECTION_SID, FACT_ID)';
	END IF;
	
	IF MissingFk('CSR','SECTION_FACT_ATTACH','FK_SEC_FACT_ATT_ATT') THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.SECTION_FACT_ATTACH
			ADD CONSTRAINT FK_SEC_FACT_ATT_ATT FOREIGN KEY (APP_SID, ATTACHMENT_ID)
				REFERENCES CSR.ATTACHMENT(APP_SID, ATTACHMENT_ID)';
	END IF;
	
	IF MissingFk('CSR','SECTION_FACT','FK_SEC_FACT_IND') THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.SECTION_FACT
			ADD CONSTRAINT FK_SEC_FACT_IND FOREIGN KEY (APP_SID, MAP_TO_IND_SID)
				REFERENCES CSR.IND(APP_SID, IND_SID)';
	END IF; 	
	
	IF MissingFk('CSR','SECTION_FACT','FK_SEC_FACT_REGION') THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.SECTION_FACT
			ADD CONSTRAINT FK_SEC_FACT_REGION FOREIGN KEY (APP_SID, MAP_TO_REGION_SID)
				REFERENCES CSR.REGION(APP_SID, REGION_SID)';
	END IF;
	
	IF MissingFk('CSR','SECTION_FACT','FK_SEC_FACT_STD_MC') THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.SECTION_FACT
			ADD CONSTRAINT FK_SEC_FACT_STD_MC FOREIGN KEY (STD_MEASURE_CONVERSION_ID)
				REFERENCES CSR.STD_MEASURE_CONVERSION(STD_MEASURE_CONVERSION_ID)';
	END IF;
	
	IF MissingFk('CSR','SECTION_FACT','FK_SECTION_FACT_SECTION') THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.SECTION_FACT
			ADD CONSTRAINT FK_SECTION_FACT_SECTION FOREIGN KEY (APP_SID, SECTION_SID)
				REFERENCES CSR.SECTION(APP_SID, SECTION_SID)';
	END IF;
	
	IF MissingFk('CSR','SECTION_VAL','FK_SECTION_VAL_SECTION_FACT') THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.SECTION_VAL
			ADD CONSTRAINT FK_SECTION_VAL_SECTION_FACT FOREIGN KEY (APP_SID, SECTION_SID, FACT_ID)
				REFERENCES CSR.SECTION_FACT(APP_SID, SECTION_SID, FACT_ID)';
	END IF; 
	
	 
/* RLS */  
	
	IF MissingPol('CSR','SECTION_FACT','SECTION_FACT_POLICY') THEN
		BEGIN
			dbms_rls.add_policy(
				object_schema   => 'CSR',
				object_name     => 'SECTION_FACT',
				policy_name     => 'SECTION_FACT_POLICY',
				function_schema => 'CSR',
				policy_function => 'appSidCheck',
				statement_types => 'select, insert, update, delete',
				update_check	=> true,
				policy_type     => dbms_rls.context_sensitive );
		EXCEPTION
			WHEN POLICY_ALREADY_EXISTS THEN
				DBMS_OUTPUT.PUT_LINE('Policy exists');
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
		END;
	END IF;
	
	IF MissingPol('CSR','SECTION_VAL','SECTION_VAL_POLICY') THEN
		BEGIN
			dbms_rls.add_policy(
				object_schema   => 'CSR',
				object_name     => 'SECTION_VAL',
				policy_name     => 'SECTION_VAL_POLICY',
				function_schema => 'CSR',
				policy_function => 'appSidCheck',
				statement_types => 'select, insert, update, delete',
				update_check	=> true,
				policy_type     => dbms_rls.context_sensitive );
		EXCEPTION
			WHEN POLICY_ALREADY_EXISTS THEN
				DBMS_OUTPUT.PUT_LINE('Policy exists');
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
		END;
	END IF;
	
	IF MissingPol('CSR','SECTION_FACT_ATTACH','SECTION_FACT_ATTACH_POLICY') THEN
		BEGIN
			dbms_rls.add_policy(
				object_schema   => 'CSR',
				object_name     => 'SECTION_FACT_ATTACH',
				policy_name     => 'SECTION_FACT_ATTACH_POLICY',
				function_schema => 'CSR',
				policy_function => 'appSidCheck',
				statement_types => 'select, insert, update, delete',
				update_check	=> true,
				policy_type     => dbms_rls.context_sensitive );
		EXCEPTION
			WHEN POLICY_ALREADY_EXISTS THEN
				DBMS_OUTPUT.PUT_LINE('Policy exists');
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
		END;
	END IF;

 END;
 /

@../section_pkg
	
@../section_body
@../doc_body
 
@update_tail