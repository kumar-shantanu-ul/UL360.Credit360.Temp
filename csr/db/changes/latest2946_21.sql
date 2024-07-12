-- Please update version.sql too -- this keeps clean builds in sync
define version=2946
define minor_version=21
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSRIMP.GEO_MAP(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    GEO_MAP_SID             	    NUMBER(10, 0)    NOT NULL,
    LABEL                   	    VARCHAR2(255)    NOT NULL,
    REGION_SELECTION_TYPE_ID	    NUMBER(10, 0)    NOT NULL,
    INCLUDE_INACTIVE_REGIONS	    NUMBER(1, 0)     NOT NULL,
    START_DTM               	    DATE             NOT NULL,
    END_DTM                 	    DATE,
    INTERVAL                	    VARCHAR2(10)     NOT NULL,
	TAG_ID                          NUMBER(10),
    CONSTRAINT CHK_GEO_MAP_INCL_INACT CHECK (INCLUDE_INACTIVE_REGIONS IN (0,1)),
    CONSTRAINT CHK_GEO_MAP_INTERVAL CHECK (INTERVAL IN ('m','q','h','y')),
    CONSTRAINT PK_GEO_MAP PRIMARY KEY (CSRIMP_SESSION_ID, GEO_MAP_SID),
    CONSTRAINT FK_GEO_MAP
		FOREIGN KEY (CSRIMP_SESSION_ID) 
		REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) 
		ON DELETE CASCADE
);

CREATE TABLE CSRIMP.GEO_MAP_REGION(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    GEO_MAP_SID						NUMBER(10, 0)    NOT NULL,
    REGION_SID     					NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_GEO_MAP_REGION PRIMARY KEY (CSRIMP_SESSION_ID, GEO_MAP_SID, REGION_SID),
    CONSTRAINT FK_GEO_MAP_REGION 
		FOREIGN KEY (CSRIMP_SESSION_ID) 
		REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) 
		ON DELETE CASCADE
);

-- Alter tables

-- *** Grants ***
grant select, insert, update on csr.geo_map to csrimp;
grant select, insert, update on csr.geo_map_region to csrimp;
grant select, insert, update, delete on csrimp.geo_map to web_user;
grant select, insert, update, delete on csrimp.geo_map_region to web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
CREATE OR REPLACE PROCEDURE csr.temp_EnablePortletForCustomer(
	in_portlet_id	IN portlet.portlet_id%TYPE
)
AS
	v_customer_portlet_sid		security_pkg.T_SID_ID;
	v_type						portlet.type%TYPE;
BEGIN
	-- allow fiddling with portlets only for people with permissions on Capabilities/System management
	IF NOT csr_data_pkg.CheckCapability('System management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on the "System management" capability');
	END IF;
	
	SELECT type
	  INTO v_type
	  FROM portlet
	 WHERE portlet_id = in_portlet_id;
	
	BEGIN
		v_customer_portlet_sid := securableobject_pkg.GetSIDFromPath(
				SYS_CONTEXT('SECURITY','ACT'),
				SYS_CONTEXT('SECURITY','APP'),
				'Portlets/' || v_type);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'),
				securableobject_pkg.GetSIDFromPath(
					SYS_CONTEXT('SECURITY','ACT'),
					SYS_CONTEXT('SECURITY','APP'),
					'Portlets'),
				class_pkg.GetClassID('CSRPortlet'), v_type, v_customer_portlet_sid);
	END;

	BEGIN
		INSERT INTO customer_portlet
				(portlet_id, customer_portlet_sid, app_sid)
		VALUES
				(in_portlet_id, v_customer_portlet_sid, SYS_CONTEXT('SECURITY', 'APP'));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
				NULL;
	END;
END;
/

BEGIN
	FOR r IN (SELECT host FROM csr.customer WHERE property_flow_sid IS NOT NULL) 
	LOOP
		security.user_pkg.LogonAdmin(r.host);

		-- Enable standalone geo-maps portlet
		csr.temp_EnablePortletForCustomer(1048);
	END LOOP;
	security.user_pkg.LogonAdmin(NULL);
END;
/

DROP PROCEDURE csr.temp_EnablePortletForCustomer;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../property_pkg
@../property_report_pkg
@../schema_pkg

@../csrimp/imp_body
@../property_body
@../property_report_body
@../region_body
@../schema_body
@../../../postcode/db/geo_region_body

@update_tail
