-- Please update version.sql too -- this keeps clean builds in sync
define version=1098
@update_header

ALTER TABLE CMS.TAB_COLUMN ADD (
	VALUE_PLACEHOLDER NUMBER(1) DEFAULT 0 NOT NULL
);

ALTER TABLE CMS.TAB_COLUMN ADD CONSTRAINT CC_TAB_COLUMN_VAL_PLACEHOLDER 
    CHECK (VALUE_PLACEHOLDER IN(0,1));

BEGIN
	INSERT INTO cms.col_type VALUES (26, 'Enforce nullability');
END;
/

set define off
@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_body

@update_tail
