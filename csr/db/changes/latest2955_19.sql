-- Please update version.sql too -- this keeps clean builds in sync
define version=2955
define minor_version=19
@update_header

-- *** DDL ***
-- Create tables
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM dba_tables
		 WHERE owner = 'CSRIMP'
		   AND table_name IN ('FLOW_STATE_GROUP_MEMBER', 'FLOW_STATE_GROUP', 'MAP_FLOW_STATE_GROUP')
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP TABLE CSRIMP.' || r.table_name || ' CASCADE CONSTRAINTS';
	END LOOP;
END;
/

CREATE TABLE CSRIMP.FLOW_STATE_GROUP(
	CSRIMP_SESSION_ID		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	FLOW_STATE_GROUP_ID		NUMBER(10, 0)	NOT NULL,
	LOOKUP_KEY				VARCHAR2(256)	NOT NULL,
	LABEL					VARCHAR2(1024)	NOT NULL,
	COUNT_IND_SID			NUMBER(10, 0),
	CONSTRAINT PK_FLOW_STATE_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_STATE_GROUP_ID),
	CONSTRAINT FK_FLOW_STATE_GROUP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.FLOW_STATE_GROUP_MEMBER(
	CSRIMP_SESSION_ID		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	FLOW_STATE_GROUP_ID		NUMBER(10, 0)	NOT NULL,
	FLOW_STATE_ID			NUMBER(10, 0)	NOT NULL,
	BEFORE_REPORT_DATE		NUMBER(1, 0)	NOT NULL,
	AFTER_REPORT_DATE		NUMBER(1, 0)	NOT NULL,
	CONSTRAINT CK_BEFORE_REPORT_DATE CHECK (BEFORE_REPORT_DATE IN(0,1)),
	CONSTRAINT CK_AFTER_REPORT_DATE CHECK (AFTER_REPORT_DATE IN(0,1)),
	CONSTRAINT PK_FLOW_STATE_GROUP_MEMBER PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_STATE_GROUP_ID, FLOW_STATE_ID),
	CONSTRAINT FK_FLOW_STATE_GROUP_MEM_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_FLOW_STATE_GROUP (
	CSRIMP_SESSION_ID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FLOW_STATE_GROUP_ID	NUMBER(10)	NOT NULL,
	NEW_FLOW_STATE_GROUP_ID	NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_FLOW_STATE_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FLOW_STATE_GROUP_ID) USING INDEX,
	CONSTRAINT UK_MAP_FLOW_STATE_GROUP UNIQUE (CSRIMP_SESSION_ID, NEW_FLOW_STATE_GROUP_ID) USING INDEX,
    CONSTRAINT FK_MAP_FLOW_STATE_GROUP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- Alter tables
DECLARE
	v_col_check NUMBER(1);
BEGIN	
	SELECT COUNT(*) INTO v_col_check
	  FROM dba_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'T_FLOW_STATE'
	   AND column_name = 'FLOW_STATE_GROUP_IDS';
	
	IF v_col_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.T_FLOW_STATE ADD FLOW_STATE_GROUP_IDS VARCHAR2(2000)';
	END IF;
END;
/


-- *** Grants ***
grant insert on csr.flow_state_group to csrimp;
grant insert on csr.flow_state_group_member to csrimp;

grant select,insert,update,delete on csrimp.flow_state_group to web_user;
grant select,insert,update,delete on csrimp.flow_state_group_member to web_user;

grant select on csr.flow_state_group_id_seq to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../flow_pkg
@../schema_pkg
@../csrimp/imp_pkg

@../csr_app_body
@../enable_body
@../flow_body
@../schema_body
@../csrimp/imp_body

@update_tail
