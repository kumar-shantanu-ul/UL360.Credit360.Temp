-- Please update version.sql too -- this keeps clean builds in sync
define version=273
@update_header

-- 
-- TABLE: DELETED_DELEGATION 
--

CREATE TABLE DELETED_DELEGATION(
    APP_SID                NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DELEGATION_SID         NUMBER(10, 0)     NOT NULL,
    NAME                   VARCHAR2(1024)    NOT NULL,
    DELETED_DTM            DATE              NOT NULL,
    DELETED_BY_USER_SID    NUMBER(10, 0)     NOT NULL,
    CONSTRAINT PK563 PRIMARY KEY (APP_SID, DELEGATION_SID)
)
;

-- 
-- TABLE: DELETED_DELEGATION 
--

ALTER TABLE DELETED_DELEGATION ADD CONSTRAINT RefCSR_USER1090 
    FOREIGN KEY (APP_SID, DELETED_BY_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE DELETED_DELEGATION ADD CONSTRAINT RefCUSTOMER1091 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;


 



INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP, PARAMS_XML  ) VALUES ( 
	7, 'Delegation terminated', 'alert_pkg.GetAlerts_DelegTerminated',
	'<params>'||
		'<param name="TERMINATED_BY_FULL_NAME"/>'||
		'<param name="FULL_NAME"/>'||
		'<param name="FRIENDLY_NAME"/>'||
		'<param name="EMAIL"/>'||
		'<param name="DELEGATOR_FULL_NAME"/>'||
		'<param name="DELEGATOR_EMAIL"/>'||
		'<param name="DELEGATION_NAME"/>'||
	'</params>'
);  

INSERT INTO CUSTOMER_ALERT_TYPE 
	(app_sid, alert_type_id)
	SELECT app_sid, 7 FROM CUSTOMER;

commit;

@..\csr_data_pkg
@..\delegation_pkg
@..\delegation_body
@..\alert_pkg
@..\alert_body

begin
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'DELETED_DELEGATION',
        policy_name     => 'DELETED_DELEGATION_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
end;
/

@update_tail
