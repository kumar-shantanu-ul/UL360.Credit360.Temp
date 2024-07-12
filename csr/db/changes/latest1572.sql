-- Please update version.sql too -- this keeps clean builds in sync
define version=1572
@update_header

/* property */
CREATE OR REPLACE VIEW csr.v$property AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name,
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


-- bare-bones view  (can include dupes if you're in multiple matching roles) 
CREATE OR REPLACE VIEW csr.v$my_property AS
    SELECT p.app_sid, p.region_sid, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, 
            p.property_type_id, p.flow_item_id, 
            fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key,  
            fs.state_colour current_state_colour,
            r.role_sid, r.name role_name, fsr.is_editable, rg.active, p.pm_building_id
      FROM region_role_member rrm
        JOIN role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
        JOIN flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
        JOIN flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid 
        JOIN flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
        JOIN property p ON fi.flow_item_id = p.flow_Item_id AND rrm.region_sid = p.region_sid AND rrm.app_sid = p.app_sid
        JOIN region rg ON p.region_sid = rg.region_sid AND p.app_Sid = rg.app_sid
     WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID');

-- fuller-fat view (can include dupes if you're in multiple matching roles) 
CREATE OR REPLACE VIEW csr.v$my_property_full AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name, pt.property_type_id, pt.label property_type_label,
        p.flow_item_id, p.current_state_id, p.current_state_label, p.current_state_lookup_key,
        p.current_state_colour, p.role_sid, p.role_name, p.is_editable,
        r.active, r.acquisition_dtm, r.disposal_dtm, geo_longitude lng, geo_latitude lat, p.pm_building_id
      FROM csr.v$my_property p
        JOIN v$region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
        LEFT JOIN postcode.country c ON r.geo_country = c.country 
        LEFT JOIN property_type pt ON p.property_type_id = pt.property_type_id AND p.app_sid = pt.app_sid;

@..\role_pkg
@..\property_pkg

@..\role_body
@..\property_body

@update_tail
