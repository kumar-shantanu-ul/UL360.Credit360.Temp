-- Please update version.sql too -- this keeps clean builds in sync
define version=3142
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables
CREATE GLOBAL TEMPORARY TABLE CMS.PAGED_TT_ID
( 
	ID							NUMBER(10) NOT NULL
) 
ON COMMIT DELETE ROWS; 
CREATE UNIQUE INDEX CMS.UK_PAGED_TT_ID ON CMS.PAGED_TT_ID (ID);

-- Alter tables
ALTER TABLE csr.flow_item ADD (
	region_sid			NUMBER(10),
	CONSTRAINT fk_flow_item_region FOREIGN KEY (app_sid, region_sid) 
		REFERENCES csr.region (app_sid, region_sid)
);

CREATE INDEX csr.ix_flow_item_region ON csr.flow_item (app_sid, region_sid);

ALTER TABLE csrimp.flow_item ADD (
	region_sid			NUMBER(10)
);

ALTER TABLE cms.tab ADD (
	storage_location	VARCHAR2(255) DEFAULT 'oracle' NOT NULL
);

ALTER TABLE csrimp.cms_tab ADD (
	storage_location	VARCHAR2(255) NOT NULL
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
create or replace package csr.form_data_pkg as
end;
/
grant execute on csr.form_data_pkg to web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../flow_pkg
@../form_data_pkg

@../audit_body
@../approval_dashboard_body
@../csrimp/imp_body
@../../../aspen2/cms/db/tab_body
@../schema_body
@../flow_body
@../form_data_body

@update_tail
