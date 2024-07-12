-- Please update version.sql too -- this keeps clean builds in sync
define version=2832
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE CHAIN.FILTER_PAGE_CMS_TABLE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE chain.filter_page_cms_table (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	filter_page_cms_table_id		NUMBER(10) NOT NULL,
	card_group_id					NUMBER(10) NOT NULL,
	column_sid						NUMBER(10) NOT NULL,
	CONSTRAINT pk_filter_page_cms_table PRIMARY KEY (app_sid, filter_page_cms_table_id),
	CONSTRAINT fk_filter_page_cms_table_col FOREIGN KEY (app_sid, column_sid) REFERENCES cms.tab_column (app_sid, column_sid)
);

CREATE INDEX chain.ix_filter_page_cms_table_col ON chain.filter_page_cms_table(app_sid, column_sid);


-- Alter tables

-- *** Grants ***
GRANT SELECT, DELETE ON chain.filter_page_cms_table TO cms;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\chain\filter_pkg
@..\chain\filter_body

@..\..\..\aspen2\cms\db\filter_pkg
@..\..\..\aspen2\cms\db\filter_body
@..\..\..\aspen2\cms\db\tab_body
@update_tail
