-- Please update version.sql too -- this keeps clean builds in sync
define version=3458
define minor_version=2
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
	v_tag_group_id					csr.tag_group.tag_group_id%TYPE;
    v_audit_type_id                 NUMBER;
	PROCEDURE AddTag(
		in_tag_group_id 				IN	NUMBER,
		in_name    						IN  VARCHAR2,
		in_lookup_key					IN	VARCHAR2,
		in_pos							IN	NUMBER
	)
	AS
		v_tag_id						csr.tag.tag_id%TYPE;
	BEGIN
		INSERT INTO csr.tag (tag_id, lookup_key, parent_id)
		VALUES (csr.tag_id_seq.nextval, in_lookup_key, NULL)
		RETURNING tag_id INTO v_tag_id;
			
		INSERT INTO csr.tag_description (tag_id, lang, tag)
		VALUES (v_tag_id, 'en', in_name);

		INSERT INTO csr.tag_group_member (tag_group_id, tag_id, pos, active)
		VALUES (in_tag_group_id, v_tag_id, in_pos, 1);
	END;
BEGIN
	security.user_pkg.logonadmin;
	
	FOR r IN (
		SELECT DISTINCT(host)
		  FROM csr.tag_group tg
		  JOIN csr.customer c ON c.app_sid = tg.app_sid
		 WHERE lookup_key = 'RBA_AUDIT_TYPE'
		   AND NOT EXISTS (
			SELECT NULL
			  FROM csr.tag_group
			 WHERE lookup_key = 'RBA_AUDIT_CAT'
			   AND app_sid = tg.app_sid
		   )
		   AND NOT EXISTS (
			SELECT NULL
			  FROM csr.tag_group_description
			 WHERE name = 'RBA Audit Category'
			   AND app_sid = tg.app_sid
		   )
	) LOOP
		security.user_pkg.logonadmin(r.host);
				
		INSERT INTO csr.tag_group (app_sid, tag_group_id, multi_select, mandatory, applies_to_audits, lookup_key)
		VALUES (security.security_pkg.GetAPP, csr.tag_group_id_seq.nextval, 0, 0, 1, 'RBA_AUDIT_CAT')
		RETURNING tag_group_id INTO v_tag_group_id;

		INSERT INTO csr.tag_group_description (app_sid, tag_group_id, lang, name)
		VALUES (security.security_pkg.GetAPP, v_tag_group_id, 'en', 'RBA Audit Category');
		
		AddTag(v_tag_group_id, 'VAP', 'RBA_VAP', 1);
		AddTag(v_tag_group_id, 'VAP: Small Business', 'RBA_VAP_SMALL_BUSINESS', 2);
		AddTag(v_tag_group_id, 'VAP: Medium Business', 'RBA_VAP_MEDIUM_BUSINESS', 3);
		AddTag(v_tag_group_id, 'Employment Site: SVAP Only', 'RBA_EMPLOYMENT_SITE_SVAP_ONLY', 4);
		AddTag(v_tag_group_id, 'Employment Site: SVAP and VAP', 'RBA_EMPLOYMENT_SITE_SVAP_AND_V', 5);
		
		SELECT internal_audit_type_id
		  INTO v_audit_type_id
		  FROM csr.internal_audit_type
		 WHERE lookup_key = 'RBA_AUDIT_TYPE';
		
		INSERT INTO csr.internal_audit_type_tag_group (internal_audit_type_id, tag_group_id)
		VALUES (v_audit_type_id, v_tag_group_id);
		
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
