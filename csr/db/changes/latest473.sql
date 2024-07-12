-- Please update version.sql too -- this keeps clean builds in sync
define version=473
@update_header

CREATE TABLE CUSTOMER_REGION_TYPE(
    APP_SID        NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    REGION_TYPE    NUMBER(2, 0)     NOT NULL,
    CONSTRAINT PK785 PRIMARY KEY (APP_SID, REGION_TYPE)
)
;

CREATE TABLE REGION_TYPE(
    REGION_TYPE    NUMBER(2, 0)     NOT NULL,
    LABEL          VARCHAR2(256)    NOT NULL,
    CONSTRAINT PK784 PRIMARY KEY (REGION_TYPE)
)
;

ALTER TABLE CUSTOMER_REGION_TYPE ADD CONSTRAINT RefREGION_TYPE1711 
    FOREIGN KEY (REGION_TYPE)
    REFERENCES REGION_TYPE(REGION_TYPE)
;

ALTER TABLE CUSTOMER_REGION_TYPE ADD CONSTRAINT RefCUSTOMER1712 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

DECLARE
	v_count NUMBER;
BEGIN
	-- Insert region types
	INSERT INTO region_type (region_type, label) VALUES(0, 'Normal');
	INSERT INTO region_type (region_type, label) VALUES(1, 'Meter');
	INSERT INTO region_type (region_type, label) VALUES(2, 'Root');
	INSERT INTO region_type (region_type, label) VALUES(3, 'Property');
	INSERT INTO region_type (region_type, label) VALUES(4, 'Tennant');
	INSERT INTO region_type (region_type, label) VALUES(5, 'Rate');
	INSERT INTO region_type (region_type, label) VALUES(6, 'Managing agent');	
	
	FOR r IN (
		SELECT app_sid, host FROM csr.customer WHERE host NOT IN ('survey.credit360.com','vancitytest.credit360.com','junkhsbc.credit360.com')
	) LOOP
		user_pkg.logonadmin(r.host);
		
		-- Insert generc type associations
		INSERT INTO customer_region_type (app_sid, region_type) VALUES (r.app_sid, 0);
		INSERT INTO customer_region_type (app_sid, region_type) VALUES (r.app_sid, 2);
		INSERT INTO customer_region_type (app_sid, region_type) VALUES (r.app_sid, 3);
		INSERT INTO customer_region_type (app_sid, region_type) VALUES (r.app_sid, 4);
		
		-- Insert metering only associations
		BEGIN
			SELECT COUNT(*)
			  INTO v_count
			  FROM security.attributes a, security.securable_object_attributes soa
			 WHERE soa.sid_id = securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, security_pkg.GetAPP, 'CSR')
			   AND soa.attribute_id = a.attribute_id
			   AND LOWER(a.name) = 'modules-metering';
			IF v_count > 0 THEN
				INSERT INTO customer_region_type (app_sid, region_type) VALUES (r.app_sid, 1); -- meter
				INSERT INTO customer_region_type (app_sid, region_type) VALUES (r.app_sid, 5); -- rate
			ELSE
				-- Check for existing region types even if metering is now disabled
				SELECT COUNT(*)
				  INTO v_count
				  FROM region
				 WHERE region_type IN (1, 5);
				-- It is possible that metering was once enabled
				IF v_count > 0 THEN
					INSERT INTO customer_region_type (app_sid, region_type) VALUES (r.app_sid, 1); -- meter
					INSERT INTO customer_region_type (app_sid, region_type) VALUES (r.app_sid, 5); -- rate
				END IF;
			END IF;
		EXCEPTION
        	-- Not 'CSR' not found, nothing to do
        	WHEN Security_Pkg.OBJECT_NOT_FOUND THEN
        		NULL;
        END;
		
		user_pkg.logonadmin(NULL);
	END LOOP;
	
	-- Insert managing agent type for BL
	INSERT INTO customer_region_type (app_sid, region_type) (
		SELECT app_sid, 6 -- Managing agent
		  FROM customer
		 WHERE host IN (
		 	'britishland.credit360.com',
		 	'test-britishland.credit360.com'
		 )
	);
	
	-- Mop-up any violations (look linke they're in defunked sites)
	INSERT INTO customer_region_type (app_sid, region_type) (
		SELECT DISTINCT app_sid, region_type
		  FROM region
		MINUS
		SELECT app_sid, region_type
		  FROM customer_region_type  
	);
	
	COMMIT;
END;
/

-- Finally, add region -> customer_region_type constraint
ALTER TABLE REGION ADD CONSTRAINT RefCUSTOMER_REGION_TYPE1713 
    FOREIGN KEY (APP_SID, REGION_TYPE)
    REFERENCES CUSTOMER_REGION_TYPE(APP_SID, REGION_TYPE)
;

-- Update row level security
@../rls

@update_tail
