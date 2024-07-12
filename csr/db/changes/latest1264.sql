-- Please update version.sql too -- this keeps clean builds in sync
define version=1264
@update_header

ALTER TABLE CSR.ALL_METER ADD (
	IS_CORE			NUMBER(1,0) DEFAULT 0 NOT NULL,
	CONSTRAINT CK_ALL_METER_IS_CORE CHECK (IS_CORE IN(0,1))
);

CREATE OR REPLACE VIEW CSR.METER
	(APP_SID,REGION_SID, NOTE, PRIMARY_IND_SID, PRIMARY_MEASURE_CONVERSION_ID, METER_SOURCE_TYPE_ID, REFERENCE, CRC_METER, COST_IND_SID, COST_MEASURE_CONVERSION_ID, DAYS_IND_SID, DAYS_MEASURE_CONVERSION_ID, COSTDAYS_IND_SID, COSTDAYS_MEASURE_CONVERSION_ID, APPROVED_BY_SID, APPROVED_DTM, IS_CORE) AS
  SELECT APP_SID,REGION_SID, NOTE, PRIMARY_IND_SID, PRIMARY_MEASURE_CONVERSION_ID, METER_SOURCE_TYPE_ID, REFERENCE, CRC_METER,
	COST_IND_SID, COST_MEASURE_CONVERSION_ID, DAYS_IND_SID, DAYS_MEASURE_CONVERSION_ID, COSTDAYS_IND_SID, COSTDAYS_MEASURE_CONVERSION_ID,
	APPROVED_BY_SID, APPROVED_DTM, IS_CORE
    FROM ALL_METER
   WHERE ACTIVE = 1;

DECLARE
  v_attribute_id  security.security_pkg.T_ATTRIBUTE_ID;
BEGIN
	security.user_pkg.logonadmin(NULL);
	
	security.attribute_pkg.CreateDefinition(
		security.security_pkg.GetACT, security.class_pkg.GetClassId('CSRData'), 
		'crc-metering-auto-core', 0, NULL, v_attribute_id);
		
	security.attribute_pkg.CreateDefinition(
		security.security_pkg.GetACT, security.class_pkg.GetClassId('CSRData'), 
		'crc-metering-ind-core', 0, NULL, v_attribute_id);
EXCEPTION
  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
    NULL;
END;
/


@../meter_pkg
@../meter_body
@../energy_star_body
@../utility_report_body
@../indicator_body


DECLARE
	v_csr_sid					security.security_pkg.T_SID_ID;
BEGIN
	FOR c IN (
		SELECT app_sid, host
		  FROM csr.customer
		 WHERE host = 'cbre.credit360.com'
	) LOOP
		security.user_pkg.logonadmin(c.host);
		v_csr_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'csr');
		security.securableobject_pkg.SetNamedNumberAttribute(security.security_pkg.GetACT, v_csr_sid, 'crc-metering-ind-core', 0);
		security.securableobject_pkg.SetNamedNumberAttribute(security.security_pkg.GetACT, v_csr_sid, 'crc-metering-auto-core', 1);
		security.user_pkg.logonadmin(NULL);
	END LOOP;
END;
/

DECLARE
	v_csr_sid					security.security_pkg.T_SID_ID;
	v_crc_enabled				security.security_pkg.T_SO_ATTRIBUTE_NUMBER;
	v_ind_core_enabled			security.security_pkg.T_SO_ATTRIBUTE_NUMBER;
BEGIN
	FOR c IN (
		SELECT app_sid, host
		  FROM csr.customer c, security.website w
		 WHERE c.host = w.website_name
	) LOOP
		security.user_pkg.logonadmin(c.host);
		
		v_csr_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'csr');
		v_crc_enabled := security.securableobject_pkg.GetNamedNumberAttribute(security.security_pkg.GetACT, v_csr_sid, 'crc-metering-enabled');
		v_ind_core_enabled := security.securableobject_pkg.GetNamedNumberAttribute(security.security_pkg.GetACT, v_csr_sid, 'crc-metering-ind-core');
		
		IF v_crc_enabled IS NOT NULL AND v_crc_enabled != 0 AND 
	   	   (v_ind_core_enabled IS NULL OR v_ind_core_enabled != 0) THEN
	   		FOR r IN (
	   			SELECT DISTINCT i.ind_sid, i.core
	   			  FROM csr.ind i, csr.all_meter m
	   			 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   			   AND m.app_sid = i.app_sid
	   			   AND m.primary_ind_sid = i.ind_sid
	   		) LOOP
	   			UPDATE csr.all_meter
			   	   SET is_core = r.core
			   	 WHERE primary_ind_sid = r.ind_sid
			   	   AND is_core <> r.core;
	   		END LOOP;   	
		END IF;
		
		security.user_pkg.logonadmin(NULL);
	END LOOP;
END;
/

@update_tail
