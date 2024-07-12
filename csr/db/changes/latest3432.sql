define version=3432
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;

CREATE SEQUENCE CSR.REGION_ENERGY_RATING_ID_SEQ;


ALTER TABLE csr.est_account_global RENAME column password TO password_old;
DECLARE
	v_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	 INTO v_count
	 FROM all_constraints
	WHERE constraint_name = 'FK_EST_CUST_GLOBAL'
	AND owner='CSR';
	IF v_count != 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.est_customer DROP CONSTRAINT FK_EST_CUST_GLOBAL DROP INDEX';
	END IF;
END;
/
ALTER TABLE csr.region_energy_rating DROP CONSTRAINT PK_REGION_ENERGY_RAT DROP INDEX;
ALTER TABLE csr.region_energy_rating ADD (
	REGION_ENERGY_RATING_ID			NUMBER(10, 0) NULL,
	NOTE							VARCHAR2(2048) NULL,
	SUBMIT_TO_GRESB					NUMBER(1) DEFAULT 0 NOT NULL
);
UPDATE csr.region_energy_rating SET region_energy_rating_id = CSR.REGION_ENERGY_RATING_ID_SEQ.NEXTVAL;
ALTER TABLE csr.region_energy_rating MODIFY	REGION_ENERGY_RATING_ID	NUMBER(10, 0) NOT NULL;
ALTER TABLE csr.region_energy_rating ADD CONSTRAINT PK_REGION_ENERGY_RAT PRIMARY KEY (app_sid, region_energy_rating_id);
ALTER TABLE csrimp.region_energy_rating ADD (
	REGION_ENERGY_RATING_ID			NUMBER(10, 0) NULL,
	NOTE							VARCHAR2(2048) NULL,
	SUBMIT_TO_GRESB					NUMBER(1) DEFAULT 0 NOT NULL
);
CREATE INDEX CSR.IX_REGION_ENERGY_REGION_SID ON CSR.REGION_ENERGY_RATING (APP_SID, REGION_SID);


grant execute on csr.energy_star_customer_pkg to security;
grant execute on csr.energy_star_customer_pkg to web_user;




CREATE OR REPLACE VIEW csr.v$est_account AS
	SELECT a.app_sid, a.est_account_sid, a.est_account_id, a.account_customer_id,
		g.user_name, g.base_url,
		g.connect_job_interval, g.last_connect_job_dtm,
		a.share_job_interval, a.last_share_job_dtm,
		a.building_job_interval, a.meter_job_interval,
		a.auto_map_customer, a.allow_delete
	 FROM csr.est_account a
	 JOIN csr.est_account_global g ON a.est_account_id = g.est_account_id
;




UPDATE csr.gresb_property_sub_type
   SET pos = pos + 1
 WHERE gresb_property_type_id = 3 
   AND gresb_property_sub_type_id >= 1;
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 5, 'Refrigerated Warehouse', 'IRFW', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 6, 'Non-Refrigerated Warehouse', 'INRW', 0);
UPDATE csr.property_sub_type
   SET gresb_property_sub_type_id = 6
 WHERE gresb_property_type_id = 3 
   AND gresb_property_sub_type_id = 1;
DELETE FROM csr.gresb_property_sub_type
 WHERE gresb_property_type_id = 3
   AND gresb_property_sub_type_id = 1;






@..\energy_star_pkg
@..\meter_monitor_pkg
@..\region_certificate_pkg


@..\enable_body
@..\energy_star_body
@..\meter_monitor_body
@..\audit_body
@..\region_certificate_body
@..\schema_body
@..\period_body
@..\csr_app_body



@update_tail
