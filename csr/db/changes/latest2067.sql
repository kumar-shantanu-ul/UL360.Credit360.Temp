-- Please update version.sql too -- this keeps clean builds in sync
define version=2067
@update_header

--Modify the column definition to match what the cache uses

ALTER TABLE csr.template MODIFY (
    MIME_TYPE    VARCHAR(255)
);


@update_tail
