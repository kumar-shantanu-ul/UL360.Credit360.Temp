-- Please update version.sql too -- this keeps clean builds in sync
define version=218
@update_header

ALTER TABLE SECTION DROP COLUMN PLUGIN_CONFIG;
ALTER TABLE SECTION ADD (
    PLUGIN_CONFIG                 SYS.XMLType
);


@update_tail