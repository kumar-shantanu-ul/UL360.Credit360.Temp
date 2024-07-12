CREATE OR REPLACE PACKAGE BODY CSR.Objective_Pkg AS
-- Securable object callbacks

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;


PROCEDURE CopyObjective(
	in_act_id         IN  security_pkg.t_act_id,
	in_parent_sid_id  IN  security_pkg.t_sid_id,
	in_sid_id         IN  security_pkg.t_sid_id
)
AS
	v_sid_id NUMBER(10) ;
	v_class_id security_pkg.t_class_id;
	v_name security_pkg.t_so_name;
	v_n NUMBER;
BEGIN
	SELECT class_id, name
	  INTO v_class_id, v_name
	  FROM security.securable_object
	 WHERE sid_id = in_sid_id;
	IF v_class_id <> class_pkg.getclassid('CSRObjective') THEN
		securableobject_pkg.createso(in_act_id, in_parent_sid_id, v_class_id, v_name, v_sid_id);
	else
		v_n:=0;
		FOR r IN (SELECT * FROM objective WHERE objective_sid = in_sid_id) LOOP
			objective_pkg.createobjective(in_act_id, in_parent_sid_id, r.name, r.description, 
				r.responsible_user_sid, r.delivery_user_sid, r.xml_template, r.pos, v_sid_id);
				security_pkg.debugmsg('gave sid ' ||v_Sid_id);
			v_n := v_n + 1;
		END LOOP;
		IF v_n <> 1 THEN 
			raise_application_error(-20001, 'objective with sid '||in_sid_id||' was not found');
		END IF;
	END IF;
	
	FOR r IN (SELECT sid_id FROM security.securable_object WHERE parent_sid_id = in_sid_id) LOOP
		CopyObjective(in_act_id, v_sid_id, r.sid_id);
	END LOOP;
END;


PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
) AS
BEGIN
	UPDATE OBJECTIVE SET NAME = in_new_name WHERE objective_sid = in_sid_id;
END;


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS
BEGIN													  
	DELETE FROM OBJECTIVE_STATUS WHERE objective_sid = in_sid_id;
	DELETE FROM OBJECTIVE WHERE objective_sid = in_sid_id;
END;


PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS
BEGIN
	NULL;
END;


/**
 * Create a new objective
 *
 * @param	in_act_id				Access token
 * @param	in_parent_sid_id		Parent object
 * @param	in_name					Name
 * @param	in_description			Description
 * @param	in_responsible_user_sid	Responsible user sid
 * @param	in_delivery_user_sid	Delivery user sid
 * @param	in_xml_template			XML template				 
 * @param	in_pos					Pos
 * @param	out_objective_sid		The SID of the created object
 *
 */
PROCEDURE CreateObjective(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_parent_sid_id			IN security_pkg.T_SID_ID, 
	in_name						IN OBJECTIVE.NAME%TYPE,
	in_description				IN OBJECTIVE.description%TYPE,
	in_responsible_user_sid		IN OBJECTIVE.responsible_user_sid%TYPE,
	in_delivery_user_sid		IN OBJECTIVE.delivery_user_sid%TYPE,
	in_xml_template				IN OBJECTIVE.xml_template%TYPE,
	in_pos						IN OBJECTIVE.pos%TYPE,
	out_objective_sid			OUT OBJECTIVE.objective_sid%TYPE
)
AS
BEGIN	
	SecurableObject_Pkg.CreateSO(in_act_id, in_parent_sid_id, 
		class_pkg.getClassID('CSRObjective'), REPLACE(in_name,'/','\'), out_objective_sid);
	INSERT INTO OBJECTIVE 
		(objective_sid, name, description, responsible_user_sid, 
		 delivery_user_sid, xml_template, pos)
	VALUES 
		(out_objective_sid, in_name, in_description, in_responsible_user_sid,
		 in_delivery_user_sid, in_xml_template, in_pos);
	-- add permission: delivery_user_sid on this object
	-- NOTE THIS IS NOT INHERITABLE
	IF in_delivery_user_sid IS NOT NULL THEN 
		acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(out_objective_sid), 
			security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_INHERIT_INHERITABLE, in_delivery_user_sid,
			security_pkg.PERMISSION_STANDARD_READ + Csr_Data_Pkg.PERMISSION_SET_STATUS);
	END IF;
END;


/**
 * Update a objective
 *
 * @param	in_act_id				Access token
 * @param	in_objective_sid		The objective to update
 * @param	in_name					The new objective name
 * @param	in_description			The new objective description
 * @param	in_responsible_user_sid	The new user responsible for this
 * @param	in_delivery_user_sid	The new user delivering this
 * @param	in_xml_template			xml template for meta data
 * @param	in_pos					Pos
 */
PROCEDURE UpdateObjective(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_objective_sid		IN security_pkg.T_SID_ID,
	in_name						IN OBJECTIVE.NAME%TYPE,
	in_description				IN OBJECTIVE.description%TYPE,
	in_responsible_user_sid		IN OBJECTIVE.responsible_user_sid%TYPE,
	in_delivery_user_sid		IN OBJECTIVE.delivery_user_sid%TYPE,
	in_xml_template				IN OBJECTIVE.xml_template%TYPE,
	in_pos						IN OBJECTIVE.pos%TYPE
)
AS	   
	v_old_delivery_sid	security_pkg.T_SID_ID;
	c_acl				security_pkg.T_OUTPUT_CUR;
	v_dacl_id			security_pkg.T_ACL_ID;
	v_acl_id			security_pkg.T_ACL_ID;
	v_acl_index			security_pkg.T_ACL_INDEX;
	v_ace_type			security_pkg.T_ACE_TYPE;
	v_ace_flags			security_pkg.T_ACE_FLAGS;
	v_sid_id			security_pkg.T_SID_ID;
	v_permission_set	security_pkg.T_PERMISSION;			   
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_objective_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;															   
	-- rename so
	SecurableObject_pkg.renameSo(in_act_id, in_objective_sid, REPLACE(in_name,'/','\'));
	
	-- find who was responsible for this before and get rid of them if
	-- they're different and then give this new user appropriate permissions
	SELECT delivery_user_sid INTO v_old_delivery_sid 
	  FROM OBJECTIVE
	 WHERE objective_sid = in_objective_sid;  
	v_dacl_id := acl_pkg.GetDACLIDForSID(in_objective_sid); 
	IF v_old_delivery_sid IS NOT NULL AND v_old_delivery_sid != in_delivery_user_sid THEN
		acl_pkg.GetDACL(in_act_id, in_objective_sid, c_acl);
		-- delete old aces, reinsert but skipping the current user
		acl_pkg.DeleteAllACES(in_act_id, v_dacl_id);
		LOOP	
			FETCH c_acl INTO v_acl_id, v_acl_index, v_ace_type, v_ace_flags, v_sid_id, v_permission_set;
			EXIT WHEN c_acl%NOTFOUND;			
			IF v_sid_id != v_old_delivery_sid THEN
				acl_pkg.AddACE(in_act_id, v_acl_id, security_pkg.ACL_INDEX_LAST,
					v_ace_type, v_ace_flags, v_sid_id, v_permission_set);
			END IF;
		END LOOP;
	END IF;		
			 
	-- add permission: delivery_user_sid on this object
	-- NOTE THIS IS NOT INHERITABLE
	IF in_delivery_user_sid IS NOT NULL THEN			  
		acl_pkg.AddACE(in_act_id, v_dacl_id, 
			security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_INHERIT_INHERITABLE, in_delivery_user_sid,
			security_pkg.PERMISSION_STANDARD_READ + Csr_Data_Pkg.PERMISSION_SET_STATUS);
	END IF;		
			
	UPDATE OBJECTIVE SET  
		name = in_name, 
		description = in_description,
		responsible_user_sid = in_responsible_user_sid, 
		delivery_user_sid = in_delivery_user_sid,
		xml_template = xml_template,	
		pos = in_pos
	 WHERE objective_sid = in_objective_sid;
END;			


PROCEDURE SetStatus(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_objective_sid			IN security_pkg.T_SID_ID,
	in_start_dtm				IN OBJECTIVE_STATUS.start_dtm%TYPE,
	in_end_dtm					IN OBJECTIVE_STATUS.end_dtm%TYPE,
	in_score					IN OBJECTIVE_STATUS.score%TYPE,
	in_status_description		IN OBJECTIVE_STATUS.status_description%TYPE,
	in_status_xml				IN OBJECTIVE_STATUS.status_xml%TYPE
) AS
	v_user_sid security_pkg.T_SID_ID;
BEGIN	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_objective_sid, Csr_Data_Pkg.PERMISSION_SET_STATUS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting status');
	END IF;				
	-- TODO: check to see if this start/end combo overlaps with anything????											   
	
	user_pkg.GetSid(in_act_id, v_user_sid);		   
				   
	BEGIN
		INSERT INTO OBJECTIVE_STATUS
			(objective_sid, start_dtm, end_dtm, score, status_description, 
			 status_xml, last_updated_dtm, updated_by_sid)			  
		VALUES
			(in_objective_sid, in_start_dtm, in_end_dtm, in_score, in_status_description, 
				in_status_xml, SYSDATE, v_user_sid);		
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE OBJECTIVE_STATUS SET 
				score = in_score,  
				status_description = in_status_description,
				status_xml = in_status_xml, 
				last_updated_dtm = SYSDATE,
				updated_by_sid = v_user_sid,
				rolled_forward = 0
			 WHERE objective_sid = in_objective_sid 
			   AND start_dtm = in_start_dtm
			   AND end_dtm = in_end_dtm;  							 
	END;
END;


PROCEDURE GetObjective(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_objective_sid	IN security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_objective_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR														 
		SELECT o.name, o.description, o.xml_template, 
			o.responsible_user_sid, cu_responsible.full_name responsible_full_name,
			o.delivery_user_sid, cu_delivery.full_name delivery_full_name, pos	
		  FROM OBJECTIVE O, CSR_USER cu_responsible, CSR_USER cu_delivery
		 WHERE o.responsible_user_sid = cu_responsible.csr_user_sid(+)
		   AND o.delivery_user_sid = cu_delivery.csr_user_sid(+)
		   AND o.objective_sid = in_objective_sid;  
END;


PROCEDURE GetObjectiveAndStatus(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_objective_sid	IN security_pkg.T_SID_ID,
	in_start_dtm		IN OBJECTIVE_STATUS.start_dtm%TYPE,
	in_end_dtm			IN OBJECTIVE_STATUS.end_dtm%TYPE,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_objective_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR														 
		SELECT o.objective_sid, o.name, o.description, o.xml_template, 
			o.responsible_user_sid, cu_responsible.full_name responsible_full_name,
			o.delivery_user_sid, cu_delivery.full_name delivery_full_name,	
			os.start_dtm, os.end_dtm, o.pos,
			os.score, os.status_description, os.status_xml,
			os.updated_by_sid, cu_updated.full_name updated_by_full_name,
			os.last_updated_dtm, rolled_forward,
			security_pkg.SQL_IsAccessAllowedSID(in_act_id, o.objective_sid, Csr_Data_Pkg.PERMISSION_SET_STATUS) editable		
		  FROM OBJECTIVE O, OBJECTIVE_STATUS os, CSR_USER cu_responsible, CSR_USER cu_delivery,
		  	CSR_USER cu_updated
		 WHERE o.objective_sid = os.objective_sid(+)
		   AND o.responsible_user_sid = cu_responsible.csr_user_sid(+)
		   AND o.delivery_user_sid = cu_delivery.csr_user_sid(+)
		   AND os.updated_by_sid = cu_updated.csr_user_sid(+)
		   AND o.objective_sid = in_objective_sid
		   AND os.start_dtm(+) = in_start_dtm
		   AND os.end_dtm(+) = in_end_dtm;	
END;


PROCEDURE GetChildObjectivesAndStatus(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_parent_sid		IN security_pkg.T_SID_ID,		   
	in_start_dtm		IN OBJECTIVE_STATUS.start_dtm%TYPE,
	in_end_dtm			IN OBJECTIVE_STATUS.end_dtm%TYPE,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- the sec sp checks for list contents	
	OPEN out_cur FOR														 
		SELECT o.objective_sid, o.name, o.description, o.xml_template, 
			o.responsible_user_sid, cu_responsible.full_name responsible_full_name,
			o.delivery_user_sid, cu_delivery.full_name delivery_full_name,	
			os.start_dtm, os.end_dtm, o.pos,
			os.score, os.status_description, os.status_xml,
			os.updated_by_sid, cu_updated.full_name updated_by_full_name,
			os.last_updated_dtm, rolled_forward,
			security_pkg.SQL_IsAccessAllowedSID(in_act_id, o.objective_sid, Csr_Data_Pkg.PERMISSION_SET_STATUS) editable		
		  FROM OBJECTIVE O, OBJECTIVE_STATUS os, CSR_USER cu_responsible, CSR_USER cu_delivery,
		  	CSR_USER cu_updated
		 WHERE o.objective_sid = os.objective_sid(+)
		   AND o.responsible_user_sid = cu_responsible.csr_user_sid(+)
		   AND o.delivery_user_sid = cu_delivery.csr_user_sid(+)
		   AND os.updated_by_sid = cu_updated.csr_user_sid(+)
		   AND os.start_dtm(+) = in_start_dtm
		   AND os.end_dtm(+) = in_end_dtm
	       AND o.objective_sid IN	
			(SELECT SID_ID FROM TABLE(securableobject_pkg.GetChildrenAsTable(in_act_id, in_parent_sid)))
		 ORDER BY o.pos;
END;


PROCEDURE RollForwardObjectives(
	in_root_sid			IN security_pkg.T_SID_ID
)
AS
BEGIN
	INSERT INTO OBJECTIVE_STATUS  
		(OBJECTIVE_SID, START_DTM, END_DTM, SCORE, STATUS_DESCRIPTION, STATUS_XML, LAST_UPDATED_DTM, UPDATED_BY_SID, ROLLED_FORWARD)                      
		SELECT os.objective_sid, end_dtm start_dtm, ADD_MONTHS(end_dtm, MONTHS_BETWEEN(end_dtm, start_dtm)) end_dtm, 0, 
			status_description,	status_xml, last_updated_dtm, updated_by_sid, 1 rolled_forward
		  FROM OBJECTIVE_STATUS os,
			(
	        SELECT objective_sid, MAX(END_dtm) max_end_dtm
			  FROM OBJECTIVE_STATUS
			 GROUP BY objective_sid
			HAVING MAX(end_dtm) <= TRUNC(SYSDATE,'Q')                
	        )x
		 WHERE x.objective_sid = os.objective_sid
		   AND x.max_end_dtm = os.END_DTM
	       AND os.objective_sid IN        
	       (SELECT sid_id FROM SECURITY.securable_object
			CONNECT BY PRIOR sid_id = parent_sid_id
			START WITH sid_id = in_root_sid);
END;
			
END;
/
