-- Please update version.sql too -- this keeps clean builds in sync
define version=457
@update_header
 
ALTER TABLE ROLE ADD(
    IS_METERING            NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    IS_PROPERTY_MANAGER    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    IS_DELEGATION          NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_ROLE_IS_METERING CHECK (IS_METERING IN (0,1)),
    CONSTRAINT CHK_ROLE_IS_PROP_MGR CHECK (IS_PROPERTY_MANAGER IN (0,1)),
    CONSTRAINT CHK_ROLE_IS_DELEG CHECK (IS_DELEGATION IN (0,1))
)
;


INSERT INTO CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('View all meters', 0);

@../meter_body

@update_tail
