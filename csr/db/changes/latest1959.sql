-- Please update version.sql too -- this keeps clean builds in sync
define version=1959
@update_header

CREATE TABLE CSR.LINKED_METER(
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    REGION_SID          NUMBER(10, 0)    NOT NULL,
    LINKED_METER_SID    NUMBER(10, 0)    NOT NULL,
    POS                 NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    CONSTRAINT PK_LINKED_METER PRIMARY KEY (APP_SID, REGION_SID, LINKED_METER_SID)
);


ALTER TABLE CSR.LINKED_METER ADD CONSTRAINT FK_METER_LINKED_METER_1 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.ALL_METER(APP_SID, REGION_SID) ON DELETE CASCADE;

ALTER TABLE CSR.LINKED_METER ADD CONSTRAINT FK_METER_LINKED_METER_2 
    FOREIGN KEY (APP_SID, LINKED_METER_SID)
    REFERENCES CSR.ALL_METER(APP_SID, REGION_SID) ON DELETE CASCADE;
    
CREATE TABLE CSRIMP.LINKED_METER(
	CSRIMP_SESSION_ID	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    REGION_SID          NUMBER(10, 0)    NOT NULL,
    LINKED_METER_SID    NUMBER(10, 0)    NOT NULL,
    POS                 NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    CONSTRAINT PK_LINKED_METER PRIMARY KEY (CSRIMP_SESSION_ID, REGION_SID, LINKED_METER_SID),
    CONSTRAINT FK_LINKED_METER_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

grant insert on csr.linked_meter to csrimp;

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
	TYPE T_TABS IS TABLE OF VARCHAR2(30);
	v_list T_TABS;
BEGIN	
	v_list := t_tabs(  
		'LINKED_METER'
	);
	FOR I IN 1 .. v_list.count 
	LOOP
		BEGIN			
		    DBMS_RLS.ADD_POLICY(
		        object_schema   => 'CSR',
		        object_name     => v_list(i),
		        policy_name     => SUBSTR(v_list(i), 1, 23)||'_POLICY',
		        function_schema => 'CSR',
		        policy_function => 'appSidCheck',
		        statement_types => 'select, insert, update, delete',
		        update_check	=> true,
		        policy_type     => dbms_rls.context_sensitive );
		    	DBMS_OUTPUT.PUT_LINE('Policy added to '||v_list(i));
		EXCEPTION
			WHEN POLICY_ALREADY_EXISTS THEN
				DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));				
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policies not applied for '||v_list(i)||' as feature not enabled');
		END;
	END LOOP;
END;
/

@..\meter_monitor_pkg

@..\meter_monitor_body
@..\csrimp\imp_body

@update_tail