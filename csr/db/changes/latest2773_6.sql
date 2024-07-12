-- Please update version.sql too -- this keeps clean builds in sync
define version=2773
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.FB52294_duplicate_inds (
	APP_SID		NUMBER(10, 0) NOT NULL,
	IND_SID		NUMBER(10, 0) NOT NULL,
	LOOKUP_KEY	VARCHAR2(1024)
);

-- Alter tables
ALTER TABLE csr.audit_type_closure_type ADD (
	ind_sid						NUMBER(10, 0),
	CONSTRAINT fk_atct_ind		FOREIGN KEY (app_sid, ind_sid) REFERENCES csr.ind (app_sid, ind_sid)
);

ALTER TABLE csrimp.audit_type_closure_type ADD (
	ind_sid			NUMBER(10, 0)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_iat_lookup_key	csr.internal_audit_type.lookup_key%TYPE;

	v_ind_sid			csr.ind.ind_sid%TYPE;
	v_ind_lookup_key	csr.ind.lookup_key%TYPE;
BEGIN
	FOR x IN (
		SELECT app_sid, host
		  FROM csr.customer c
		 WHERE EXISTS (
			SELECT * 
			  FROM csr.audit_type_closure_type
			 WHERE app_sid = c.app_sid
		 )
	) LOOP
		security.user_pkg.logonadmin(x.host);

		FOR y IN (
			SELECT app_sid, internal_audit_type_id, lookup_key
			  FROM csr.internal_audit_type
			 WHERE app_sid = x.app_sid
		) LOOP
			IF y.lookup_key IS NOT NULL THEN
				v_iat_lookup_key := y.lookup_key;
			ELSE
				v_iat_lookup_key := 'IAT_'||y.internal_audit_type_id||'_A';
			END IF;

			-- fix the folders
			v_ind_lookup_key := v_iat_lookup_key||'_RESULTS';

			UPDATE csr.ind
			   SET measure_sid = NULL
			 WHERE app_sid = y.app_sid
			   AND lookup_key = v_ind_lookup_key;

			-- now fix the closure types
			FOR z IN (
				SELECT act.app_sid, act.audit_closure_type_id, act.label
				  FROM csr.audit_type_closure_type atct
				  JOIN csr.audit_closure_type act 
				    ON atct.audit_closure_type_id = act.audit_closure_type_id
				   AND atct.app_sid = act.app_sid
				 WHERE atct.app_sid = y.app_sid
				   AND atct.internal_audit_type_id = y.internal_audit_type_id
			) LOOP
				v_ind_lookup_key := v_iat_lookup_key||'_RESULT_'||UPPER(z.label);
				
				BEGIN
					SELECT ind_sid
					  INTO v_ind_sid
					  FROM csr.ind
					 WHERE app_sid = z.app_sid
					   AND lookup_key = v_ind_lookup_key;

					UPDATE csr.audit_type_closure_type
					   SET ind_sid = v_ind_sid
					 WHERE app_sid = z.app_sid
					   AND internal_audit_type_id = y.internal_audit_type_id
					   AND audit_closure_type_id = z.audit_closure_type_id;
				EXCEPTION 
					WHEN no_data_found THEN
						NULL;
					WHEN too_many_rows THEN
						INSERT INTO csr.FB52294_duplicate_inds (app_sid, ind_sid, lookup_key)
							 SELECT app_sid, ind_sid, lookup_key
							   FROM csr.ind
							  WHERE app_sid = z.app_sid
							    AND lookup_key = v_ind_lookup_key;
				END;
			END LOOP;
		END LOOP;
	END LOOP;
	
	security.user_pkg.logonadmin;
END;
/

-- ** New package grants **

-- *** Packages ***
@../audit_body
@../schema_body
@../csrimp/imp_body

@update_tail
