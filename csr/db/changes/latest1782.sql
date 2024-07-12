-- Please update version.sql too -- this keeps clean builds in sync
define version=1782
@update_header

ALTER TABLE chain.card_group_card DROP COLUMN INIT_PARAM;

CREATE TABLE CHAIN.CARD_INIT_PARAM(
    CARD_ID          NUMBER(10, 0)    NOT NULL,
    APP_SID          NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    PARAM_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    KEY              VARCHAR2(255)    NOT NULL,
    VALUE            VARCHAR2(255)    NOT NULL,
    CARD_GROUP_ID    NUMBER(10, 0),
    CONSTRAINT CHK_CARD_INIT_PARAM_GROUP CHECK (CASE WHEN card_group_id IS NOT NULL THEN 1 ELSE 0 END = param_type_id),
    CONSTRAINT PK481 PRIMARY KEY (CARD_ID, APP_SID, PARAM_TYPE_ID, KEY)
);

CREATE TABLE CHAIN.CARD_INIT_PARAM_TYPE(
    PARAM_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION      VARCHAR2(255),
    CONSTRAINT PK482 PRIMARY KEY (PARAM_TYPE_ID)
);

ALTER TABLE CHAIN.CARD_INIT_PARAM ADD CONSTRAINT RefCUSTOMER_OPTIONS1159 
    FOREIGN KEY (APP_SID)
    REFERENCES CHAIN.CUSTOMER_OPTIONS(APP_SID);

ALTER TABLE CHAIN.CARD_INIT_PARAM ADD CONSTRAINT RefCARD_GROUP1160 
    FOREIGN KEY (CARD_GROUP_ID)
    REFERENCES CHAIN.CARD_GROUP(CARD_GROUP_ID);

ALTER TABLE CHAIN.CARD_INIT_PARAM ADD CONSTRAINT RefCARD_INIT_PARAM_TYPE1161 
    FOREIGN KEY (PARAM_TYPE_ID)
    REFERENCES CHAIN.CARD_INIT_PARAM_TYPE(PARAM_TYPE_ID);

ALTER TABLE CHAIN.CARD_INIT_PARAM ADD CONSTRAINT RefCARD1162 
    FOREIGN KEY (CARD_ID)
    REFERENCES CHAIN.CARD(CARD_ID);
	
-- RLS
DECLARE
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	BEGIN
		dbms_rls.add_policy(
		    object_schema   => 'CHAIN',
		    object_name     => 'CARD_INIT_PARAM',
		    policy_name     => 'CARD_INIT_PARAM_POLICY',
		    function_schema => 'CHAIN',
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

BEGIN
	INSERT INTO chain.card_init_param_type(param_type_id, description) VALUES(0, 'Global Parameter. Applies to all cards in an application (that are part of any group).');
	INSERT INTO chain.card_init_param_type(param_type_id, description) VALUES(1, 'Specific Parameter. Applies to a specific card in a specific group and application.');
END;
/

@../chain/chain_pkg
@../chain/card_pkg
@../chain/card_body
@../chain/task_body

@update_tail