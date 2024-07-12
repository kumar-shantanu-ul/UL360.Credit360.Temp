-- Please update version.sql too -- this keeps clean builds in sync
define version=1656
@update_header

CREATE TABLE CSRIMP.DATAVIEW_TREND(
	CSRIMP_SESSION_ID		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    DATAVIEW_TREND_ID       NUMBER(10, 0)    NOT NULL,
    NAME                    VARCHAR2(255)    NOT NULL,
    TITLE                   VARCHAR2(4000)   NOT NULL,
    DATAVIEW_SID            NUMBER(10, 0)    NOT NULL,
    IND_SID                 NUMBER(10, 0)    NOT NULL,
    REGION_SID              NUMBER(10, 0)    NOT NULL,
    MONTHS                  NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_DATAVIEW_TREND PRIMARY KEY (CSRIMP_SESSION_ID, DATAVIEW_TREND_ID),
    CONSTRAINT FK_DATAVIEW_TREND_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
)
;

-- CSRIMP RLS
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSRIMP',
		object_name     => 'DATAVIEW_TREND',
		policy_name     => 'DATAVIEW_TREND_POL',
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);
END;
/

@../schema_pkg
@../schema_body

@update_tail
