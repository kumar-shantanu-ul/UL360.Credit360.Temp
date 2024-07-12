-- Please update version.sql too -- this keeps clean builds in sync
define version=2989
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.non_compliance RENAME COLUMN survey_response_id TO xxx_survey_response_id;
ALTER TABLE csrimp.non_compliance DROP COLUMN survey_response_id;

ALTER TABLE csr.audit_non_compliance ADD (
	attached_to_primary_survey			NUMBER(1, 0) DEFAULT 0 NOT NULL,
	internal_audit_type_survey_id		NUMBER(10, 0),
	CONSTRAINT ck_anc_survey CHECK (
		attached_to_primary_survey = 0 OR
		(attached_to_primary_survey = 1 AND internal_audit_type_survey_id IS NULL)
	)
);

ALTER TABLE csrimp.audit_non_compliance ADD (
	attached_to_primary_survey			NUMBER(1, 0) DEFAULT 0 NOT NULL,
	internal_audit_type_survey_id		NUMBER(10, 0)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

DECLARE
	v_detached			NUMBER(1, 0);
	v_iats_id			NUMBER(10, 0);
BEGIN
	security.user_pkg.logonadmin;

	FOR site IN (
		SELECT c.app_sid, c.host
		  FROM csr.customer c
		 WHERE EXISTS (
				SELECT NULL
				  FROM csr.non_compliance
				 WHERE app_sid = c.app_sid
				   AND xxx_survey_response_id IS NOT NULL
		 )
	) LOOP
		security.user_pkg.logonadmin(site.host);

		FOR r IN (
			SELECT nc.app_sid, nc.non_compliance_id, nc.created_in_audit_sid, nc.xxx_survey_response_id,
				   CASE WHEN nc.xxx_survey_response_id = ia.survey_response_id THEN 0 ELSE iats.internal_audit_type_survey_id END internal_audit_type_survey_id,  
				   CASE WHEN nc.xxx_survey_response_id = ia.survey_response_id THEN 0 ELSE iats.ia_type_survey_group_id END ia_type_survey_group_id
			  FROM csr.non_compliance nc
			  JOIN csr.internal_audit ia ON ia.internal_audit_sid = nc.created_in_audit_sid
			  LEFT JOIN csr.internal_audit_survey ias ON ias.internal_audit_sid = nc.created_in_audit_sid
													 AND ias.survey_response_id = nc.xxx_survey_response_id
													 AND ias.app_sid = nc.app_sid
			  LEFT JOIN csr.internal_audit_type_survey iats ON iats.internal_audit_type_survey_id = ias.internal_audit_type_survey_id
														   AND iats.app_sid = ias.app_sid
			 WHERE nc.app_sid = site.app_sid
			   AND nc.xxx_survey_response_id IS NOT NULL
		) LOOP
			IF r.internal_audit_type_survey_id = 0 THEN
				UPDATE csr.audit_non_compliance
					   SET attached_to_primary_survey = 1
					 WHERE non_compliance_id = r.non_compliance_id
					   AND app_sid = r.app_sid;
			ELSE
				v_detached := 0;

				FOR rr IN (
					SELECT anc.app_sid, anc.audit_non_compliance_id, anc.internal_audit_sid,
						   iats.internal_audit_type_survey_id, iats.ia_type_survey_group_id
					  FROM csr.audit_non_compliance anc
					  JOIN csr.internal_audit ia
					    ON ia.internal_audit_sid = anc.internal_audit_sid
					   AND ia.app_sid = anc.app_sid
					  LEFT JOIN csr.internal_audit_type_survey iats
					    ON iats.internal_audit_type_id = ia.internal_audit_type_id
					   AND (
							iats.internal_audit_type_survey_id = r.internal_audit_type_survey_id OR
							iats.ia_type_survey_group_id = r.ia_type_survey_group_id
					   )
					 WHERE anc.non_compliance_id = r.non_compliance_id
					   AND anc.app_sid = r.app_sid
				  ORDER BY anc.internal_audit_sid ASC
				) LOOP
					v_iats_id := rr.internal_audit_type_survey_id;

					IF v_iats_id IS NULL THEN
						v_detached := 1;
					END IF;

					UPDATE csr.audit_non_compliance
					   SET internal_audit_type_survey_id = CASE WHEN v_detached = 1 THEN NULL ELSE v_iats_id END
					 WHERE audit_non_compliance_id = rr.audit_non_compliance_id
					   AND app_sid = rr.app_sid;
				END LOOP;
			END IF;
		END LOOP;
	END LOOP;

	security.user_pkg.logonadmin;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_pkg

@../audit_body
@../quick_survey_body
@../schema_body
@../csrimp/imp_body

@update_tail
