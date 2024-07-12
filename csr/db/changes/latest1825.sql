-- Please update version.sql too -- this keeps clean builds in sync
define version=1825
@update_header

begin
	insert into cms.col_type values (32, 'Owner user');
end;
/

grant select on csr.flow_item_id_seq to cms;
grant select, insert on csr.flow_item to cms;


ALTER TABLE csr.flow ADD (
    OWNER_CAN_CREATE    NUMBER(1)   DEFAULT 0 NOT NULL
);

ALTER TABLE csr.flow_state_transition ADD (
    OWNER_CAN_SET   NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT CK_OWNER_CAN_SET CHECK (OWNER_CAN_SET IN (0,1))
);

CREATE OR REPLACE VIEW csr.v$property_meter AS
    SELECT a.app_sid, a.region_sid, a.reference, r.description, r.parent_sid, a.note,
        NVL(mi.label, pi.description) group_label, mi.group_key,
        a.primary_ind_sid, pi.description primary_description, NVL(pmc.description, pm.description) primary_measure, a.primary_measure_conversion_id,
        a.cost_ind_sid, ci.description cost_description, NVL(cmc.description, cm.description) cost_measure, a.cost_measure_conversion_id,       
        ms.meter_source_type_id, ms.name source_type_name, ms.description source_type_description,
        ms.manual_data_entry, ms.supplier_data_mandatory, ms.arbitrary_period, ms.reference_mandatory, ms.add_invoice_data,
        ms.realtime_metering, ms.show_in_meter_list, a.meter_ind_id, r.active
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


CREATE OR REPLACE VIEW csr.v$space AS
    SELECT s.region_sid, r.description, r.active, r.parent_sid, s.space_type_id, st.label space_type_label, s.current_lease_id, l.tenant_name current_tenant_name
      FROM space s
        JOIN v$region r on s.region_sid = r.region_sid
        JOIN space_type st ON s.space_type_Id = st.space_type_id
        LEFT JOIN v$lease l ON l.lease_id = s.current_lease_id;


grant select on csr.cms_alert_type to cms;
grant execute on csr.alert_pkg to cms;


@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_body

@..\property_pkg
@..\flow_pkg

@..\meter_body
@..\property_body
@..\flow_body

@update_tail
