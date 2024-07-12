-- Please update version.sql too -- this keeps clean builds in sync
define version=2263
@update_header

CREATE OR REPLACE VIEW csr.v$space AS
    SELECT s.region_sid, r.description, r.active, r.parent_sid, s.space_type_id, st.label space_type_label, s.current_lease_id, s.property_region_Sid,
		   l.tenant_name current_tenant_name
      FROM space s
        JOIN v$region r on s.region_sid = r.region_sid
        JOIN space_type st ON s.space_type_Id = st.space_type_id
		LEFT JOIN v$lease l ON l.lease_id = s.current_lease_id;


@..\property_body

@update_tail
