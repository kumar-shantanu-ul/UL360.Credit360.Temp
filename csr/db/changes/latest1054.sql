-- Please update version.sql too -- this keeps clean builds in sync
define version=1054
@update_header


CREATE GLOBAL TEMPORARY TABLE CSR.MAP_ID(
	OLD_ID					NUMBER(10)	NOT NULL,
	NEW_ID					NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_ID PRIMARY KEY (OLD_ID) USING INDEX,
	CONSTRAINT UK_MAP_ID UNIQUE (NEW_ID) USING INDEX
) ON COMMIT DELETE ROWS;

@..\deleg_plan_pkg

@..\deleg_plan_body

@update_tail
