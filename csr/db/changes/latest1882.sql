-- Please update version.sql too -- this keeps clean builds in sync
define version=1882
@update_header

CREATE OR REPLACE VIEW csr.v$my_initiatives AS
SELECT	i.app_sid, i.initiative_sid,
		ir.region_sid,
		fi.current_state_id flow_state_id,
		fs.label flow_state_label,
		fs.lookup_key flow_state_lookup_key,
		fs.state_colour flow_state_colour,
		r.role_sid,
		r.name role_name,
		fsr.is_editable,
		rg.active,
		null owner_sid
  FROM	region_role_member rrm
  JOIN	role r
		 ON rrm.role_sid = r.role_sid
		AND rrm.app_sid = r.app_sid
  JOIN flow_state_role fsr
		 ON fsr.role_sid = r.role_sid
		AND fsr.app_sid = r.app_sid
  JOIN flow_state fs
		 ON fsr.flow_state_id = fs.flow_state_id
		AND fsr.app_sid      = fs.app_sid
  JOIN flow_item fi
		 ON fs.flow_state_id = fi.current_state_id
		AND fs.app_sid      = fi.app_sid
  JOIN initiative i
		 ON fi.flow_item_id = i.flow_Item_id
  JOIN initiative_region ir
		 ON i.initiative_sid = ir.initiative_sid
		AND rrm.region_sid = ir.region_sid
		AND rrm.app_sid    = ir.app_sid
  JOIN region rg
		 ON ir.region_sid    = rg.region_sid
		AND ir.app_Sid      = rg.app_sid
 WHERE	rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
   AND	i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
UNION ALL
SELECT	i.app_sid, i.initiative_sid, 
		ir.region_sid,
		fi.current_state_id flow_state_id,
		fs.label flow_state_label,
		fs.lookup_key flow_state_lookup_key,
		fs.state_colour flow_state_colour,
		null role_sid,
		null role_name,
		iu.is_editable,
		rg.active,
		iu.user_sid owner_sid
  FROM	initiative_user iu
  JOIN	initiative i
		 ON iu.initiative_sid = i.initiative_sid
		AND iu.app_sid = i.app_sid
  JOIN	flow_item fi
		 ON i.flow_item_id = fi.flow_item_id
		AND i.app_sid = fi.app_sid
		AND iu.flow_state_id = fi.current_state_id
  JOIN flow_state fs
		 ON fi.current_state_id = fs.flow_state_id
		AND fi.flow_sid = fs.flow_sid
		AND fi.app_sid = fs.app_sid
  JOIN initiative_region ir
		 ON ir.initiative_sid = i.initiative_sid
		AND ir.app_sid = i.app_sid
  JOIN region rg
		 ON ir.region_sid = rg.region_sid
		AND ir.app_Sid = rg.app_sid
 WHERE	iu.user_sid = SYS_CONTEXT('SECURITY','SID')
   AND	i.app_sid = SYS_CONTEXT('SECURITY', 'APP');


@../initiative_metric_pkg
@../initiative_pkg
@../initiative_doc_pkg
@../initiative_project_pkg
@../initiative_import_pkg
@../initiative_aggr_pkg

@../initiative_metric_body
@../initiative_body
@../initiative_doc_body
@../initiative_project_body
@../initiative_import_body
@../initiative_aggr_body

@update_tail
