-- Please update version.sql too -- this keeps clean builds in sync
define version=3348
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.external_target_profile DROP (graph_api_url, sharepoint_tenant_id);

CREATE TABLE csr.external_target_profile_log (
	app_sid						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	target_profile_id			NUMBER(10) 		NOT NULL,
	changed_dtm					DATE 			NOT NULL,
	changed_by_user_sid			NUMBER(10) 		NOT NULL,
	message						VARCHAR2(4000) 	NOT NULL
);

CREATE INDEX csr.idx_ext_target_profile_log ON csr.external_target_profile_log(app_sid);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../target_profile_pkg

@../target_profile_body

@update_tail
