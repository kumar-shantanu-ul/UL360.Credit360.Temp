-- Please update version.sql too -- this keeps clean builds in sync
define version=1503
@update_header


CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_FLOW_FILTER
(
    ID                      NUMBER(10) NOT NULL,
    IS_EDITABLE             NUMBER(1) NOT NULL
) ON COMMIT DELETE ROWS;

-- all this is in ER/Studio
ALTER TABLE CSR.PROPERTY_TYPE_SPACE_TYPE ADD CONSTRAINT PK_PROP_TYPE_SPACE_TYPE PRIMARY KEY  (APP_SID,PROPERTY_TYPE_ID, SPACE_TYPE_ID);

ALTER TABLE CSR.REGION_TYPE_TAG_GROUP DROP CONSTRAINT FK_REG_TYP_TG_REG_TYP;

ALTER TABLE CSR.REGION_TYPE_TAG_GROUP ADD CONSTRAINT FK_REG_TYP_TG_REG_TYP
    FOREIGN KEY (APP_SID,REGION_TYPE)
    REFERENCES CSR.CUSTOMER_REGION_TYPE(APP_SID, REGION_TYPE);
    
DROP TABLE CSR.SPACE_TYPE_IND PURGE;

ALTER TABLE CSR.ALL_METER ADD (
    METER_IND_ID    NUMBER(10),
    CONSTRAINT FK_METER_METER_IND FOREIGN KEY (APP_SID,METER_IND_ID)
    REFERENCES CSR.METER_IND(APP_SID, METER_IND_ID)
);

ALTER TABLE CSR.CUSTOMER ADD (
    PROPERTY_FLOW_SID   NUMBER(10),
    CONSTRAINT FK_CUST_FLOW FOREIGN KEY (APP_SID, PROPERTY_FLOW_SID)
    REFERENCES CSR.FLOW(APP_SID, FLOW_SID)
);

-- this comes from region_metric_region so not required
ALTER TABLE CSR.REGION_METRIC_VAL DROP CONSTRAINT FK_RMETRIC_RMETRIC_VAL;

CREATE TABLE CSR.SPACE_TYPE_REGION_METRIC(
    APP_SID          NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SPACE_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    IND_SID          NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SPACE_TYPE_REGION_METRIC PRIMARY KEY (APP_SID, SPACE_TYPE_ID, IND_SID)
);

ALTER TABLE CSR.SPACE_TYPE_REGION_METRIC ADD CONSTRAINT FK_REG_METRIC_SPACE_TYPE 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.REGION_METRIC(APP_SID, IND_SID);

ALTER TABLE CSR.SPACE_TYPE_REGION_METRIC ADD CONSTRAINT FK_SPACE_TYPE_SPT_REG_MET 
    FOREIGN KEY (APP_SID, SPACE_TYPE_ID)
    REFERENCES CSR.SPACE_TYPE(APP_SID, SPACE_TYPE_ID);


-- added lookup_key
CREATE OR REPLACE VIEW csr.V$FLOW_ITEM AS
    SELECT fi.app_sid, fi.flow_sid, fi.flow_item_Id, fs.flow_state_id current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key,
        fi.survey_response_id, fi.dashboard_instance_id  -- deprecated
      FROM flow_item fi           
        JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid 
    ;   

-- needs recompiling because we altered v$flow_item and it includes .*
CREATE OR REPLACE VIEW csr.V$FLOW_ITEM_ROLE_MEMBER AS
    SELECT fi.*, r.role_sid, r.name role_name, rrm.region_sid, fsr.is_editable
      FROM V$FLOW_ITEM fi
        JOIN flow_state_role fsr ON fi.current_state_id = fsr.flow_state_id AND fi.app_sid = fsr.app_sid
        JOIN role r ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
        JOIN region_role_member rrm ON r.role_sid = rrm.role_sid AND r.app_sid = rrm.app_sid AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
    ;
 
CREATE OR REPLACE VIEW csr.v$property AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name, pt.property_type_id, pt.label property_type_label,
        p.flow_item_id, fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key, fs.state_colour current_state_colour,
        r.active, r.acquisition_dtm, r.disposal_dtm, geo_longitude lng, geo_latitude lat
      FROM property p
        JOIN v$region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
        LEFT JOIN postcode.country c ON r.geo_country = c.country 
        LEFT JOIN property_type pt ON p.property_type_id = pt.property_type_id AND p.app_sid = pt.app_sid
        LEFT JOIN flow_item fi ON p.flow_item_id = fi.flow_item_id AND p.app_sid = fi.app_sid
        LEFT JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid;

CREATE OR REPLACE VIEW csr.v$property_meter AS
	SELECT a.app_sid, a.region_sid, a.reference, r.description, r.parent_sid, a.note,
			NVL(mi.label, i.description) group_label, mi.group_key,
			a.primary_ind_sid, i.description primary_description, NVL(mc.description, m.description) primary_measure, a.primary_measure_conversion_id,
			ms.meter_source_type_id, ms.name source_type_name, ms.description source_type_description,
			ms.manual_data_entry, ms.supplier_data_mandatory, ms.arbitrary_period, ms.reference_mandatory, ms.add_invoice_data,
			ms.realtime_metering, ms.show_in_meter_list
		  FROM all_meter a
			JOIN meter_source_type ms ON a.meter_source_type_id = ms.meter_source_type_id AND a.app_sid = ms.app_sid			
			JOIN v$region r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
			JOIN v$ind i ON a.primary_ind_sid = i.ind_sid AND a.app_sid = i.app_sid
			JOIN measure m ON i.measure_sid = m.measure_sid AND i.app_sid = m.app_sid
			LEFT JOIN meter_ind mi ON a.meter_ind_id = mi.meter_ind_id
			LEFT JOIN measure_conversion mc ON a.primary_measure_conversion_id = mc.measure_conversion_id AND a.app_sid = mc.app_sid;
            

-- bare-bones view  (can include dupes if you're in multiple matching roles) 
CREATE OR REPLACE VIEW csr.v$my_property AS
    SELECT p.app_sid, p.region_sid, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, 
            p.property_type_id, p.flow_item_id, 
            fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key,  
            fs.state_colour current_state_colour,
            r.role_sid, r.name role_name, fsr.is_editable
      FROM region_role_member rrm
        JOIN role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
        JOIN flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
        JOIN flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid 
        JOIN flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
        JOIN property p ON fi.flow_item_id = p.flow_Item_id AND rrm.region_sid = p.region_sid AND rrm.app_sid = p.app_sid
     WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID');
    
-- fuller-fat view (can include dupes if you're in multiple matching roles) 
CREATE OR REPLACE VIEW csr.v$my_property_full AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name, pt.property_type_id, pt.label property_type_label,
        p.flow_item_id, p.current_state_id, p.current_state_label, p.current_state_lookup_key,
        p.current_state_colour, p.role_sid, p.role_name, p.is_editable,
        r.active, r.acquisition_dtm, r.disposal_dtm, geo_longitude lng, geo_latitude lat
      FROM csr.v$my_property p
        JOIN v$region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
        LEFT JOIN postcode.country c ON r.geo_country = c.country 
        LEFT JOIN property_type pt ON p.property_type_id = pt.property_type_id AND p.app_sid = pt.app_sid;


@..\property_pkg
@..\space_pkg
@..\region_metric_pkg

@..\property_body
@..\space_body
@..\region_metric_body

@update_tail