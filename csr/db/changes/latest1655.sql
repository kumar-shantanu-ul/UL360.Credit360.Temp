-- Please update version.sql too -- this keeps clean builds in sync
define version=1655
@update_header

CREATE SEQUENCE CSR.DATAVIEW_TREND_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE CSR.DATAVIEW_TREND(
    APP_SID                 NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DATAVIEW_TREND_ID       NUMBER(10, 0)    NOT NULL,
    NAME                    VARCHAR2(255)    NOT NULL,
    TITLE                   VARCHAR2(4000)   NOT NULL,
    DATAVIEW_SID            NUMBER(10, 0)    NOT NULL,
    IND_SID                 NUMBER(10, 0)    NOT NULL,
    REGION_SID              NUMBER(10, 0)    NOT NULL,
    MONTHS                  NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_DATAVIEW_TREND PRIMARY KEY (APP_SID, DATAVIEW_TREND_ID)
)
;

ALTER TABLE CSR.DATAVIEW_TREND ADD CONSTRAINT FK_DATAVIEW_TREND_DATAVIEW
    FOREIGN KEY (APP_SID, DATAVIEW_SID)
    REFERENCES CSR.DATAVIEW(APP_SID, DATAVIEW_SID)
;

ALTER TABLE CSR.DATAVIEW_TREND ADD CONSTRAINT FK_DATAVIEW_TREND_IND
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.DATAVIEW_TREND ADD CONSTRAINT FK_DATAVIEW_TREND_REGION
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.REGION(APP_SID, REGION_SID)
;

-- RLS
DECLARE
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	BEGIN
		dbms_rls.add_policy(
		    object_schema   => 'CSR',
		    object_name     => 'DATAVIEW_TREND',
		    policy_name     => 'DATAVIEW_TREND_POLICY',
		    function_schema => 'CSR',
		    policy_function => 'appSidCheck',
		    statement_types => 'select, insert, update, delete',
		    update_check	=> true,
		    policy_type     => dbms_rls.context_sensitive
		);
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			NULL;
	END;
END;
/

@../dataview_pkg
@../dataview_body

@update_tail
