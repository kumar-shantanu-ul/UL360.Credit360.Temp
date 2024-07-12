DECLARE
	v_act_id								security_pkg.T_ACT_ID;
	v_status_class_id				security_pkg.T_SID_ID; 
	-- donation status SO
	v_statuses_sid					security_pkg.T_SID_ID;
	v_donation_status_sid 	security_pkg.T_SID_ID;
	v_donations_sid					security_pkg.T_SID_ID;
	v_transitions_sid				security_pkg.T_SID_ID;
	v_transistion_sid				security_pkg.T_SID_ID;
BEGIN
	-- log on
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act_id);	

	-- get class ids
	v_status_class_id:=class_pkg.GetClassId('DonationsStatus');

 	-- convert old donation_status to SO
	FOR c IN (SELECT DISTINCT app_sid FROM DONATION_STATUS ORDER BY APP_SID)
	LOOP 
		v_donations_sid := securableobject_pkg.GetSIDFromPath(v_act_id, c.app_sid, 'Donations');	
		
		-- get/create securable object Donations/Status
		BEGIN
			SecurableObject_Pkg.CreateSO(v_act_id, v_donations_sid, security_pkg.SO_CONTAINER, 'Statuses', v_statuses_sid);
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_statuses_sid := securableobject_pkg.GetSIDFromPath(v_act_id, c.app_sid, 'Donations/Statuses');
		END;
		
		-- get/create securable object Donations/Transitions
		BEGIN
			SecurableObject_Pkg.CreateSO(v_act_id, v_donations_sid, security_pkg.SO_CONTAINER, 'Transitions', v_transitions_sid);	
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_transitions_sid := securableobject_pkg.GetSIDFromPath(v_act_id, c.app_sid, 'Donations/Transitions');
		END;
		
		-- go through all statuses for current app_sid
		-- and convert current data to sids
		FOR r IN (SELECT * from DONATION_STATUS WHERE app_sid = c.app_sid)
		LOOP			
			-- create status/ ignore if already created
			BEGIN
				SecurableObject_Pkg.CreateSO(v_act_id, v_statuses_sid, v_status_class_id, r.description, v_donation_status_sid );
			EXCEPTION
				WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
					v_donation_status_sid := securableobject_pkg.GetSIDFromPath(v_act_id, c.app_sid, 'Donations/Statuses/' || r.description);
			END;
			-- update donation_status entry with new sid
			UPDATE DONATION_STATUS 
			   SET donation_status_sid = v_donation_status_sid 
			 WHERE donation_status_id = r.donation_status_id;
			 
			 -- update donations for new status object
			 UPDATE DONATION 
			    SET donation_status_sid = v_donation_status_sid
			   WHERE donation_status_id  = r.donation_status_id;
	
			 -- update letters for new status object	
			UPDATE LETTER_BODY_TEXT
					SET donation_status_sid = v_donation_status_sid 
				WHERE donation_status_id  = r.donation_status_id;
	
			-- update letters body region group for new status object	
			UPDATE LETTER_BODY_REGION_GROUP
					SET donation_status_sid = v_donation_status_sid 
				WHERE donation_status_id  = r.donation_status_id;
		END LOOP;
	END LOOP;
 
	-- now generate transitions for statuses
	FOR r IN (SELECT app_sid FROM CUSTOMER_FILTER_FLAG WHERE 	AUTO_GEN_STATUS_TRANSITION > 0)
	LOOP
		FOR from_row IN (SELECT donation_status_sid FROM donation_status WHERE app_sid = r.app_sid)
		LOOP		
			FOR to_row IN (SELECT donation_status_sid FROM donation_status WHERE app_sid = r.app_sid and donation_status_sid != from_row.donation_status_sid)
			LOOP
				transition_pkg.createTransition(from_row.donation_status_sid, to_row.donation_status_sid, r.app_sid, v_transistion_sid);			
			END LOOP;
		END LOOP;
	END LOOP;
	
		
	COMMIT;


END;
/



