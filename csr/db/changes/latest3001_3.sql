-- Please update version.sql too -- this keeps clean builds in sync
define version=3001
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- ADD RUN_FOR_CURRENT_MONTH to CSR.AGGREGATE_IND_GROUP and CSRIMP.AGGREGATE_IND_GROUP
DECLARE
	v_check	NUMBER(1);
BEGIN
	SELECT COUNT(column_name) INTO v_check
	  FROM all_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'AGGREGATE_IND_GROUP'
	   AND column_name = 'RUN_FOR_CURRENT_MONTH';

	IF v_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.AGGREGATE_IND_GROUP ADD RUN_FOR_CURRENT_MONTH NUMBER(1) DEFAULT 0 NOT NULL';
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.AGGREGATE_IND_GROUP ADD CONSTRAINT CK_AGG_IND_GROUP_MONTHLY CHECK (RUN_FOR_CURRENT_MONTH IN (0, 1))';
	END IF;
END;
/

DECLARE
	v_check	NUMBER(1);
BEGIN
	SELECT COUNT(column_name) INTO v_check
	  FROM all_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'AGGREGATE_IND_GROUP'
	   AND column_name = 'RUN_FOR_CURRENT_MONTH';

	IF v_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.AGGREGATE_IND_GROUP ADD RUN_FOR_CURRENT_MONTH NUMBER(1) NOT NULL';
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.AGGREGATE_IND_GROUP ADD CONSTRAINT CK_AGG_IND_GROUP_MONTHLY CHECK (RUN_FOR_CURRENT_MONTH IN (0, 1))';
	END IF;
END;
/

-- ADD TIME_SPENT_IND_SID TO CSR.FLOW_STATE AND CSRIMP.FLOW_STATE
BEGIN
	FOR r IN (
		SELECT COUNT(tc.column_name) c_check, t.owner, t.table_name
		  FROM all_tables t
	 LEFT JOIN all_tab_columns tc 
				 ON t.owner = tc.owner
				AND t.table_name = tc.table_name
				AND tc.column_name = 'TIME_SPENT_IND_SID'
		 WHERE t.owner IN ('CSR', 'CSRIMP')
		   AND t.table_name = 'FLOW_STATE'
	  GROUP BY t.owner, t.table_name
	)
	LOOP
		IF r.c_check = 0 THEN
			EXECUTE IMMEDIATE 'ALTER TABLE ' || r.owner || '.flow_state ADD time_spent_ind_sid NUMBER(10)';
		END IF;
	END LOOP;
END;
/

DECLARE
	v_check	NUMBER(1);
BEGIN
	SELECT COUNT(constraint_name) INTO v_check
	  FROM all_constraints
	 WHERE owner = 'CSR'
	   AND table_name = 'FLOW_STATE'
	   AND constraint_name = 'FK_FLOW_STATE_TIME_IND_SID';

	IF v_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.FLOW_STATE ADD CONSTRAINT FK_FLOW_STATE_TIME_IND_SID FOREIGN KEY (APP_SID, TIME_SPENT_IND_SID) REFERENCES CSR.IND(APP_SID, IND_SID)';
		EXECUTE IMMEDIATE 'CREATE INDEX csr.ix_flow_state_time_ind_sid ON csr.flow_state (app_sid, time_spent_ind_sid)';
	END IF;
END;
/



-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_check	NUMBER(1);
BEGIN
	SELECT COUNT(util_script_id) INTO v_check
	  FROM csr.util_script
	 WHERE util_script_id = 27
	   AND util_script_name = 'Capture time in workflow states';
	
	IF v_check = 0 THEN
		INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) 
		VALUES (27, 'Capture time in workflow states', 'Creates indicators for each state in given workflow and record the time items spend in each state.', 'RecordTimeInFlowStates', NULL);

		INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN) 
		VALUES (27, 'Workflow SID', 'System ID of a workflow. Supports Chain and Campaign workflow types only.', 0, NULL, 0);
	END IF;
	   
END;
/

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.flow_report_pkg as
	PROCEDURE dummy;
END;
/

CREATE OR REPLACE PACKAGE BODY csr.flow_report_pkg as
	PROCEDURE dummy
	AS
	BEGIN
		null;
	END;
END;
/

GRANT EXECUTE ON csr.flow_report_pkg to web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../flow_report_pkg
@../util_script_pkg

@../flow_report_body
@../util_script_body
@../aggregate_ind_body
@../indicator_body
@../schema_body
@../csrimp/imp_body

@update_tail
