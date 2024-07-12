-- Please update version.sql too -- this keeps clean builds in sync
define version=1871
@update_header

ALTER TABLE CMS.TAB_COLUMN ADD (
    OWNER_PERMISSION NUMBER(1),
    CONSTRAINT CC_TAB_COLUMN_OWNER_PERMISSION CHECK (OWNER_PERMISSION IS NULL OR OWNER_PERMISSION IN (0, 1, 2))
);

@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_body

@update_tail
