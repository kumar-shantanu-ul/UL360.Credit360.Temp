-- Please update version.sql too -- this keeps clean builds in sync
define version=3387
define minor_version=3
@update_header
@@latestUD-11792_packages
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
	PROCEDURE ReplaceAuditTypeByLookUpKey(
		in_old_audit_lookup_key IN csr.internal_audit_type.lookup_key%TYPE,
		in_new_audit_lookup_key IN csr.internal_audit_type.lookup_key%TYPE
	)
	AS
		v_new_audit_type_id 	NUMBER 							:= -1;
		v_old_audit_type_id 	NUMBER 							:= -1;
		v_app_sid				SECURITY.SECURITY_PKG.T_SID_ID	:= SYS_CONTEXT('SECURITY', 'APP');
	BEGIN
		BEGIN
			SELECT internal_audit_type_id
			  INTO v_old_audit_type_id
			  FROM csr.internal_audit_type
			 WHERE app_sid = v_app_sid
			   AND lookup_key = in_old_audit_lookup_key;
		EXCEPTION 
			WHEN NO_DATA_FOUND THEN
				RETURN;
		END;

		BEGIN
			SELECT internal_audit_type_id
			  INTO v_new_audit_type_id
			  FROM csr.internal_audit_type
			 WHERE app_sid = v_app_sid
			   AND lookup_key = in_new_audit_lookup_key;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN;
		END;

		If (v_new_audit_type_id > 0 AND v_old_audit_type_id > 0) THEN
			UPDATE csr.quick_survey
			   SET auditing_audit_type_id = v_new_audit_type_id
			 WHERE auditing_audit_type_id = v_old_audit_type_id
			   AND app_sid = v_app_sid;
			   
			UPDATE csr.internal_audit_type_survey
			   SET internal_audit_type_id = v_new_audit_type_id
			 WHERE internal_audit_type_id = v_old_audit_type_id
			   AND app_sid = v_app_sid;
			   
			UPDATE csr.flow_state_audit_ind
			   SET internal_audit_type_id = v_new_audit_type_id
			 WHERE internal_audit_type_id = v_old_audit_type_id 
			   AND app_sid = v_app_sid;
			   
			UPDATE csr.internal_audit
			   SET internal_audit_type_id = v_new_audit_type_id
			 WHERE internal_audit_type_id = v_old_audit_type_id
			   AND app_sid = v_app_sid;

			DELETE FROM csr.score_type_audit_type
			 WHERE internal_audit_type_id = v_old_audit_type_id 
			   AND app_sid = v_app_sid;
			   
			DELETE FROM csr.region_internal_audit
			 WHERE internal_audit_type_id = v_old_audit_type_id 
			   AND app_sid = v_app_sid;
			   
			DELETE FROM csr.internal_audit_type_tag_group
			 WHERE internal_audit_type_id = v_old_audit_type_id
			   AND app_sid = v_app_sid;
			   
			DELETE FROM csr.audit_type_non_comp_default 
			 WHERE internal_audit_type_id = v_old_audit_type_id
			   AND app_sid = v_app_sid;
			   
			DELETE FROM csr.audit_type_flow_inv_type
			 WHERE internal_audit_type_id = v_old_audit_type_id 
			   AND app_sid= v_app_sid;
			   
			csr.temp_audit_pkg.DeleteInternalAuditType(v_old_audit_type_id);
		END IF;
	END;
BEGIN
	security.user_pkg.logonadmin();
	FOR apps IN (
		SELECT app_sid, host
		  FROM csr.customer c
		  JOIN security.website w ON c.host = w.website_name
	)
	LOOP
		security.user_pkg.logonadmin(apps.host);

		ReplaceAuditTypeByLookUpKey('RBA_PRIORITY_CLOSURE_AUDIT','RBA_INITIAL_AUDIT');
		ReplaceAuditTypeByLookUpKey('RBA_CLOSURE_AUDIT','RBA_INITIAL_AUDIT');
		
		UPDATE csr.internal_audit_type
		   SET label = 'RBA', lookup_key = 'RBA_AUDIT_TYPE' 
		 WHERE app_sid = apps.app_sid
		   AND lookup_key = 'RBA_INITIAL_AUDIT';
		
		DELETE FROM csr.internal_audit_tag iat
		 WHERE EXISTS (
			SELECT NULL
			  FROM csr.tag
			 WHERE lookup_key IN ('RBA_VAP', 'RBA_VAP_MEDIUM_BUSINESS', 'RBA_EMPLOYMENT_SITE_SVA_ONLY')
			   AND tag_id = iat.tag_id
		);
		
		-- Rename Audit Category Tags
		UPDATE csr.tag
		   SET lookup_key = 'RBA_INITIAL_AUDIT' 
		 WHERE app_sid = apps.app_sid
		   AND lookup_key = 'RBA_VAP';
		
		UPDATE csr.tag_description td
		   SET tag = 'Initial Audit'
		 WHERE EXISTS(
			SELECT NULL
			  FROM csr.tag
			 WHERE tag_id = td.tag_id
			   AND lookup_key = 'RBA_INITIAL_AUDIT'
			);
		
		UPDATE csr.tag
		   SET lookup_key = 'RBA_PRIORITY_CLOSURE_AUDIT' 
		 WHERE app_sid = apps.app_sid
		   AND lookup_key = 'RBA_VAP_MEDIUM_BUSINESS';
		
		UPDATE csr.tag_description td
		   SET tag = 'Priority Closure Audit'
		 WHERE EXISTS(
			SELECT NULL
			  FROM csr.tag
			 WHERE tag_id = td.tag_id
			   AND lookup_key = 'RBA_PRIORITY_CLOSURE_AUDIT'
			);
		
		UPDATE csr.tag
		   SET lookup_key = 'RBA_CLOSURE_AUDIT' 
		 WHERE app_sid = apps.app_sid
		   AND lookup_key = 'RBA_EMPLOYMENT_SITE_SVA_ONLY';
		   
		UPDATE csr.tag_description td
		   SET tag = 'Closure Audit'
		 WHERE EXISTS(
			SELECT NULL
			  FROM csr.tag
			 WHERE tag_id = td.tag_id
			   AND lookup_key = 'RBA_CLOSURE_AUDIT'
			);

		security.user_pkg.logonadmin();
	END LOOP;	
END;
/

-- ** New package grants **
DROP PACKAGE csr.temp_audit_pkg;

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
