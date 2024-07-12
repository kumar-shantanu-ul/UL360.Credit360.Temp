-- Please update version.sql too -- this keeps clean builds in sync
define version=2058
@update_header

alter table csr.alert_template add (
    FROM_NAME                 VARCHAR2(255),
    FROM_EMAIL                VARCHAR2(255)
);

@..\alert_body

@update_tail
