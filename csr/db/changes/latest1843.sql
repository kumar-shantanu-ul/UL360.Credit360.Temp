-- Please update version.sql too -- this keeps clean builds in sync
define version=1843
@update_header

ALTER TABLE csr.flow_state ADD (
    IS_EDITABLE_BY_OWNER    NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT CK_IS_EDITABLE_BY_OWNER CHECK (IS_EDITABLE_BY_OWNER IN (0,1))
);


@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_body

@update_tail
