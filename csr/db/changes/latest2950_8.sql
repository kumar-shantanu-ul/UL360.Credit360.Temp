-- Please update version.sql too -- this keeps clean builds in sync
define version=2950
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.internal_audit_type_group ADD (
	audits_menu_sid				NUMBER(10, 0),
	new_audit_menu_sid			NUMBER(10, 0),
	non_compliances_menu_sid	NUMBER(10, 0),
	block_css_class				VARCHAR2(255)
);

ALTER TABLE csrimp.internal_audit_type_group ADD (
	audits_menu_sid				NUMBER(10, 0),
	new_audit_menu_sid			NUMBER(10, 0),
	non_compliances_menu_sid	NUMBER(10, 0),
	block_css_class				VARCHAR2(255)
);

-- *** Grants ***
GRANT update ON security.menu TO csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
CREATE OR REPLACE PACKAGE csr.latest_US4400_pkg IS

PROCEDURE FindMenuSid(
	in_name			IN	security.security_pkg.T_SO_NAME,
	out_menu_sid 	OUT security. security_pkg.T_SID_ID		
);

END latest_US4400_pkg;
/

CREATE OR REPLACE PACKAGE BODY csr.latest_US4400_pkg IS

PROCEDURE FindMenuSid(
	in_name			IN	security.security_pkg.T_SO_NAME,
	out_menu_sid 	OUT security. security_pkg.T_SID_ID		
)
IS
	v_cur			security.security_pkg.T_OUTPUT_CUR;
	v_row			security.menu%ROWTYPE;
BEGIN
	security.menu_pkg.FindMenuItem(
		security.security_pkg.GetACT, 
		security.security_pkg.GetApp, 
		in_name,
		v_cur
	);

	IF v_cur%NOTFOUND THEN
		out_menu_sid := NULL;
	ELSE
		FETCH v_cur INTO v_row;
		out_menu_sid := v_row.sid_id;
	END IF;
END;

END latest_US4400_pkg;
/

DECLARE
	v_audits_menu_sid			NUMBER(10, 0);
	v_new_audit_menu_sid		NUMBER(10, 0);
	v_non_compliances_menu_sid	NUMBER(10, 0);
BEGIN
	FOR s IN (
		SELECT c.host
		  FROM csr.customer c
		 WHERE EXISTS ( SELECT * FROM csr.internal_audit_type_group iatg WHERE iatg.app_sid = c.app_sid )
	) LOOP
		security.user_pkg.logonadmin(s.host);
		
		FOR r IN (
			SELECT iatg.internal_audit_type_group_id, LOWER(iatg.lookup_key) lookup_key
			  FROM csr.internal_audit_type_group iatg
		) LOOP
			csr.latest_US4400_pkg.FindMenuSid('csr_audit_browse_'		  || r.lookup_key, v_audits_menu_sid);
			csr.latest_US4400_pkg.FindMenuSid('csr_site_audit_editAudit_' || r.lookup_key, v_new_audit_menu_sid);
			csr.latest_US4400_pkg.FindMenuSid('csr_non_compliance_list_'  || r.lookup_key, v_non_compliances_menu_sid);
			
			UPDATE csr.internal_audit_type_group
				SET audits_menu_sid = NVL(audits_menu_sid, v_audits_menu_sid),
					new_audit_menu_sid = NVL(new_audit_menu_sid, v_new_audit_menu_sid),
					non_compliances_menu_sid = NVL(non_compliances_menu_sid, v_non_compliances_menu_sid)
				WHERE internal_audit_type_group_id = r.internal_audit_type_group_id;
		END LOOP;
	END LOOP;
END;
/

DROP PACKAGE BODY csr.latest_US4400_pkg;
DROP PACKAGE csr.latest_US4400_pkg;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_pkg
@../audit_body
@../schema_body
@../csrimp/imp_body

@update_tail
