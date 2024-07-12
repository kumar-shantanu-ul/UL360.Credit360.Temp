-- Please update version.sql too -- this keeps clean builds in sync
define version=658
@update_header

alter table csr.role add (
    IS_SUPPLIER              NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_ROLE_IS_SUPPLIER CHECK (IS_SUPPLIER IN (0,1))
);

@..\supplier_pkg
@..\supplier_body

@update_tail


