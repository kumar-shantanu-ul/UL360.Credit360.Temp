-- Please update version.sql too -- this keeps clean builds in sync
define version=1694
@update_header

-- one I sneaked in after sending the stuff above to James Boss
ALTER TABLE CSR.SPACE_TYPE ADD (
    IS_TENANTABLE    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_SPACE_TYPE_IS_TENANT CHECK (IS_TENANTABLE IN (0,1))
);
 

-- deprecated with the new code
drop table csr.root_section_user;
drop table csr.section_approvers;
drop table csrimp.root_section_user;
drop table csrimp.section_approvers;

-- fiddle around with the meter tables
ALTER TABLE CSR.METER_IND MODIFY COST_IND_SID NULL;

ALTER TABLE CSR.ALL_METER ADD (
    DEMAND_IND_SID                    NUMBER(10, 0),
    DEMAND_MEASURE_CONVERSION_ID      NUMBER(10, 0)
);

 
ALTER TABLE CSR.METER_IND ADD (
    DAYS_IND_SID           NUMBER(10, 0),
    COSTDAYS_IND_SID       NUMBER(10, 0),
    DEMAND_IND_SID         NUMBER(10, 0)
);
 
ALTER TABLE CSR.METER_LIST_CACHE ADD (
    DEMAND_NUMBER           NUMBER(24, 10)
);

ALTER TABLE CSR.METER_READING ADD (
    DEMAND                  NUMBER(24, 10)
);
 

ALTER TABLE CSR.ALL_METER ADD CONSTRAINT FK_IND_METER_DMND 
    FOREIGN KEY (APP_SID, DEMAND_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID);
 
ALTER TABLE CSR.ALL_METER ADD CONSTRAINT FK_MEAS_CONV_METER_DMND 
    FOREIGN KEY (APP_SID, DEMAND_MEASURE_CONVERSION_ID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID);

ALTER TABLE CSR.METER_IND ADD CONSTRAINT FK_IND_METER_IND_DMND 
    FOREIGN KEY (APP_SID, DEMAND_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID);

ALTER TABLE CSR.METER_IND ADD CONSTRAINT FK_IND_METER_IND_CONSUMPT 
    FOREIGN KEY (APP_SID, CONSUMPTION_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID);

ALTER TABLE CSR.METER_IND ADD CONSTRAINT FK_IND_METER_IND_COST 
    FOREIGN KEY (APP_SID, COST_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID);

ALTER TABLE CSR.METER_IND ADD CONSTRAINT FK_IND_METER_IND_COSTDAYS 
    FOREIGN KEY (APP_SID, COSTDAYS_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID);

ALTER TABLE CSR.METER_IND ADD CONSTRAINT FK_IND_METER_IND_DAYS 
    FOREIGN KEY (APP_SID, DAYS_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID);



CREATE OR REPLACE VIEW csr.v$property_meter AS
  SELECT a.app_sid, a.region_sid, a.reference, r.description, r.parent_sid, a.note,
    NVL(mi.label, pi.description) group_label, mi.group_key,
    a.primary_ind_sid, pi.description primary_description, NVL(pmc.description, pm.description) primary_measure, a.primary_measure_conversion_id,
    a.cost_ind_sid, ci.description cost_description, NVL(cmc.description, cm.description) cost_measure, a.cost_measure_conversion_id,   
    ms.meter_source_type_id, ms.name source_type_name, ms.description source_type_description,
    ms.manual_data_entry, ms.supplier_data_mandatory, ms.arbitrary_period, ms.reference_mandatory, ms.add_invoice_data,
    ms.realtime_metering, ms.show_in_meter_list, a.meter_ind_id
    FROM all_meter a
    JOIN meter_source_type ms ON a.meter_source_type_id = ms.meter_source_type_id AND a.app_sid = ms.app_sid      
    JOIN v$region r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
    LEFT JOIN meter_ind mi ON a.meter_ind_id = mi.meter_ind_id
    LEFT JOIN v$ind pi ON a.primary_ind_sid = pi.ind_sid AND a.app_sid = pi.app_sid
    LEFT JOIN measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
    LEFT JOIN measure_conversion pmc ON a.primary_measure_conversion_id = pmc.measure_conversion_id AND a.app_sid = pmc.app_sid
    LEFT JOIN v$ind ci ON a.cost_ind_sid = ci.ind_sid AND a.app_sid = ci.app_sid
    LEFT JOIN measure cm ON ci.measure_sid = cm.measure_sid AND ci.app_sid = cm.app_sid
    LEFT JOIN measure_conversion cmc ON a.cost_measure_conversion_id = cmc.measure_conversion_id AND a.app_sid = cmc.app_sid;
    
CREATE OR REPLACE VIEW csr.v$property AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name, c.currency country_currency,
        pt.property_type_id, pt.label property_type_label,
        pst.property_sub_type_id, pst.label property_sub_type_label,
        p.flow_item_id, fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key, fs.state_colour current_state_colour,
        r.active, r.acquisition_dtm, r.disposal_dtm, geo_longitude lng, geo_latitude lat, fund_id,
        mgmt_company_id, mgmt_company_other, p.company_sid, p.pm_building_id
      FROM property p
        JOIN v$region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
        LEFT JOIN postcode.country c ON r.geo_country = c.country 
        LEFT JOIN property_type pt ON p.property_type_id = pt.property_type_id AND p.app_sid = pt.app_sid
        LEFT JOIN property_sub_type pst ON p.property_sub_type_id = pst.property_sub_type_id AND p.app_sid = pst.app_sid
        LEFT JOIN flow_item fi ON p.flow_item_id = fi.flow_item_id AND p.app_sid = fi.app_sid
        LEFT JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid;



CREATE OR REPLACE VIEW csr.METER AS
  SELECT APP_SID,REGION_SID, NOTE, PRIMARY_IND_SID, PRIMARY_MEASURE_CONVERSION_ID, METER_SOURCE_TYPE_ID, REFERENCE, CRC_METER,
  COST_IND_SID, COST_MEASURE_CONVERSION_ID, DAYS_IND_SID, DAYS_MEASURE_CONVERSION_ID, COSTDAYS_IND_SID, COSTDAYS_MEASURE_CONVERSION_ID,
  APPROVED_BY_SID, APPROVED_DTM, IS_CORE
    FROM ALL_METER
   WHERE ACTIVE = 1;
   


@..\csr_data_pkg
@..\section_pkg
@..\schema_pkg
@..\space_pkg
@..\property_pkg

@..\measure_body
@..\section_body
@..\schema_body
@..\csr_user_body
@..\csr_data_body
@..\csrimp\imp_body
@..\space_body
@..\property_body

@update_tail