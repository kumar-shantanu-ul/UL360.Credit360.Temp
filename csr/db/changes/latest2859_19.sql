-- Please update version.sql too -- this keeps clean builds in sync
define version=2859
define minor_version=19
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE cms.fk_cons ADD (
	CONSTRAINT uk_fk_cons_tab UNIQUE (app_sid, fk_cons_id, tab_sid)
);

ALTER TABLE cms.tab ADD (
	securable_fk_cons_id		NUMBER(10),
	CONSTRAINT fk_tab_sec_fk_cons 
		FOREIGN KEY (app_sid, securable_fk_cons_id, tab_sid) 
		REFERENCES cms.fk_cons (app_sid, fk_cons_id, tab_sid)
);

CREATE INDEX cms.ix_tab_sec_fk_cons ON cms.tab (app_sid, securable_fk_cons_id, tab_sid);

ALTER TABLE csrimp.cms_tab ADD (
	securable_fk_cons_id		NUMBER(10)
);
	

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../../../aspen2/cms/db/tab_body
@../../../aspen2/cms/db/filter_body
@../csrimp/imp_body

@update_tail
