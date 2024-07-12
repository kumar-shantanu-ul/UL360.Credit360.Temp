-- Please update version.sql too -- this keeps clean builds in sync
define version=3368
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	FOR r IN (SELECT tag_group_id FROM csr.tag_group WHERE lookup_key = 'RBA_F_FINDING_STATUS')
	LOOP
		DELETE FROM csr.non_compliance_tag
		 WHERE tag_id IN (SELECT tag_id FROM csr.tag_group_member WHERE tag_group_id = r.tag_group_id);
		 
		DELETE FROM csr.tag_group_member
		 WHERE tag_group_id = r.tag_group_id;
		
		DELETE FROM csr.tag_description
		 WHERE tag_id IN (SELECT tag_id FROM csr.tag_group_member WHERE tag_group_id = r.tag_group_id);
		 
		DELETE FROM csr.tag
		 WHERE tag_id IN (SELECT tag_id FROM csr.tag_group_member WHERE tag_group_id = r.tag_group_id);
		   
		DELETE FROM csr.non_compliance_type_tag_group
		 WHERE tag_group_id = r.tag_group_id;
		 
		DELETE FROM csr.tag_group_description
		 WHERE tag_group_id = r.tag_group_id;

		DELETE FROM csr.tag_group
		 WHERE tag_group_id = r.tag_group_id;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
