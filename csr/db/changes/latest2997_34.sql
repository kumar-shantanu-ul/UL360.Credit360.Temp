-- Please update version.sql too -- this keeps clean builds in sync
define version=2997
define minor_version=34
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.all_space
 DROP CONSTRAINT FK_PRP_TYP_SPC_TYP_SPC DROP INDEX;

ALTER TABLE csr.all_space
  ADD CONSTRAINT FK_ALL_SPC_TYP_SPC_TYP
FOREIGN KEY (app_sid, space_type_id)
REFERENCES csr.space_type(app_sid, space_type_id);

ALTER TABLE csr.all_space
  ADD CONSTRAINT FK_ALL_SPC_TYP_PROP_TYP
FOREIGN KEY (app_sid, property_type_id)
REFERENCES csr.property_type(app_sid, property_type_id);

CREATE INDEX csr.ix_space_type ON csr.all_space(app_sid, space_type_id);
CREATE INDEX csr.ix_space_type_prop_type ON csr.all_space(app_sid, property_type_id);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- C:\cvs\csr\db\create_views.sql
CREATE OR REPLACE VIEW csr.v$space AS
	SELECT s.app_sid, s.region_sid, r.description, r.active, r.parent_sid, s.space_type_id, st.label space_type_label, s.current_lease_id, s.property_region_Sid,
		   l.tenant_name current_tenant_name, r.disposal_dtm
	  FROM csr.space s
	  JOIN v$region r on s.region_sid = r.region_sid
	  JOIN space_type st ON s.space_type_Id = st.space_type_id
	  LEFT JOIN v$lease l ON l.lease_id = s.current_lease_id;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@..\region_pkg
@@..\space_pkg

@@..\region_body
@@..\property_body
@@..\space_body

@update_tail
