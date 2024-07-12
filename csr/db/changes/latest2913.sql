-- Please update version.sql too -- this keeps clean builds in sync
define version=2913
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

BEGIN
	FOR chk IN (
		SELECT *
		  FROM dual
		 WHERE NOT EXISTS (
			SELECT *
			  FROM all_constraints
			 WHERE owner = 'CSR'
			   AND constraint_name = 'PK_AUDIT_NON_COMPLIANCE'
		  )
	) LOOP
		UPDATE csr.audit_non_compliance
		   SET audit_non_compliance_id = csr.audit_non_compliance_id_seq.nextval
		 WHERE audit_non_compliance_id IS NULL;
		
		EXECUTE IMMEDIATE 'ALTER TABLE csr.audit_non_compliance ADD (
				CONSTRAINT pk_audit_non_compliance	PRIMARY KEY(app_sid, audit_non_compliance_id),
				CONSTRAINT fk_anc_repeat_anc		FOREIGN KEY (app_sid, repeat_of_audit_nc_id)
					REFERENCES csr.audit_non_compliance (app_sid, audit_non_compliance_id)
			)';
	END LOOP;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
