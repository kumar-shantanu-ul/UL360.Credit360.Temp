-- Please update version.sql too -- this keeps clean builds in sync
define version=2832
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_company_capability_id		NUMBER(10, 0);
	v_suppliers_capability_id	NUMBER(10, 0);
BEGIN
	SELECT capability_id
	  INTO v_company_capability_id
	  FROM chain.capability
	 WHERE capability_name = 'Company';
	 
	SELECT capability_id
	  INTO v_suppliers_capability_id
	  FROM chain.capability
	 WHERE capability_name = 'Suppliers';

	FOR r IN (
		SELECT c.app_sid, c.host, fc.*
		  FROM csr.customer c
		  JOIN csr.flow_capability fc ON fc.flow_capability_id = 1001
		 WHERE EXISTS (
			SELECT *
			  FROM chain.implementation
			 WHERE app_sid = c.app_sid
		 )
	) LOOP
		security.user_pkg.logonadmin(r.host);
		
		DECLARE
			v_flow_capability_id	NUMBER(10, 0) := csr.customer_flow_cap_id_seq.NEXTVAL;
		BEGIN
			INSERT INTO csr.customer_flow_capability (app_sid, flow_capability_id, flow_alert_class, description, perm_type, default_permission_set, lookup_key)
			VALUES (r.app_sid, v_flow_capability_id, r.flow_alert_class, 'Chain: Company / Supplier', r.perm_type, r.default_permission_set, NULL);

			BEGIN
				INSERT INTO chain.capability_flow_capability (app_sid, flow_capability_id, capability_id)
				VALUES (r.app_sid, v_flow_capability_id, v_company_capability_id);
			EXCEPTION
				WHEN dup_val_on_index THEN
					NULL;
			END;
		
			BEGIN
				INSERT INTO chain.capability_flow_capability (app_sid, flow_capability_id, capability_id)
				VALUES (r.app_sid, v_flow_capability_id, v_suppliers_capability_id);
			EXCEPTION
				WHEN dup_val_on_index THEN
					NULL;
			END;

			FOR rr IN (
				SELECT *
				  FROM csr.flow_state_role_capability
				 WHERE app_sid = r.app_sid
				   AND flow_capability_id = r.flow_capability_id
			) LOOP
				INSERT INTO csr.flow_state_role_capability (app_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id, role_sid, flow_involvement_type_id, permission_set, group_sid)
				VALUES (rr.app_sid, csr.flow_state_rl_cap_id_seq.NEXTVAL, rr.flow_state_id, v_flow_capability_id, rr.role_sid, rr.flow_involvement_type_id, rr.permission_set, rr.group_sid);
			END LOOP;
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
		
		DELETE FROM csr.flow_state_role_capability WHERE app_sid = r.app_sid AND flow_capability_id = r.flow_capability_id;
	END LOOP;
	
	security.user_pkg.logonadmin();
	DELETE FROM csr.flow_capability WHERE flow_capability_id = 1001;

	COMMIT;
END;
/

-- ** New package grants **

-- *** Packages ***

@../csr_data_pkg

@../chain/company_body
@../chain/type_capability_body
@../flow_body

@update_tail
