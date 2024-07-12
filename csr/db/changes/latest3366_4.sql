-- Please update version.sql too -- this keeps clean builds in sync
define version=3366
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.non_compliance ADD (
	lookup_key 	VARCHAR2(255)
);

CREATE UNIQUE INDEX csr.uk_non_compliance_lookup ON csr.non_compliance(app_sid, NVL(UPPER(lookup_key), TO_CHAR(non_compliance_id)))
;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
@latestUD7851_packages

DECLARE
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_nct_id						NUMBER(10);
	v_tag_group_id					csr.tag_group.tag_group_id%TYPE;
	v_tag_id						csr.tag.tag_id%TYPE;
	v_nc_types						security.security_pkg.T_SID_IDS;
	v_dummy_sids					security.security_pkg.T_SID_IDS;
BEGIN
	security.user_pkg.logonadmin();
	FOR R IN (
		SELECT cr.app_sid
		  FROM chain.reference cr
		 WHERE cr.lookup_key = 'RBA_SITECODE'
	) LOOP
		security.user_pkg.logonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, r.app_sid, v_act_id);
		v_app_sid := r.app_sid;
		
		csr.temp_audit_pkg.SetNonComplianceType(
			in_non_compliance_type_id		=> NULL,
			in_label						=> 'RBA Finding',
			in_lookup_key					=> 'RBA_FINDING',
			in_position						=> 0,
			in_colour_when_open				=> 16712965,
			in_colour_when_closed			=> 3777539, 
			in_can_have_actions				=> 1,
			in_closure_behaviour_id			=> 1,
			in_repeat_audit_type_ids		=> v_dummy_sids,
			out_non_compliance_type_id		=> v_nct_id
		);
		
		FOR ATYP IN (
			SELECT internal_audit_type_id
			  FROM csr.internal_audit_type
			 WHERE lookup_key IN ('RBA_INITIAL_AUDIT', 'RBA_CLOSURE_AUDIT', 'RBA_PRIORITY_CLOSURE_AUDIT')
		) LOOP
			csr.temp_audit_pkg.SetAuditTypeNonCompType(
				in_internal_audit_type_id	=> ATYP.internal_audit_type_id,
				in_non_compliance_type_id	=> v_nct_id
			);
		END LOOP;
		
		v_nc_types(1) := v_nct_id;
		
		-- Finding Status:
		csr.temp_tag_pkg.SetTagGroup(
			in_act_id				=> v_act_id,
			in_app_sid				=> v_app_sid,
			in_name					=> 'Finding Status',
			in_multi_select			=> 0,
			in_mandatory			=> 0,
			in_applies_to_non_comp	=> 1,
			in_lookup_key			=> 'RBA_F_FINDING_STATUS',
			out_tag_group_id		=> v_tag_group_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Plan Initiated',
			in_pos					=> 0,
			in_lookup_key			=> 'RBA_F_PLAN_INITIATED',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Plan Submitted for Approval',
			in_pos					=> 1,
			in_lookup_key			=> 'RBA_F_PLAN_SUBMITTED_FOR_APPRO',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Plan Needs Revision',
			in_pos					=> 2,
			in_lookup_key			=> 'RBA_F_PLAN_NEEDS_REVISION',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Plan Approved / Actions underway',
			in_pos					=> 3,
			in_lookup_key			=> 'RBA_F_PLAN_APPROVED__ACTIONS_U',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Actions Submitted for Approval',
			in_pos					=> 4,
			in_lookup_key			=> 'RBA_F_ACTIONS_SUBMITTED_FOR_AP',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Further Action Required',
			in_pos					=> 5,
			in_lookup_key			=> 'RBA_F_FURTHER_ACTION_REQUIRED',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Actions Completed / Eligible for Closure Audit',
			in_pos					=> 6,
			in_lookup_key			=> 'RBA_F_ACTIONS_COMPLETED__ELIGI',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Closed',
			in_pos					=> 7,
			in_lookup_key			=> 'RBA_F_CLOSED',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTagGroupNCTypes(
			in_tag_group_id			=> v_tag_group_id,
			in_nc_ids				=> v_nc_types
		);
		
		-- Finding Severity:
		csr.temp_tag_pkg.SetTagGroup(
			in_act_id				=> v_act_id,
			in_app_sid				=> v_app_sid,
			in_name					=> 'Finding Severity',
			in_multi_select			=> 0,
			in_mandatory			=> 0,
			in_applies_to_non_comp	=> 1,
			in_lookup_key			=> 'RBA_F_FINDING_SEVERITY',
			out_tag_group_id		=> v_tag_group_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Priority Non-Conformance',
			in_pos					=> 0,
			in_lookup_key			=> 'RBA_F_PRIORITY_NONCONFORMANCE',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Major Non-Conformance',
			in_pos					=> 1,
			in_lookup_key			=> 'RBA_F_MAJOR_NONCONFORMANCE',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Minor Non-Conformance',
			in_pos					=> 2,
			in_lookup_key			=> 'RBA_F_MINOR_NONCONFORMANCE',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Risk of Non-Conformance',
			in_pos					=> 3,
			in_lookup_key			=> 'RBA_F_RISK_OF_NONCONFORMANCE',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Opportunity for Improvement',
			in_pos					=> 4,
			in_lookup_key			=> 'RBA_F_OPPORTUNITY_FOR_IMPROVEM',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Conformance',
			in_pos					=> 5,
			in_lookup_key			=> 'RBA_F_CONFORMANCE',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTag(
			in_act_id				=> v_act_id,
			in_tag_group_id			=> v_tag_group_id,
			in_tag					=> 'Not Applicable',
			in_pos					=> 6,
			in_lookup_key			=> 'RBA_F_NOT_APPLICABLE',
			in_active				=> 1,
			out_tag_id				=> v_tag_id
		);
		
		csr.temp_tag_pkg.SetTagGroupNCTypes(
			in_tag_group_id			=> v_tag_group_id,
			in_nc_ids				=> v_nc_types
		);
	END LOOP;
	security.user_pkg.logonadmin();
END;
/

DROP PACKAGE csr.temp_audit_pkg;
DROP PACKAGE csr.temp_tag_pkg;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_pkg

@../audit_body
@../enable_body

@update_tail
