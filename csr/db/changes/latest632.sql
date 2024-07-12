-- Please update version.sql too -- this keeps clean builds in sync
define version=632
@update_header


ALTER TABLE csr.delegation_grid ADD (
    HELPER_PKG    VARCHAR2(255),
    NAME        VARCHAR2(255)
);

-- stick some data in for now
UPDATE csr.delegation_grid SET name = NVL(path,'unknown'); 

ALTER TABLE csr.delegation_grid MODIFY name NOT NULL;

ALTER TABLE csr.role ADD (
    REGION_PERMISSION_SET    NUMBER(10, 0)
);

@..\sheet_pkg
@..\role_pkg

@..\sheet_body
@..\role_body

@update_tail
