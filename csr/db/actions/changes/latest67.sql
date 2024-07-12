-- Please update version.sql too -- this keeps clean builds in sync
define version=67
@update_header

ALTER TABLE TASK_STATUS ADD (
	IS_REJECTED       NUMBER(1, 0)     DEFAULT 0  NOT NULL
    CHECK (IS_REJECTED IN(0,1)),
    CHECK (IS_LIVE IN(0,1)),
    CHECK (IS_DEFAULT IN(0,1))
);

@update_tail
