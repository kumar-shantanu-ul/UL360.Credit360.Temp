-- Please update version.sql too -- this keeps clean builds in sync
define version=3459
define minor_version=1
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
DECLARE
	v_tag_id						csr.tag.tag_id%TYPE;
BEGIN
	security.user_pkg.logonadmin;
	
	FOR r IN (
		SELECT DISTINCT host, tag_group_id
		  FROM csr.tag_group tg
		  JOIN csr.customer c ON c.app_sid = tg.app_sid
		 WHERE lookup_key = 'RBA_AUDIT_STATUS'
	) LOOP
		security.user_pkg.logonadmin(r.host);
				
		INSERT INTO csr.tag (tag_id, lookup_key, parent_id)
		VALUES (csr.tag_id_seq.nextval, 'RBA_CLOSED', NULL)
		RETURNING tag_id INTO v_tag_id;
			
		INSERT INTO csr.tag_description (tag_id, lang, tag)
		VALUES (v_tag_id, 'en', 'Closed');

		INSERT INTO csr.tag_group_member (tag_group_id, tag_id, pos, active)
		VALUES (r.tag_group_id, v_tag_id, 0, 1);
		
		security.user_pkg.logonadmin;
	END LOOP;
	security.user_pkg.logonadmin;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
