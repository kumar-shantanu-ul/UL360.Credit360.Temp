-- Please update version.sql too -- this keeps clean builds in sync
define version=2335
@update_header

--Modify the column definition to match what the cache uses

ALTER TABLE csrimp.template MODIFY (
    MIME_TYPE    VARCHAR2(255)
);

@update_tail
