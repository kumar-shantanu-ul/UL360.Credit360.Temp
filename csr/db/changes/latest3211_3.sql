-- Please update version.sql too -- this keeps clean builds in sync
define version=3211
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

DECLARE
	PROCEDURE EnablePortletForCustomer(
		in_portlet_id	IN csr.portlet.portlet_id%TYPE
	)
	AS
		v_customer_portlet_sid		security.security_pkg.T_SID_ID;
		v_portlets_sid				security.security_pkg.T_SID_ID;
		v_type						csr.portlet.type%TYPE;
	BEGIN
		SELECT type
		  INTO v_type
		  FROM csr.portlet
		 WHERE portlet_id = in_portlet_id;
		
		BEGIN
			v_customer_portlet_sid := security.securableobject_pkg.GetSIDFromPath(
					SYS_CONTEXT('SECURITY','ACT'),
					SYS_CONTEXT('SECURITY','APP'),
					'Portlets/' || v_type);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
		
			BEGIN
				v_portlets_sid := security.securableobject_pkg.GetSIDFromPath(
						SYS_CONTEXT('SECURITY','ACT'),
						SYS_CONTEXT('SECURITY','APP'),
						'Portlets');

				security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'),
					v_portlets_sid,
					security.class_pkg.GetClassID('CSRPortlet'), v_type, v_customer_portlet_sid);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;
		END;

		IF v_customer_portlet_sid IS NOT NULL THEN
			BEGIN
				INSERT INTO csr.customer_portlet
					(portlet_id, customer_portlet_sid, app_sid)
				VALUES
					(in_portlet_id, v_customer_portlet_sid, SYS_CONTEXT('SECURITY', 'APP'));
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN NULL;
			END;
		END IF;
	END;

BEGIN
	security.user_pkg.LogonAdmin;
	FOR s IN (
		SELECT app_sid, host
		  FROM csr.customer c, security.website w
		 WHERE c.host = w.website_name
	) LOOP
		security.user_pkg.LogonAdmin(s.host);
		FOR p IN (
			SELECT portlet_id
			  FROM csr.portlet
			 WHERE type IN (
				'Credit360.Portlets.PeriodPicker2'
			) AND portlet_Id NOT IN (SELECT portlet_id FROM csr.customer_portlet)
		) LOOP
			EnablePortletForCustomer(p.portlet_id);
		END LOOP;
		security.user_pkg.LogonAdmin;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
