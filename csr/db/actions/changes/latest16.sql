-- Please update version.sql too -- this keeps clean builds in sync
define version=16
@update_header

PROMPT Enter connection (e.g. ASPEN)
connect csr/csr@&&1

-- Add an actions folder to each customer's indicator tree
-- Add an action progress measure for each customer
DECLARE
	v_act 					security_pkg.T_ACT_ID;
	v_ind_sid 				security_pkg.T_SID_ID;
	v_measure_root_sid 		security_pkg.T_SID_ID;
	v_measure_sid 			security_pkg.T_SID_ID;
BEGIN
	-- just for customers who use actions
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',3600,v_act);
	FOR r IN (
		SELECT DISTINCT c.app_sid, ind_root_sid
		  FROM customer c, actions.project p 
		 WHERE c.app_sid = p.app_sid
	)
	LOOP
		BEGIN
			-- Create 'Actions' indicator folder (inactive)
			indicator_pkg.CreateIndicator(
				v_act, r.ind_root_sid, r.app_sid, 'Actions', 'Actions', 0,
				NULL, 1, NULL, NULL, 1, NULL, NULL, NULL,
				1, 1, 0, 'SUM', NULL, v_ind_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN NULL;
		END;
		BEGIN
			-- Create 'action_progress' measure
			v_measure_root_sid := security.securableobject_pkg.GetSIDFromPath(v_act, r.app_sid, 'Measures');
			measure_pkg.CreateMeasure(
				v_act, v_measure_root_sid, r.app_sid, 'action_progress', 
				'Action Progress', 1, '0.00', NULL, v_measure_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN NULL;
		END;			
	END LOOP;
END;
/

COMMIT;

connect actions/actions@&&1
@update_tail