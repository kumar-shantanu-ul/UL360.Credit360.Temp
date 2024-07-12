--Please update version.sql too -- this keeps clean builds in sync
define version=2632
@update_header

--There was one instance with multiple properties sharing the same flow_item.
--clients\mcd-de\db\utils\fix-flow-properties.sql fixed this issue

DECLARE
	v_act_id			 	security.security_pkg.T_ACT_ID;
	v_workflows_sid		 	security.security_Pkg.T_SID_ID;
	v_property_workflow_sid	security.security_Pkg.T_SID_ID;
	v_flow_item_id			security.security_Pkg.T_SID_ID;
	
BEGIN
	security.user_pkg.logonadmin;

	v_act_id			 	:= security.security_pkg.GetAct;			
		
	FOR s IN (
		SELECT app_sid, flow_item_id
		  FROM csr.all_property
		 GROUP BY app_sid, flow_item_id
		HAVING COUNT(*) > 1) LOOP

		security.security_pkg.SetApp(s.app_sid);
		
		v_workflows_sid		 	:= security.securableobject_pkg.getsidfrompath(v_act_id, security.security_pkg.getApp,  'Workflows');
		v_property_workflow_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_workflows_sid, 'Property Workflow');

		FOR r IN (
			SELECT region_sid
			  FROM csr.property 
			 WHERE app_sid = security.security_pkg.getApp
			   AND flow_item_id = s.flow_item_id
		   )
		LOOP
			dbms_output.put_line('Updating property with region: ' || r.region_sid);
			csr.flow_pkg.addFlowItem( v_property_workflow_sid, v_flow_item_id);
			
			UPDATE csr.property 
			   SET flow_item_id = v_flow_item_id
			 WHERE app_sid = security.security_pkg.getapp
			   AND region_sid = r.region_sid;
	    
		END LOOP;
	END LOOP;
END;
/


ALTER TABLE CSR.ALL_PROPERTY ADD CONSTRAINT UC_PROPERTY_FLOW_ITEM UNIQUE (FLOW_ITEM_ID);
ALTER TABLE CSR.INTERNAL_AUDIT ADD CONSTRAINT UC_IA_FLOW_ITEM UNIQUE (FLOW_ITEM_ID);
	
@update_tail