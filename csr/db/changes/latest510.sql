-- Please update version.sql too -- this keeps clean builds in sync
define version=510
@update_header

ALTER TABLE SHEET_VALUE ADD (
    VAR_EXPL_NOTE                  VARCHAR2(2000)
);

ALTER TABLE VAR_EXPL ADD (
    REQUIRES_NOTE        NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_REQUIRES_NOTE CHECK (REQUIRES_NOTE IN (0,1))
);

@..\sheet_pkg
@..\delegation_pkg
@..\sheet_body
@..\delegation_body

@update_tail
