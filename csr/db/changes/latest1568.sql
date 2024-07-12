-- Please update version.sql too -- this keeps clean builds in sync
define version=1568
@update_header

CREATE OR REPLACE VIEW csr.v$my_property AS
    SELECT p.app_sid, p.region_sid, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, 
            p.property_type_id, p.flow_item_id, 
            fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key,  
            fs.state_colour current_state_colour,
            r.role_sid, r.name role_name, fsr.is_editable, rg.active
      FROM region_role_member rrm
        JOIN role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
        JOIN flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
        JOIN flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid 
        JOIN flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
        JOIN property p ON fi.flow_item_id = p.flow_Item_id AND rrm.region_sid = p.region_sid AND rrm.app_sid = p.app_sid
        JOIN region rg ON p.region_sid = rg.region_sid AND p.app_Sid = rg.app_sid
     WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID');

@..\property_body   

@update_tail