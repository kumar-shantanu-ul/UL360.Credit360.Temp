define version=3239
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/


DECLARE
	v_exists	NUMBER := 0;
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND index_name = 'IX_INTAPI_COMPAN_GROUP_SID_ID';
	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE 'CREATE INDEX csr.ix_intapi_compan_group_sid_id ON csr.intapi_company_user_group (group_sid_id)';
	END IF;
END;
/






CREATE OR REPLACE VIEW csr.v$meter_reading_urjanet
AS
SELECT x.app_sid, x.region_sid, x.start_dtm, x.end_dtm, MAX(x.val_number) val_number, MAX(x.cost) cost,
	   LISTAGG(x.note, '; ') WITHIN GROUP (ORDER BY NULL) note
  FROM (
	-- Consumption + Cost (value part)
	SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm,
			CASE WHEN ip.LOOKUP_KEY='CONSUMPTION' THEN sd.consumption END val_number,
			CASE WHEN ip.LOOKUP_KEY='COST' THEN sd.consumption END cost, NULL note
	  FROM all_meter m
	  JOIN v$aggr_meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.region_sid
	  JOIN meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key IN ('CONSUMPTION', 'COST') AND sd.meter_input_id = ip.meter_input_id
	  JOIN meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
	-- Consumption + cost (distinct note part)
	UNION
	SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, NULL cost, sd.note
	  FROM all_meter m
	  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.region_sid
	  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key IN ('CONSUMPTION', 'COST') AND sd.meter_input_id = ip.meter_input_id
	  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
 ) x
 GROUP BY x.app_sid, x.region_sid, x.start_dtm, x.end_dtm
;




EXEC security.user_pkg.logonadmin('');
      
DECLARE
	v_compliance_language_id NUMBER;
BEGIN 
	FOR r IN (
		SELECT app_sid FROM csr.compliance_language WHERE lang_id=53 GROUP BY app_sid, lang_id HAVING COUNT(*) > 1
	)
	LOOP
		SELECT MIN(compliance_language_id)
		  INTO v_compliance_language_id
		  FROM csr.compliance_language 
		 WHERE app_sid = r.app_sid
		   AND lang_id = 53;
		DELETE FROM csr.compliance_language
		 WHERE app_sid = r.app_sid
		   AND lang_id = 53
		   AND compliance_language_id != v_compliance_language_id;  
	END LOOP;
END;
/ 
ALTER TABLE csr.compliance_language
ADD CONSTRAINT uk_compliance_language UNIQUE (app_sid, lang_id);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Compliance Languages', 0, 'Enable compliance languages feature.');
DELETE FROM csr.flow_item_gen_alert_archive
 WHERE (app_sid, flow_item_generated_alert_id) IN (
	 SELECT app_sid, flow_item_generated_alert_id
	   FROM csr.flow_item_generated_alert
 );






@..\compliance_pkg


@..\meter_body
@..\enable_body
@..\campaigns\campaign_body
@..\compliance_body
@..\audit_body
@..\supplier_body
@..\postit_body



@update_tail
