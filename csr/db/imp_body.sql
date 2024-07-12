CREATE OR REPLACE PACKAGE BODY CSR.Imp_Pkg AS


/*
-- for showing what measures map to what -- needs sticking in the UI
select distinct m.measure_sid, m.description base_measure_description, im.imp_measure_id, 
    im.description imp_description, maps_to_measure_conversion_Id,
    maps_to_measure_sid, mc.description mapped_description
  from csr.imp_val iv
    join csr.imp_measure im on iv.imp_measure_id = im.imp_measure_id
    join csr.imp_ind ii on iv.imp_ind_id = ii.imp_ind_id
    join csr.ind i on ii.maps_to_ind_sid = i.ind_sid
    join csr.measure m on i.measure_sid = m.measure_sid
    left join csr.measure_conversion mc on im.maps_to_measure_conversion_id = mc.measure_conversion_id
 where imp_session_sid = 11326557;

*/
-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	NULL;
END;


PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
) AS
BEGIN
	UPDATE imp_session
	   SET name = in_new_name 
	 WHERE imp_session_sid = in_sid_id;
END;


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS
BEGIN
	-- delete feeds
	UPDATE feed_request 
	   SET imp_session_sid = null
     WHERE imp_session_sid = in_sid_id;
	
	-- delete conflicts	   
	DELETE FROM imp_conflict_val 
	 WHERE imp_conflict_id IN 
	 	  (SELECT imp_conflict_id FROM imp_conflict WHERE imp_session_sid = in_sid_id);		  

	DELETE FROM imp_conflict 
	 WHERE imp_session_sid = in_sid_id;
	
	-- unlink any data linked to this session
	UPDATE val
	   SET source_id = NULL 
	 WHERE source_type_id = csr_data_pkg.SOURCE_TYPE_IMPORT 
	   AND source_id IN (SELECT imp_val_id FROM imp_val WHERE imp_session_sid = in_sid_id);		  

	DELETE FROM imp_val 
	 WHERE imp_session_sid = in_sid_id;

	DELETE FROM imp_session 
	 WHERE imp_session_sid = in_sid_id;
END;


PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS
BEGIN
	UPDATE imp_session 
	   SET parent_sid = in_new_parent_sid_id
	 WHERE imp_session_sid = in_sid_id; 
END;	


/**
 * Create a new import session
 *
 * @param	in_act_id				Access token
 * @param	in_parent_sid_id		Parent object
 * @param	in_name					Name
 * @param 	in_file_path			file path
 * @param	out_sid_id				The SID of the created session
 *
 */
PROCEDURE CreateImpSession(
	in_act_id 				IN security_pkg.T_ACT_ID, 
	in_parent_sid_id 		IN security_pkg.T_SID_ID,
	in_app_sid 				IN security_pkg.T_SID_ID,
	in_name 				IN IMP_SESSION.NAME%TYPE,
	in_file_path 			IN IMP_SESSION.file_path%TYPE,
	out_sid_id				OUT security_pkg.T_SID_ID
) AS		 
	v_user_sid		security_pkg.T_SID_ID;
BEGIN
 	SecurableObject_pkg.CreateSO(in_act_id, in_parent_sid_id, class_pkg.GetClassID('CSRImpSession'),
		null, out_sid_id);			  
		
	User_Pkg.GetSid(in_act_id, v_user_sid);
	INSERT INTO imp_session 
		(imp_session_sid, parent_sid, owner_sid, name, file_path, uploaded_dtm, app_sid) 
	VALUES
		(out_sid_id, in_parent_sid_id, v_user_sid, in_name, in_file_path, SYSDATE, in_app_sid); 
END;					   


/**
 * Looks for a pending import parse job and if there is one, this
 * marks the parse job as started and returns an output 
 * cursor containing details.
 * 	
 * @param in_act_id		  Access token.
 *
 * The output rowset IS OF THE FORM:
 * imp_session_sid, file_path, name
 */
PROCEDURE GetAndStartParseJob(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_imp_session_sid		IN imp_session.imp_session_sid%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
IS 
	CURSOR c IS
	   SELECT imp_session_sid, file_path, name, parse_started_dtm, app_sid
	     FROM imp_session 
	    WHERE parse_started_dtm IS NULL
		  AND parsed_dtm IS NULL 
		  AND imp_session_sid = in_imp_session_sid FOR UPDATE;
	r c%ROWTYPE;
BEGIN
	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		-- blank recordset
		OPEN out_cur FOR
			SELECT NULL imp_session_sid, NULL name, NULL file_path, NULL app_sid 
			  FROM DUAL
			 WHERE 0 = 1;
	ELSE
		UPDATE imp_session 
		   SET parse_started_dtm = SYSDATE 
		 WHERE CURRENT OF c;
		OPEN out_cur FOR
			SELECT r.imp_session_sid imp_session_sid, r.name name, 
				r.file_path file_path, r.app_sid app_sid  FROM DUAL; 
	END IF;
	CLOSE c;
END;

PROCEDURE StartParseJob(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_imp_session_sid		IN imp_session.imp_session_sid%TYPE
)
IS 
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_imp_session_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	UPDATE imp_session
	   SET parse_started_dtm = SYSDATE
	 WHERE imp_session_sid = in_imp_session_sid
	   AND app_sid = security_pkg.getApp;
	 
END;


-- called by val_pkg.setValue to allow us to unhook anything
-- e.g. if we keep a pointer to a val_id
PROCEDURE OnValChange(
	in_val_id		imp_val.set_val_id%TYPE,
	in_imp_val_id	imp_val.imp_val_id%TYPE
)
AS
BEGIN
	UPDATE imp_val
	   SET set_val_id = NULL, set_region_metric_val_id = NULL
	 WHERE set_val_id = in_val_id;
END;


PROCEDURE SynchImpMeasures(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID	
)
AS
	CURSOR cMC IS
		SELECT im.imp_measure_id, im.ROWID rid, mc.measure_conversion_id
		  FROM imp_measure im, imp_ind ii, ind i, measure_conversion mc 
		 WHERE im.imp_ind_id = ii.imp_ind_id
		   AND ii.maps_to_ind_sid = i.ind_sid
		   AND i.measure_sid = mc.measure_sid
		   AND im.app_sid = in_app_sid
		   AND LOWER(im.description)  = LOWER(mc.description);
	CURSOR cM IS
		SELECT im.imp_measure_id, im.ROWID rid, m.measure_sid
		  FROM imp_measure im, imp_ind ii, ind i, measure m 
		 WHERE im.imp_ind_id = ii.imp_ind_id
		   AND ii.maps_to_ind_sid = i.ind_sid
		   AND i.measure_sid = m.measure_sid
		   AND im.app_sid = in_app_sid
		   AND LOWER(im.description) = LOWER(m.description);   
BEGIN
	FOR r IN cMC LOOP
		UPDATE imp_measure 
		   SET maps_to_measure_conversion_id = r.measure_conversion_id,
           	   maps_to_measure_sid = null
		 WHERE rowid = r.rid; 
	END LOOP;
	FOR r IN cM LOOP
		UPDATE imp_measure 
		   SET maps_to_measure_sid = r.measure_sid,
           	   maps_to_measure_conversion_id = null
		 WHERE rowid = r.rid; 
	END LOOP;
END;


/**
 * Marks a mailout as completed.
 * 	
 * @param in_act_id		  		Access token.
 * @param in_mailout_sid		Mailout Sid.
 * @param in_number_sent		Additional text note.
 */
PROCEDURE MarkParseJobCompleted(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_imp_session_sid		IN security_pkg.T_SID_ID,	
	in_result_code			IN IMP_SESSION.result_code%TYPE,
	in_message				IN IMP_SESSION.message%TYPE
)
AS
	CURSOR c IS
	   SELECT parsed_dtm 
	   	 FROM imp_session
	    WHERE imp_session_sid = in_imp_session_sid FOR UPDATE;
	r 	c%ROWTYPE;
BEGIN
	-- do we need to check permissions?
	
	OPEN c;
	FETCH c INTO r;

	-- can we even find this job?
	IF c%NOTFOUND THEN
	   RAISE_APPLICATION_ERROR(-20001, 'Imp Session not found');
	END IF;
	
	-- has it ended already?
	IF r.parsed_dtm IS NOT NULL THEN
	   RAISE_APPLICATION_ERROR(-20001, 'Imp Session already ended');
	END IF;
	
	UPDATE imp_session  
	   SET parsed_dtm = SYSDATE, result_code= in_result_code, message = substr(in_message,1, 2040)
	 WHERE CURRENT OF c;
END;


PROCEDURE GetSessionList(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_parent_sid	IN	security_pkg.T_SID_ID,	 
	in_order_by		IN	VARCHAR2, -- not used
	out_cur			OUT security_pkg.T_OUTPUT_CUR
) AS
BEGIN				
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied listing sessions');
	END IF;																									 
	
	OPEN out_cur FOR
		SELECT impS.imp_session_sid, impS.name, impS.owner_sid, cu.full_name, cu.email, 
			impS.uploaded_dtm, TO_CHAR(impS.uploaded_dtm, 'Dy dd-Mon-yyyy hh24:mi')||' GMT' uploaded_dtm_formatted,  
			impS.parsed_dtm, TO_CHAR(impS.parsed_dtm,'Dy dd-Mon-yyyy hh24:mi')||' GMT' parsed_dtm_formatted,  
			impS.merged_dtm, TO_CHAR(impS.merged_dtm,'Dy dd-Mon-yyyy hh24:mi')||' GMT' merged_dtm_formatted,
			NVL(unmerged_dtm, NVL(merged_dtm, NVL(parsed_dtm, uploaded_dtm))) status_dtm,
			TO_CHAR(NVL(unmerged_dtm, NVL(merged_dtm, NVL(parsed_dtm, uploaded_dtm))),'Dy dd-Mon-yyyy') status_dtm_formatted,
			CASE WHEN merged_dtm IS NULL THEN 0 ELSE 1 END is_merged,
			CASE WHEN result_code!=0 THEN 'Needs checking' WHEN parsed_dtm IS NULL THEN 'Uploaded' WHEN merged_dtm IS NULL THEN 'Being mapped' ELSE 'Merged' END status, 
			r.unmapped_regions, r.total_regions - r.unmapped_regions - r.ignored_regions mapped_regions, r.ignored_regions,
			i.unmapped_inds, i.total_inds - i.unmapped_inds - i.ignored_inds mapped_inds, i.ignored_inds,
			result_code, message,
			(SELECT COUNT(*) FROM IMP_CONFLICT WHERE imp_session_sid = ImpS.imp_session_sid) conflicts
		  FROM IMP_SESSION ImpS, CSR_USER cu,		
			(SELECT IMP_SESSION_SID, SUM(ir.v) unmapped_regions, COUNT(ir.v) total_regions, SUM(ir.ignore) ignored_regions
			  FROM 
			   (SELECT iv.imp_session_sid, CASE WHEN ir.maps_to_region_sid IS NULL AND ignore = 0 THEN 1 ELSE 0 END v, ir.ignore
				  FROM IMP_VAL iv, IMP_REGION ir
				 WHERE iv.imp_region_id = ir.imp_region_id	      
				 GROUP BY iv.IMP_SESSION_SID, iv.imp_region_id, ir.description, ir.maps_to_region_sid, ignore)ir
				 GROUP BY IMP_SESSION_sid)r,
			(SELECT IMP_SESSION_SID, SUM(ii.v) unmapped_inds, COUNT(ii.v) total_inds, SUM(ii.ignore) ignored_inds
			 FROM 
			   (SELECT iv.imp_session_sid, CASE WHEN ii.maps_to_ind_sid IS NULL AND ignore = 0 THEN 1 ELSE 0 END v, ii.ignore
				  FROM IMP_VAL iv, IMP_IND ii
				 WHERE iv.imp_ind_id = ii.imp_ind_id	      
				 GROUP BY iv.IMP_SESSION_SID, iv.imp_ind_id, ii.description, ii.maps_to_ind_sid, ignore)ii
				 GROUP BY IMP_SESSION_SID)i	
		 WHERE ImpS.imp_session_sid = i.imp_session_sid(+)
		   AND ImpS.imp_session_sid = r.imp_session_sid(+)
		   AND ImpS.owner_sid = cu.csr_user_sid(+)
		   AND ImpS.parent_sid = in_parent_sid
		 ORDER BY status_dtm DESC;
END;

PROCEDURE GetPagedSessionList(
	in_parent_sid	IN	security_pkg.T_SID_ID,	 
	in_start		IN	NUMBER,
	in_page_size	IN	NUMBER,
	out_count		OUT	NUMBER,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getact, in_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied listing sessions');
	END IF;
	
	SELECT count(*)
	  INTO out_count
	  FROM IMP_SESSION imps
	 WHERE imps.parent_sid = in_parent_sid;
	
	OPEN out_cur FOR		 
		SELECT * 
		  FROM (
			SELECT inr1.*, ROWNUM rn
			  FROM (
				SELECT imps.imp_session_sid, imps.name, imps.owner_sid, imps.uploaded_dtm, imps.parent_sid,
						CASE 
							WHEN result_code!=0 THEN 'Needs checking' 
							WHEN parsed_dtm IS NULL THEN 'Uploaded' 
							WHEN merged_dtm IS NULL THEN 'Being mapped' 
							ELSE 'Merged' 
						END status,
						CASE 
							WHEN merged_dtm IS NULL THEN 0
							ELSE 1
						END is_merged,
						CASE
							WHEN merged_dtm IS NOT NULL AND merged_dtm > imps.uploaded_dtm THEN merged_dtm
							WHEN unmerged_dtm IS NOT NULL AND unmerged_dtm > imps.uploaded_dtm THEN unmerged_dtm
							WHEN merged_dtm IS NULL THEN imps.uploaded_dtm
						END last_modified_dtm,
						NVL(r.unmapped_regions,0) unmapped_regions, 
						NVL(r.total_regions - r.unmapped_regions - r.ignored_regions,0) mapped_regions, 
						NVL(r.ignored_regions, 0) ignored_regions,
						NVL(i.unmapped_inds, 0) unmapped_inds, 
						NVL(i.total_inds - i.unmapped_inds - i.ignored_inds, 0) mapped_inds, 
						NVL(i.ignored_inds, 0) ignored_inds,
						(SELECT COUNT(*) FROM IMP_CONFLICT WHERE imp_session_sid = ImpS.imp_session_sid) conflicts
				  FROM	IMP_SESSION imps
				  LEFT JOIN
						(SELECT IMP_SESSION_SID, SUM(ir.v) unmapped_regions, COUNT(ir.v) total_regions, SUM(ir.ignore) ignored_regions
						  FROM 
						   (SELECT iv.imp_session_sid, CASE WHEN ir.maps_to_region_sid IS NULL AND ignore = 0 THEN 1 ELSE 0 END v, ir.ignore
							  FROM IMP_VAL iv, IMP_REGION ir
							 WHERE iv.imp_region_id = ir.imp_region_id AND iv.app_sid = ir.app_sid	      							 
                               AND iv.imp_session_sid IN (
                                    SELECT imp_session_sid FROM imp_session WHERE parent_sid = in_parent_sid
                               )
							 GROUP BY iv.IMP_SESSION_SID, iv.imp_region_id, ir.description, ir.maps_to_region_sid, ignore)ir
							 GROUP BY IMP_SESSION_sid
						 )r ON imps.imp_session_sid = r.imp_session_sid
				  LEFT JOIN
						(SELECT IMP_SESSION_SID, SUM(ii.v) unmapped_inds, COUNT(ii.v) total_inds, SUM(ii.ignore) ignored_inds
						 FROM 
						   (SELECT iv.imp_session_sid, CASE WHEN ii.maps_to_ind_sid IS NULL AND ignore = 0 THEN 1 ELSE 0 END v, ii.ignore
							  FROM IMP_VAL iv, IMP_IND ii
							 WHERE iv.imp_ind_id = ii.imp_ind_id AND iv.app_sid = ii.app_sid	    				 
                               AND iv.imp_session_sid IN (
                                    SELECT imp_session_sid FROM imp_session WHERE parent_sid = in_parent_sid
                               )  
							 GROUP BY iv.IMP_SESSION_SID, iv.imp_ind_id, ii.description, ii.maps_to_ind_sid, ignore)ii
							 GROUP BY IMP_SESSION_SID
						 )i ON imps.imp_session_sid = i.imp_session_sid				  
				 WHERE imps.parent_sid = in_parent_sid
				 ORDER BY imp_session_sid, uploaded_dtm DESC
				) inr1
			 WHERE ROWNUM <= in_start + in_page_size
			) inr2
		WHERE rn > in_start
		ORDER BY last_modified_dtm DESC;
END;

PROCEDURE GetSession(
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getact, in_imp_session_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading session');
	END IF;
	
	OPEN out_cur FOR
		SELECT imps.imp_session_sid, imps.name, imps.owner_sid, imps.uploaded_dtm, imps.parent_sid,
				CASE 
					WHEN result_code!=0 THEN 'Needs checking' 
					WHEN parsed_dtm IS NULL THEN 'Uploaded' 
					WHEN merged_dtm IS NULL THEN 'Being mapped' 
					ELSE 'Merged' 
				END status,
				CASE 
					WHEN merged_dtm IS NULL THEN 0
					ELSE 1
				END is_merged,
				r.unmapped_regions, r.total_regions - r.unmapped_regions - r.ignored_regions mapped_regions, r.ignored_regions,
				i.unmapped_inds, i.total_inds - i.unmapped_inds - i.ignored_inds mapped_inds, i.ignored_inds
		  FROM	IMP_SESSION imps
		  LEFT JOIN
				(SELECT IMP_SESSION_SID, SUM(ir.v) unmapped_regions, COUNT(ir.v) total_regions, SUM(ir.ignore) ignored_regions
				  FROM 
				   (SELECT iv.imp_session_sid, CASE WHEN ir.maps_to_region_sid IS NULL AND ignore = 0 THEN 1 ELSE 0 END v, ir.ignore
					  FROM IMP_VAL iv, IMP_REGION ir
					 WHERE iv.imp_region_id = ir.imp_region_id	      
					 GROUP BY iv.IMP_SESSION_SID, iv.imp_region_id, ir.description, ir.maps_to_region_sid, ignore)ir
					 GROUP BY IMP_SESSION_sid
				 )r ON imps.imp_session_sid = r.imp_session_sid
		  LEFT JOIN
				(SELECT IMP_SESSION_SID, SUM(ii.v) unmapped_inds, COUNT(ii.v) total_inds, SUM(ii.ignore) ignored_inds
				 FROM 
				   (SELECT iv.imp_session_sid, CASE WHEN ii.maps_to_ind_sid IS NULL AND ignore = 0 THEN 1 ELSE 0 END v, ii.ignore
					  FROM IMP_VAL iv, IMP_IND ii
					 WHERE iv.imp_ind_id = ii.imp_ind_id	      
					 GROUP BY iv.IMP_SESSION_SID, iv.imp_ind_id, ii.description, ii.maps_to_ind_sid, ignore)ii
					 GROUP BY IMP_SESSION_SID
				 )i ON imps.imp_session_sid = i.imp_session_sid				  
		 WHERE imps.imp_session_sid = in_imp_session_sid;
END;

PROCEDURE AddValueUnsecured(
	in_imp_session_sid		IN	security_pkg.T_SID_ID,	
	in_app_sid			IN	security_pkg.T_SID_ID,	 
	in_ind_description		IN	IMP_IND.description%TYPE,	 
	in_region_description	IN	IMP_REGION.description%TYPE,
	in_measure_description	IN	IMP_MEASURE.description%TYPE,
	in_unknown				IN 	IMP_VAL.unknown%TYPE,
	in_start_dtm			IN 	IMP_VAL.start_dtm%TYPE,
	in_end_dtm				IN 	IMP_VAL.end_dtm%TYPE,
	in_val					IN 	IMP_VAL.VAL%TYPE,
	in_note					IN 	IMP_VAL.NOTE%TYPE,
	in_file_sid				IN 	IMP_VAL.file_sid%TYPE,
	out_imp_val_id			OUT	IMP_VAL.imp_val_id%TYPE
) AS									
	v_imp_ind_id			IMP_VAL.imp_ind_id%TYPE;
	v_imp_region_id			IMP_VAL.imp_region_id%TYPE; 
	v_imp_measure_id		IMP_VAL.imp_measure_id%TYPE; 
BEGIN	  
	-- ind
	BEGIN
		INSERT INTO IMP_IND (imp_ind_id, app_sid, description)
			VALUES (imp_ind_id_seq.NEXTVAL, in_app_sid, IN_ind_description)
			RETURNING imp_ind_id INTO v_imp_ind_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT imp_ind_id
			  INTO v_imp_ind_id
			  FROM imp_ind
			 WHERE LOWER(description) = LOWER(in_ind_description);
	END;
	
	-- region
	BEGIN
		INSERT INTO IMP_REGION (imp_region_id, app_sid, description)
			VALUES (imp_region_id_seq.NEXTVAL, in_app_sid, IN_region_description)
			RETURNING imp_region_id INTO v_imp_region_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT imp_region_id
			  INTO v_imp_region_id
			  FROM imp_region
			 WHERE LOWER(description) = LOWER(in_region_description);
	END;
	
	-- measure
	IF in_measure_description IS NULL THEN
    	v_imp_measure_id := NULL;
    ELSE
		BEGIN
			INSERT INTO IMP_MEASURE (imp_measure_id, app_sid, description, imp_ind_id)
				VALUES (imp_measure_id_seq.NEXTVAL, in_app_sid, IN_measure_description, v_imp_ind_id)
				RETURNING imp_measure_id INTO v_imp_measure_id;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				SELECT imp_measure_id
				  INTO v_imp_measure_id
				  FROM imp_measure
				 WHERE LOWER(description) = LOWER(in_measure_description)
				   AND imp_ind_id = v_imp_ind_Id;
		END;
	END IF;
    
	-- store the value	
	INSERT INTO IMP_VAL 
		(imp_val_id, imp_ind_id, imp_region_id, imp_measure_id, unknown, start_dtm, END_dtm, VAL, note,
			file_sid, imp_session_sid)
	VALUES
		(imp_val_id_seq.NEXTVAL, v_imp_ind_id, v_imp_region_id, v_imp_measure_id, in_unknown,
		in_start_dtm, IN_end_dtm, in_val, in_note, in_file_sid, in_imp_session_sid)
	RETURNING imp_val_id INTO out_imp_val_id;
END;
 
/**
 * AddValueUnsecured
 * 
 * @param in_imp_session_sid		The import session sid
 * @param in_app_sid			The sid of the Application/CSR object
 * @param in_ind_description		The imp indicator id
 * @param in_region_description		The imp region id
 * @param in_measure_description	The imp measure id
 * @param in_unknown				Any unknown text
 * @param in_start_dtm				The start date
 * @param in_end_dtm				The end date
 * @param in_val					The value number
 * @param in_file_sid				The Sid of the file being imported
 * @param out_imp_val_id			Returns the new imp_val_id
 */
PROCEDURE AddValueUnsecuredFromIds(
	in_imp_session_sid		IN	security_pkg.T_SID_ID,	
	in_app_sid				IN	security_pkg.T_SID_ID,	 
	in_imp_ind_id			IN	imp_ind.imp_ind_id%TYPE,	 
	in_imp_region_id		IN	imp_region.imp_region_id%TYPE,
	in_imp_measure_id		IN	imp_measure.imp_measure_id%TYPE,
	in_unknown				IN 	imp_val.unknown%TYPE,
	in_start_dtm			IN 	imp_val.start_dtm%TYPE,
	in_end_dtm				IN 	imp_val.end_dtm%TYPE,
	in_val					IN 	imp_val.val%TYPE,
	in_note					IN 	imp_val.note%TYPE,
	in_file_sid				IN 	imp_val.file_sid%TYPE,
	out_imp_val_id			OUT	imp_val.imp_val_id%TYPE
) AS									
BEGIN	     
	-- store the value	
	INSERT INTO IMP_VAL 
		(imp_val_id, imp_ind_id, imp_region_id, imp_measure_id, unknown, start_dtm, end_dtm, val, note,
			file_sid, imp_session_sid)
	VALUES
		(imp_val_id_seq.NEXTVAL, in_imp_ind_id, in_imp_region_id, in_imp_measure_id, in_unknown,
		in_start_dtm, IN_end_dtm, in_val, in_note, in_file_sid, in_imp_session_sid)
	RETURNING imp_val_id INTO out_imp_val_id;
END; 

PROCEDURE CreateImpIndUnsec(	
	in_app_sid				IN	security_pkg.T_SID_ID,	 
	in_description			IN	imp_ind.description%TYPE,	
	out_imp_ind_id			OUT	imp_ind.imp_ind_id%TYPE
) AS
BEGIN	  
	-- ind
	BEGIN
		INSERT INTO imp_ind (imp_ind_id, app_sid, description)
	    VALUES (imp_ind_id_seq.NEXTVAL, in_app_sid, in_description)
			RETURNING imp_ind_id INTO out_imp_ind_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT imp_ind_id
			  INTO out_imp_ind_id
			  FROM imp_ind
			 WHERE LOWER(description) = LOWER(in_description);
	END;
END;

PROCEDURE CreateImpRegionUnsec(	
	in_app_sid					IN	security_pkg.T_SID_ID,	 
	in_description				IN	imp_region.description%TYPE,	
	out_imp_region_id			OUT	imp_region.imp_region_id%TYPE
) AS
BEGIN	  
	-- Region
	BEGIN
		INSERT INTO imp_region (imp_region_id, app_sid, description)
	    VALUES (imp_region_id_seq.NEXTVAL, in_app_sid, in_description)
			RETURNING imp_region_id INTO out_imp_region_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT imp_region_id
			  INTO out_imp_region_id
			  FROM imp_region
			 WHERE LOWER(description) = LOWER(in_description);
	END;
END;

PROCEDURE CreateImpMeasureUnsec(	
	in_app_sid					IN	security_pkg.T_SID_ID,	 
	in_description				IN	imp_measure.description%TYPE,	
	in_imp_ind_id				IN  imp_measure.imp_ind_id%TYPE,
	out_imp_measure_id			OUT	imp_measure.imp_measure_id%TYPE
) AS
BEGIN	  
	-- measure
	BEGIN
		INSERT INTO imp_measure (imp_measure_id, app_sid, description, imp_ind_id)
	    VALUES (imp_measure_id_seq.NEXTVAL, in_app_sid, in_description, in_imp_ind_id)
			RETURNING imp_measure_id INTO out_imp_measure_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT imp_measure_id
			  INTO out_imp_measure_id
			  FROM imp_measure
			 WHERE LOWER(description) = LOWER(in_description)
			   AND imp_ind_id = in_imp_ind_id;
	END;		   
END;

PROCEDURE getSessionIndicators(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_session_sid			IN	security_pkg.T_SID_ID,			
	in_imp_ind_id			IN	IMP_IND.imp_ind_id%TYPE,
	in_comp_direction		IN  NUMBER,
	in_sort_direction		IN  NUMBER,
	in_show_only_unmapped	IN  NUMBER,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_cond_and_order_by VARCHAR2(1000);
BEGIN
	-- check permission on session	   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_session_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;					  
	
	v_cond_and_order_by := '';
	
	IF in_show_only_unmapped = 1 THEN
		v_cond_and_order_by := ' AND II.MAPS_TO_IND_SID IS NULL AND II.IGNORE = 0 ';
	END IF;
		        
	IF in_comp_direction < 0 THEN	
		v_cond_and_order_by := v_cond_and_order_by || ' AND II.IMP_IND_ID < :in_min_imp_ind_id';
	ELSIF in_comp_direction = 0 THEN  												
		v_cond_and_order_by := v_cond_and_order_by || ' AND II.IMP_IND_ID >= :in_min_imp_ind_id';
	ELSIF in_comp_direction > 0 THEN  												
		v_cond_and_order_by := v_cond_and_order_by || ' AND II.IMP_IND_ID > :in_min_imp_ind_id';
	END IF; 	 
				  
	IF in_sort_direction < 0 THEN	
		v_cond_and_order_by := v_cond_and_order_by || ' ORDER BY II.POS DESC';
	ELSE  												
		v_cond_and_order_by := v_cond_and_order_by || ' ORDER BY II.POS ASC';
	END IF; 	   
		      
	OPEN out_cur FOR 	  			
		'SELECT II.POS, II.IMP_IND_ID, II.DESCRIPTION,IGNORE,'|| 
			' II.MAPS_TO_IND_SID, I.DESCRIPTION IND_DESCRIPTION'||
		  ' FROM V$IND I,'||  
			' (SELECT IMP_IND_ID, MAPS_TO_IND_SID, DESCRIPTION, ROWNUM POS, IGNORE FROM'|| 
				' (SELECT DISTINCT II.IMP_IND_ID, MAPS_TO_IND_SID, II.DESCRIPTION, IGNORE '||  
				  ' FROM IMP_VAL IV, IMP_IND II'||
				 ' WHERE IV.IMP_IND_ID = II.IMP_IND_ID'||
				   ' AND IMP_SESSION_SID = :in_session_sid ORDER BY imp_ind_id))II'||
			' WHERE II.MAPS_TO_IND_SID = I.IND_SID(+)'||v_cond_and_order_by 
			USING in_session_sid, in_imp_ind_id;	  
END; 

PROCEDURE getSessionIndicators(
	in_session_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- check permission on session	   	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_session_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the import session with sid '||in_session_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT ii.imp_ind_id, ii.description, ii.ignore, ii.maps_to_ind_sid, i.description ind_description
		  FROM imp_ind ii, v$ind i, (
		  		SELECT app_sid, imp_ind_id
		  		  FROM imp_val
		  		 WHERE imp_session_sid = in_session_sid
		  		 GROUP BY app_sid, imp_ind_id) iiv
		 WHERE ii.app_sid = iiv.app_sid
		   AND ii.imp_ind_id = iiv.imp_ind_id
		   AND ii.app_sid = i.app_sid(+)
		   AND ii.maps_to_ind_sid = i.ind_sid(+)
		 ORDER BY ii.imp_ind_id;
END;

PROCEDURE getSessionRegions(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_session_sid			IN	security_pkg.T_SID_ID,			
	in_imp_region_id		IN	IMP_REGION.imp_region_id%TYPE,
	in_comp_direction		IN  NUMBER,
	in_sort_direction		IN  NUMBER,
	in_show_only_unmapped	IN  NUMBER,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_cond_and_order_by VARCHAR2(1000) := '';
    v_unmapped_only		VARCHAR2(200) := '';
    v_sql VARCHAR2(4000);
BEGIN
	-- check permission on session	   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_session_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;					  
	
	
	IF in_show_only_unmapped = 1 THEN
		v_unmapped_only := 'AND IR.MAPS_TO_REGION_SID IS NULL AND IR.IGNORE = 0 ';
	END IF;
		        
	IF in_comp_direction < 0 THEN	
		v_cond_and_order_by := ' IR.IMP_REGION_ID < :in_min_imp_region_id';
	ELSIF in_comp_direction = 0 THEN  												
		v_cond_and_order_by := ' IR.IMP_REGION_ID >= :in_min_imp_region_id';
	ELSIF in_comp_direction > 0 THEN  												
		v_cond_and_order_by := ' IR.IMP_REGION_ID > :in_min_imp_region_id';
	END IF; 	 
				  
	IF in_sort_direction < 0 THEN	
		v_cond_and_order_by := v_cond_and_order_by || ' ORDER BY IR.POS DESC';
	ELSE  												
		v_cond_and_order_by := v_cond_and_order_by || ' ORDER BY IR.POS ASC';
	END IF; 	   
	
    v_sql := 'SELECT IMP_REGION_ID, MAPS_TO_REGION_SID, DESCRIPTION, REGION_DESCRIPTION, POS, IGNORE ' 
	   	   ||'FROM (SELECT IMP_REGION_ID, MAPS_TO_REGION_SID, DESCRIPTION, REGION_DESCRIPTION, ROWNUM POS, IGNORE ' 
	         ||'FROM (SELECT DISTINCT IR.IMP_REGION_ID, MAPS_TO_REGION_SID, IR.DESCRIPTION, R.DESCRIPTION REGION_DESCRIPTION, IGNORE '
	           ||'FROM IMP_VAL IV, IMP_REGION IR, V$REGION R ' 
	          ||'WHERE IV.IMP_REGION_ID = IR.IMP_REGION_ID  '
	            ||'AND IMP_SESSION_SID = :in_session_sid '
	            ||'AND IR.MAPS_TO_REGION_SID = R.REGION_SID(+) '||v_unmapped_only
	          ||'ORDER BY IMP_REGION_ID))IR '
		  ||'WHERE '||v_cond_and_order_by;
      	      
	OPEN out_cur FOR 	
    	v_sql USING in_session_sid, in_imp_region_id;
            
    --security_pkg.debugmsg(v_sql||' '||in_imp_region_id);
END;  

PROCEDURE getSessionRegions(
	in_session_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- check permission on session	   	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_session_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the import session with sid '||in_session_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT ir.imp_region_id, ir.description, ir.ignore, ir.maps_to_region_sid, r.description region_description
		  FROM imp_region ir, v$region r, (
		  		SELECT app_sid, imp_region_id
		  		  FROM imp_val
		  		 WHERE imp_session_sid = in_session_sid
		  		 GROUP BY app_sid, imp_region_id) irv
		 WHERE ir.app_sid = irv.app_sid
		   AND ir.imp_region_id = irv.imp_region_id
		   AND ir.app_sid = r.app_sid(+)
		   AND ir.maps_to_region_sid = r.region_sid(+)
		 ORDER BY ir.imp_region_id;
END;

PROCEDURE getValuesForImpIndId(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_session_sid		IN	security_pkg.T_SID_ID,			
	in_imp_ind_id		IN	imp_ind.imp_ind_id%TYPE,   
	in_order_by			IN	VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_total_rows		NUMBER;
BEGIN
	getValuesForImpIndId(in_act_id, in_session_sid, in_imp_ind_id, in_order_by, 0, 10000000, v_total_rows, out_cur);
END;

PROCEDURE getValuesForImpIndId(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_session_sid		IN	security_pkg.T_SID_ID,			
	in_imp_ind_id		IN	imp_ind.imp_ind_id%TYPE,   
	in_order_by			IN	VARCHAR2,
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	out_total_rows		OUT	NUMBER,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_order_by	VARCHAR2(1000);
BEGIN
	-- check permission on session	   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_session_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	   
		
	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'imp_region_description,start_dtm,end_dtm,unknown,val,file_sid,filename');
		v_order_by := ' ORDER BY ' || in_order_by;
	END IF;
	
	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM imp_val
	 WHERE imp_ind_id = in_imp_ind_id 
	   AND imp_session_sid = in_session_sid;

	OPEN out_cur FOR
		'SELECT *'||
		  'FROM ('||
			'SELECT *'||
			  'FROM ('||
				'SELECT rownum rn, q.* '||
				  'FROM ('||
						'SELECT iv.imp_val_id,'||
							  ' ir.description imp_region_description, ir.imp_region_id, '||	 
							  ' iv.start_dtm, to_char(iv.start_dtm, ''dd mon yy'') start_dtm_formatted,'||
							  ' iv.end_dtm, to_char(iv.end_dtm-1, ''dd mon yy'') end_dtm_formatted,'||
							  ' iv.unknown, iv.val,'|| 
							  ' iv.file_sid, fu.filename'||
						 ' FROM imp_val iv, imp_region ir, file_upload fu'||
						' WHERE iv.imp_ind_id = :in_imp_ind_id'||
						  ' AND iv.app_sid = ir.app_sid'||
						  ' AND iv.imp_region_id = ir.imp_region_id'|| 
						  ' AND iv.app_sid = fu.app_sid'||
						  ' AND iv.file_sid = fu.file_upload_sid'||
						  ' AND iv.imp_session_sid = :in_session_sid'||v_order_by||
					    ') q '||
					 ')'||
				 'WHERE rownum <= :in_limit'||
				') '||
		 'WHERE rn > :in_start_row'
	USING in_imp_ind_id, in_session_sid, in_start_row + in_page_size, in_start_row;
END; 

PROCEDURE getValuesForImpRegionId(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_session_sid		IN	security_pkg.T_SID_ID,			
	in_imp_region_id	IN	imp_region.imp_region_id%TYPE,   
	in_order_by			IN	VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_total_rows		NUMBER;
BEGIN
	getValuesForImpRegionId(in_act_id, in_session_sid, in_imp_region_id, in_order_by, 0, 10000000, v_total_rows, out_cur);
END;

PROCEDURE getValuesForImpRegionId(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_session_sid		IN	security_pkg.T_SID_ID,			
	in_imp_region_id	IN	imp_region.imp_region_id%TYPE,   
	in_order_by			IN	VARCHAR2,
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	out_total_rows		OUT	NUMBER,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_order_by	VARCHAR2(1000);
BEGIN
	-- check permission on session	   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_session_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	   
		
	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'imp_ind_description,start_dtm,end_dtm,unknown,val,file_sid,filename');
		v_order_by := ' ORDER BY ' || in_order_by;
	END IF;
	
	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM imp_val
	 WHERE imp_region_id = in_imp_region_id 
	   AND imp_session_sid = in_session_sid;

	OPEN out_cur FOR
		'SELECT *'||
		  'FROM ('||
			'SELECT *'||
			  'FROM ('||
				'SELECT rownum rn, q.* '||
				  'FROM ('||
						'SELECT iv.imp_val_id,'||
							  ' ii.description imp_ind_description, ii.imp_ind_id, '||	 
							  ' iv.start_dtm, to_char(iv.start_dtm, ''dd mon yy'') start_dtm_formatted,'||
							  ' iv.end_dtm, to_char(iv.end_dtm-1, ''dd mon yy'') end_dtm_formatted,'||
							  ' iv.unknown, iv.val,'|| 
							  ' iv.file_sid, fu.filename'||
						 ' FROM imp_val iv, imp_ind ii, file_upload fu'||
						' WHERE iv.imp_region_id = :in_imp_region_id'||
						  ' AND iv.app_sid = ii.app_sid'||
						  ' AND iv.imp_ind_id = ii.imp_ind_id'||
						  ' AND iv.app_sid = fu.app_sid'||
						  ' AND iv.file_sid = fu.file_upload_sid'||
						  ' AND iv.imp_session_sid = :in_session_sid'||v_order_by||
					    ') q '||
					')'||
				 'WHERE rownum <= :in_limit'||
			') '||
		 'WHERE rn > :in_start_row'
	USING in_imp_region_id, in_session_sid, in_start_row + in_page_size, in_start_row;
END; 

PROCEDURE mapImpIndToSid(	
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_ind_id		IN	IMP_IND.imp_ind_id%TYPE,
	in_maps_to_sid		IN	IMP_IND.maps_to_ind_sid%TYPE   
)
AS 
	CURSOR c IS
		SELECT DISTINCT imp_session_sid 
		  FROM IMP_VAL 
		 WHERE imp_ind_id = in_imp_ind_id;	  
	CURSOR c_clean IS
		 SELECT ICV.IMP_CONFLICT_ID, COUNT(ICV.imp_val_id)  
		   FROM IMP_CONFLICT_VAL ICV
		  WHERE IMP_CONFLICT_ID IN
		  	(SELECT IMP_CONFLICT_ID 
			   FROM IMP_CONFLICT_VAL
			  WHERE imp_val_id IN
			  	(SELECT imp_val_id FROM IMP_VAL WHERE IMP_IND_ID = in_imp_ind_id))
		  GROUP BY IMP_CONFLICT_ID
		 HAVING COUNT(ICV.imp_val_id) <= 2; 
BEGIN	 
	-- TODO: check permissions		
	  
	-- clean up any conflicts that would otherwise be left with 1 member
	FOR r IN c_clean LOOP
		DELETE FROM IMP_CONFLICT_VAL WHERE IMP_CONFLICT_ID = r.IMP_CONFLICT_ID;
		DELETE FROM IMP_CONFLICT WHERE IMP_CONFLICT_ID = r.IMP_CONFLICT_ID; 
	END LOOP;		
	
	DELETE FROM IMP_CONFLICT_VAL WHERE 
		imp_val_id IN (SELECT imp_val_id FROM IMP_VAL WHERE IMP_IND_ID = in_imp_ind_id);
	
	-- clear ignore flag too
	UPDATE IMP_IND 
	   SET maps_to_ind_sid = in_maps_to_sid , ignore = 0
	 WHERE imp_ind_id = in_imp_ind_id; 		
	 		 			  
	-- insert conflicts for all sessions that use this imp_region_id
	FOR r IN c LOOP 
		insertConflicts(in_act_id, r.imp_session_sid);
	END LOOP;  
	
END;  	 


PROCEDURE IgnoreImpInd(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_imp_ind_id	IN	IMP_IND.imp_ind_id%TYPE
)
AS
BEGIN
	mapImpIndToSid(in_act_id, in_imp_ind_id, NULL);

	-- mapImpRegionToSid clears ignore flag, so we must set it here
	UPDATE imp_ind
	   SET ignore = 1
	 WHERE imp_ind_id = in_imp_ind_id;
END;


PROCEDURE mapImpRegionToSid(	
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_region_id	IN	IMP_REGION.imp_region_id%TYPE,
	in_maps_to_sid		IN	IMP_REGION.maps_to_region_sid%TYPE   
)
AS
	CURSOR c IS
		SELECT DISTINCT imp_session_sid 
		  FROM imp_val 
		 WHERE imp_region_id = in_imp_region_id; 

	CURSOR c_clean IS
		 SELECT icv.imp_conflict_id, COUNT(icv.imp_val_id)
		   FROM imp_conflict_val icv
		  WHERE imp_conflict_id IN (
		  		SELECT imp_conflict_id 
				  FROM imp_conflict_val
				 WHERE imp_val_id IN (
					SELECT imp_val_id
					  FROM imp_val
					 WHERE imp_region_id = in_imp_region_id))
		  GROUP BY imp_conflict_id
		 HAVING COUNT(icv.imp_val_id) <= 2; 
BEGIN	 
	-- TODO: check permissions			  
	
	-- clean up any conflicts that would otherwise be left with 1 member
	FOR r IN c_clean LOOP
		DELETE FROM imp_conflict_val
		 WHERE imp_conflict_id = r.imp_conflict_id;
		
		DELETE FROM imp_conflict
		 WHERE imp_conflict_id = r.imp_conflict_id; 
	END LOOP;	

	DELETE FROM imp_conflict_val
	 WHERE imp_val_id IN (
	 		SELECT imp_val_id
	 		  FROM imp_val
	 		 WHERE imp_region_id = in_imp_region_id); 
	
	-- clear ignore flag too
	UPDATE imp_region 
	   SET maps_to_region_sid = in_maps_to_sid , ignore = 0
	 WHERE imp_region_id = in_imp_region_id; 
							  
	-- insert conflicts for all sessions that use this imp_region_id
	FOR r IN c LOOP 
		insertConflicts(in_act_id, r.imp_session_sid);
	END LOOP;		 	
END;

PROCEDURE IgnoreImpRegion(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_region_id	IN	IMP_REGION.imp_region_id%TYPE
)
AS
BEGIN
	mapImpRegionToSid(in_act_id, in_imp_region_id, NULL);

	-- mapImpRegionToSid clears ignore flag, so we must set it here
	UPDATE imp_region 
	   SET ignore = 1
	 WHERE imp_region_id = in_imp_region_id;
END;


PROCEDURE getMappingsToIndicator( 
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permission on session	   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	   
	 
	OPEN out_cur FOR
		SELECT DISTINCT ii.imp_ind_id, ii.description  
		  FROM imp_ind ii, imp_val iv
		 WHERE ii.imp_ind_id = iv.imp_ind_id
		   AND ii.maps_to_ind_sid = in_ind_sid
		   AND iv.imp_session_sid = in_imp_session_sid;
END;


PROCEDURE getMappingsToRegion( 
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permission on session	   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	   
	 
	OPEN out_cur FOR
		SELECT DISTINCT IR.imp_region_id, IR.description  
		  FROM IMP_REGION IR, IMP_VAL IV
		 WHERE IR.IMP_REGION_ID = IV.IMP_REGION_ID
		   AND IR.MAPS_TO_REGION_SID = in_region_sid
		   AND IV.IMP_SESSION_SID = in_imp_session_sid;
END;


PROCEDURE deleteFileData( 
	in_act_id	IN	security_pkg.T_ACT_ID,
	in_file_sid	IN	security_pkg.T_SID_ID
)
AS
	CURSOR c_clean IS
		 SELECT ICV.IMP_CONFLICT_ID, COUNT(ICV.imp_val_id)  
		   FROM IMP_CONFLICT_VAL ICV
		  WHERE IMP_CONFLICT_ID IN
		  	(SELECT IMP_CONFLICT_ID 
			   FROM IMP_CONFLICT_VAL
			  WHERE imp_val_id IN
			  	(SELECT imp_val_id FROM IMP_VAL WHERE FILE_SID = in_file_sid))
		  GROUP BY IMP_CONFLICT_ID
		 HAVING COUNT(ICV.imp_val_id) <= 2;
	CURSOR c IS
		SELECT DISTINCT imp_session_sid FROM IMP_VAL WHERE FILE_SID = in_file_sid;
	r_sessions	c%ROWTYPE;
BEGIN											  
	-- clean up any conflicts that would otherwise be left with 1 member
	FOR r IN c_clean LOOP
		DELETE FROM IMP_CONFLICT_VAL WHERE IMP_CONFLICT_ID = r.IMP_CONFLICT_ID;
		DELETE FROM IMP_CONFLICT WHERE IMP_CONFLICT_ID = r.IMP_CONFLICT_ID; 
	END LOOP;	

	DELETE FROM IMP_CONFLICT_VAL WHERE 
		imp_val_id IN (SELECT imp_val_id FROM IMP_VAL WHERE FILE_SID = in_file_sid);	 
	-- update main value table to unlink the value to some imported data
	UPDATE VAL SET source_id = NULL
		WHERE source_type_id = csr_data_pkg.SOURCE_TYPE_IMPORT 
		AND source_id IN (SELECT imp_val_id FROM IMP_VAL WHERE FILE_SID = in_file_sid);
		  
	-- open the cursor before we trash the data
	OPEN c;
	FETCH c INTO r_sessions;
				 
	DELETE FROM IMP_VAL WHERE FILE_SID = in_file_sid;
 							  
	-- insert conflicts for all sessions that use this imp_region_id
	LOOP											  
		EXIT WHEN c%NOTFOUND;
		insertConflicts(in_act_id, r_sessions.imp_session_sid);
		FETCH c INTO r_sessions;
	END LOOP;		

END;


PROCEDURE insertConflicts(	
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID   
)
AS			  
	CURSOR c IS
	  SELECT /*+ALL_ROWS CARDINALITY(iv, 200000) CARDINALITY(ii, 1000) CARDINALITY(ir, 1000) CARDINALITY(i, 10000) CARDINALITY(r, 10000)*/ iv.imp_val_id, 
	 		 iv.imp_ind_id, iv.imp_region_id,   
			 ii.maps_to_ind_sid, ir.maps_to_region_sid, 
	 		 iv.start_dtm, iv.end_dtm, iv.val
	   FROM imp_val iv, imp_ind ii, imp_region ir, ind i, region r
	  WHERE iv.imp_ind_id = ii.imp_ind_id AND iv.app_sid = ii.app_sid
	    AND iv.imp_region_id = ir.imp_region_id AND iv.app_sid = ir.app_sid
	    AND ii.maps_to_ind_sid = i.ind_sid AND ii.app_sid = i.app_sid
	    AND ir.maps_to_region_sid = r.region_sid AND ir.app_sid = r.app_sid
	    AND iv.imp_session_sid = in_imp_session_sid
	  ORDER BY ii.maps_to_ind_sid, ir.maps_to_region_sid, iv.start_dtm, iv.end_dtm;

	CURSOR c_conflict(in_ind_sid security_pkg.T_SID_ID, in_region_sid security_pkg.T_SID_ID, in_start_dtm DATE, in_end_dtm DATE) IS
		SELECT imp_conflict_id, start_dtm, end_dtm 
		  FROM imp_conflict 
		 WHERE region_sid = in_region_sid AND ind_sid = in_ind_sid
		   AND ((start_dtm >= in_start_dtm AND start_dtm < in_end_dtm)
		         OR (end_dtm > in_start_dtm AND end_dtm <= in_end_dtm))
	 	   AND imp_session_sid = in_imp_session_sid;
	r_conflict	c_conflict%ROWTYPE; 
	last	c%ROWTYPE;
	v_imp_conflict_id	IMP_CONFLICT.imp_conflict_id%TYPE;
	v_start_dtm			IMP_CONFLICT.start_dtm%TYPE;
	v_end_dtm			IMP_CONFLICT.end_dtm%TYPE;
	v_just_added		BOOLEAN;			
BEGIN				
	--TODO: Permission check???
			
	FOR r IN c LOOP								
		-- does time overlaps and mapped to same ind + region?
		IF last.maps_to_ind_sid = r.maps_to_ind_sid AND last.maps_to_region_sid = r.maps_to_region_sid
			AND	last.end_dtm > r.start_dtm THEN
			
			v_start_dtm := LEAST(r.start_dtm, last.start_dtm);
			v_end_dtm := GREATEST(r.end_dtm, last.end_dtm);
			
			-- does a conflict already exist that we can add ourselves to?
			OPEN c_conflict(r.maps_to_ind_sid, r.maps_to_region_sid, v_start_dtm, v_end_dtm);
			FETCH c_conflict INTO r_conflict;
			IF c_conflict%FOUND THEN	   
				v_imp_conflict_id := r_conflict.imp_conflict_id;  
				
				-- are we involved in this conflict already??? we shouldn't be!!
				-- actually, don't care - we'll trap the DUP_VAL_ON_INDEXS instead
				-- XXX: this looks buggy, shouldn't this code be updating the date ranges on imp_conflict?
				IF v_start_dtm < r_conflict.start_dtm OR v_end_dtm > r_conflict.end_dtm THEN
					v_start_dtm := LEAST(r_conflict.start_dtm, v_start_dtm);
					v_end_dtm := GREATEST(r_conflict.end_dtm, v_end_dtm);
					UPDATE imp_conflict
					   SET start_dtm = v_start_dtm,
					   	   end_dtm = v_end_dtm
					 WHERE imp_conflict_id = v_imp_conflict_id;					   	   
				END IF;
			ELSE
				INSERT INTO imp_conflict (imp_conflict_id, imp_session_sid, region_sid, ind_sid, start_dtm, end_dtm)
				VALUES (imp_conflict_id_seq.NEXTVAL, in_imp_session_sid, r.maps_to_region_sid, r.maps_to_ind_sid, v_start_dtm, v_end_dtm)
				RETURNING imp_conflict_id INTO v_imp_conflict_id;
			END IF;
			CLOSE c_conflict;		  
			-- if this is the first row of the conflict - try and insert
			IF NOT v_just_added THEN
				BEGIN
					INSERT INTO imp_conflict_val (imp_conflict_id, imp_val_id) 
					VALUES (v_imp_conflict_id, last.imp_val_id);
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						NULL;
				END;
			END IF;	 
			-- try and insert this one  
			BEGIN
				INSERT INTO imp_conflict_val (imp_conflict_id, imp_val_id) 
				VALUES (v_imp_conflict_id, r.imp_val_id);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
			END;
			v_just_added := TRUE;
		ELSE
			v_just_added := FALSE;
		END IF;		
		-- try next
		last := r;
	END LOOP;
END;	


PROCEDURE getConflictList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_session_sid		IN	security_pkg.T_SID_ID,			
	in_order_by			IN	VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_order_by	VARCHAR2(1000);
BEGIN
	-- check permission on session	   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_session_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	   
		
	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'region_description,ind_description,start_dtm,end_dtm');
		v_order_by := ' ORDER BY ' || in_order_by;
	END IF;
	
	OPEN out_cur FOR
		'SELECT IMP_CONFLICT_ID, '|| 
			'R.DESCRIPTION REGION_DESCRIPTION, '||
			'I.DESCRIPTION IND_DESCRIPTION, '||
			'START_DTM, TO_CHAR(START_DTM,''dd Mon yyyy'') START_DTM_FORMATTED, '||
			'END_DTM, TO_CHAR(END_DTM,''dd Mon yyyy'') END_DTM_FORMATTED '||
		  'FROM IMP_CONFLICT IC, V$REGION R, V$IND I '||
		 'WHERE IC.APP_SID = R.APP_SID AND IC.REGION_SID = R.REGION_SID '||
		   'AND IC.APP_SID = I.APP_SID AND IC.IND_SID = I.IND_SID '||
		   'AND IC.APP_SID = security.security_pkg.getApp ' ||
		   'AND IMP_SESSION_SID = :in_session_sid'||v_order_by USING in_session_sid;		  
END;  


PROCEDURE getConflict(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_conflict_id	IN	IMP_CONFLICT.imp_conflict_id%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_imp_session_sid	security_pkg.T_SID_ID; 
BEGIN
	SELECT imp_session_sid INTO v_imp_session_sid 
	  FROM IMP_CONFLICT
	 WHERE imp_conflict_id = in_imp_conflict_id;
	 
	-- check permission on session	   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_imp_session_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	   
		
	OPEN out_cur FOR
		SELECT imp_conflict_id, r.description region_description, 
			   i.description ind_description, start_dtm, end_dtm
		  FROM imp_conflict ic, v$region r, v$ind i
		 WHERE ic.region_sid = r.region_sid 
		   AND ic.ind_sid = i.ind_sid
		   AND ic.imp_conflict_id = in_imp_conflict_id;		  
END;  


PROCEDURE getConflictDetailList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_conflict_id	IN	security_pkg.T_SID_ID,			
	in_order_by			IN	VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_order_by	VARCHAR2(1000);
	v_imp_session_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT imp_session_sid INTO v_imp_session_sid 
	  FROM IMP_CONFLICT
	 WHERE imp_conflict_id = in_imp_conflict_id;
	  
	-- check permission on session	   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_imp_session_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	   
		
	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'imp_conflict_id,imp_val_id,val,file_sid,filename,'||
			'imp_ind_description,imp_region_description,ind_description,region_description,start_dtm,end_dtm');
		v_order_by := ' ORDER BY ' || in_order_by;
	END IF;
	
	-- show what the conflict is		
	OPEN out_cur FOR
		'SELECT ICV.IMP_CONFLICT_ID, IV.imp_val_id, IV.VAL, IV.FILE_SID, F.FILENAME, '||
			'II.DESCRIPTION IMP_IND_DESCRIPTION, II.IMP_IND_ID, '||
			'IR.DESCRIPTION IMP_REGION_DESCRIPTION, IR.IMP_REGION_ID, '||
			'I.DESCRIPTION IND_DESCRIPTION, ACCEPT, '||
			'R.DESCRIPTION REGION_DESCRIPTION, '||
			'START_DTM, TO_CHAR(START_DTM,''dd Mon yyyy'') START_DTM_FORMATTED, '||
			'END_DTM, TO_CHAR(END_DTM,''dd Mon yyyy'') END_DTM_FORMATTED, iv.note '||
		  'FROM IMP_CONFLICT_VAL ICV, IMP_VAL IV, IMP_IND II, IMP_REGION IR, V$IND I, V$REGION R, FILE_UPLOAD F '||
		 'WHERE ICV.imp_val_id = IV.imp_val_id '||
		   'AND IV.IMP_REGION_ID = IR.IMP_REGION_ID '||
		   'AND IV.IMP_IND_ID = II.IMP_IND_ID '||
		   'AND II.MAPS_TO_IND_SID = I.IND_SID '|| 
		   'AND IR.MAPS_TO_REGION_SID = R.REGION_SID '||
		   'AND F.FILE_UPLOAD_SID = IV.FILE_SID '||
		   'AND IMP_CONFLICT_ID = :in_imp_conflict_id'||v_order_by USING in_imp_conflict_id;
END;  		


PROCEDURE acceptConflict(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_conflict_id	IN	IMP_CONFLICT_VAL.imp_conflict_id%TYPE,			
	in_imp_val_id		IN	IMP_CONFLICT_VAL.imp_val_id%TYPE,			
	in_accept			IN	IMP_CONFLICT_VAL.ACCEPT%TYPE
)
AS 	
	v_imp_session_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT imp_session_sid INTO v_imp_session_sid 
	  FROM IMP_CONFLICT
	 WHERE imp_conflict_id = in_imp_conflict_id;
	  
	-- check permission on session	   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_imp_session_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	   		  
	
	UPDATE IMP_CONFLICT_VAL 
	   SET ACCEPT = in_accept
	 WHERE imp_conflict_id = in_imp_conflict_id
	   AND imp_val_id = in_imp_val_id;	
END; 

PROCEDURE getSessionFilesList( 
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	in_order_by			IN	VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_conflicts			NUMBER;
BEGIN
	getSessionFilesList(in_act_id,in_imp_session_sid,in_order_by,v_conflicts,out_cur);
END;


PROCEDURE getSessionFilesList( 
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID,			
	in_order_by			IN	VARCHAR2,
	out_conflicts		OUT NUMBER,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_order_by	VARCHAR2(1000);
BEGIN
	-- check permission on session	   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_imp_session_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	   
		
	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'file_upload_sid,filename');
		v_order_by := ' ORDER BY ' || in_order_by;
	END IF;
	
	SELECT COUNT(*) 
	   INTO out_conflicts
	   FROM IMP_CONFLICT 
	   WHERE imp_session_sid = in_imp_session_sid;
	
	OPEN out_cur FOR
		'SELECT FILE_UPLOAD_SID, FILENAME '|| 
		   'FROM FILE_UPLOAD '||
		   'WHERE PARENT_SID = :in_imp_session_sid'||v_order_by USING in_imp_session_sid;	
END; 

-- get region + indicator info incl mapping as list

PROCEDURE getFileInfoList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_file_sid			IN	security_pkg.T_SID_ID,
	in_info_type		IN	VARCHAR2,			
	in_order_by			IN	VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_order_by	VARCHAR2(1000);
BEGIN
	-- check permission on file   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_file_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	   
		
	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'imp_id,description,maps_to_sid,maps_to_description,'||
			'min_start_dtm,min_start_dtm_formatted,max_end_dtm,max_end_dtm_formatted');
		v_order_by := ' ORDER BY ' || in_order_by;
	END IF;
	
	-- pull out relevant info on file	
	IF in_info_type = 'indicator' THEN	
		OPEN out_cur FOR    
			'SELECT II.IMP_IND_ID IMP_ID, II.DESCRIPTION, II.MAPS_TO_IND_SID MAPS_TO_SID, indicator_pkg.INTERNAL_GetIndPathString(I.IND_SID) MAPS_TO_DESCRIPTION, '||
				'indicator_pkg.INTERNAL_GetIndPathString(I.IND_SID) MAPS_TO_PATH, '||
				'MIN(START_DTM) MIN_START_DTM, TO_CHAR(MIN(START_DTM),''Mon YYYY'') MIN_START_DTM_FORMATTED, '||
				'MAX(END_DTM) MAX_END_DTM, TO_CHAR(MAX(END_DTM),''Mon YYYY'') MAX_END_DTM_FORMATTED '|| 
			  'FROM IMP_VAL IV, IMP_IND II, IND I '||
			 'WHERE file_sid = :in_file_sid '||
			   'AND IV.IMP_IND_ID = II.IMP_IND_ID '||
			   'AND II.MAPS_TO_IND_SID = I.IND_SID(+) '|| 
			 'GROUP BY II.IMP_IND_ID, II.DESCRIPTION, II.MAPS_TO_IND_SID, indicator_pkg.INTERNAL_GetIndPathString(I.IND_SID)'||v_order_by USING in_file_sid;
	ELSE -- default to region   
		OPEN out_cur FOR    
			'SELECT IR.IMP_REGION_ID IMP_ID, IR.DESCRIPTION, IR.MAPS_TO_REGION_SID MAPS_TO_SID, '||
				'CASE WHEN r.lookup_key is null then R.DESCRIPTION else r.description||'' - [''||r.lookup_key||'']'' end MAPS_TO_DESCRIPTION, '||
				'region_pkg.INTERNAL_GetRegionPathString(r.region_sid) MAPS_TO_PATH, '||
				'MIN(START_DTM) MIN_START_DTM, TO_CHAR(MIN(START_DTM),''Mon YYYY'') MIN_START_DTM_FORMATTED, '||
				'MAX(END_DTM) MAX_END_DTM, TO_CHAR(MAX(END_DTM),''Mon YYYY'') MAX_END_DTM_FORMATTED '||
			  'FROM IMP_VAL IV, IMP_REGION IR, V$REGION R '|| 
			 'WHERE file_sid = :in_file_sid '||
			   'AND IV.IMP_REGION_ID = IR.IMP_REGION_ID '||
			   'AND IR.MAPS_TO_REGION_SID = R.REGION_SID(+) '||
			 'GROUP BY IR.IMP_REGION_ID, IR.DESCRIPTION, IR.MAPS_TO_REGION_SID, CASE WHEN r.lookup_key is null then R.DESCRIPTION else r.description||'' - [''||r.lookup_key||'']'' end,region_pkg.INTERNAL_GetRegionPathString(r.region_sid)'||v_order_by USING in_file_sid;
	END IF;
END;


PROCEDURE previewMerge(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_file_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permission on file   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_file_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on file with sid '||in_file_Sid);
	END IF;
	
	imp_pkg.SynchImpMeasures(security_pkg.getact, security_pkg.getapp);
	
	OPEN out_cur FOR
		SELECT maps_to_ind_sid, start_dtm, end_dtm,
			   maps_to_ind_description ind_description,
			   aggregate,
			   CASE
					WHEN aggregate IN ('SUM','FORCE SUM') THEN
					   SUM(
						   CASE
							  WHEN factor_a IS NULL THEN val
							  ELSE factor_a * POWER(val, factor_b) + factor_c
						   END) 
					ELSE null -- 'force down and 'down' don't make any sense in the preview (I guess it might if only one region were imported but that's just tough)
			   END val,
			   measure_description,
			   MIN(from_measure_description) from_measure_description,
			   format_mask, 
			   indicator_pkg.INTERNAL_GetIndPathString(maps_to_ind_sid) ind_path
		  FROM v$imp_merge
		 WHERE file_sid = in_file_sid
		 GROUP BY start_dtm, end_dtm, maps_to_ind_sid, measure_description, maps_to_ind_description, 
			format_mask, aggregate
		 ORDER BY ind_description, maps_to_ind_sid, start_dtm;
END;           

-- "unmerge"
PROCEDURE RemoveMergedData(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_imp_session_sid			IN	security_pkg.T_SID_ID
)
AS
	v_locked_data_rows_count	NUMBER;
	v_lock_start				DATE;
	v_lock_end					DATE;
BEGIN
	-- check permission on file
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_imp_session_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- get the start and end dates for the locked date range.
	SELECT lock_start_dtm, lock_end_dtm 
	  INTO v_lock_start, v_lock_end
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	-- See if there are any rows for the given session_sid that have data in the locked date range
	SELECT COUNT(*) 
	  INTO v_locked_data_rows_count
	  FROM IMP_VAL
	 WHERE imp_session_sid = in_imp_session_sid
	   AND set_val_id IS NOT NULL
	   AND start_dtm < v_lock_end
	   AND end_dtm > v_lock_start;

	IF v_locked_data_rows_count > 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_NOT_ALLOWED_WRITE, 'Cannot unmerge data for the period ('||TO_CHAR(v_lock_start,'Mon yyyy')||' to '||TO_CHAR(v_lock_end, 'Mon yyyy')||') is locked? See CUSTOMER.LOCK_START_DTM / LOCK_END_DTM.');
	END IF;

	-- delete all old values from this session
	FOR r IN (
		SELECT set_val_id
		  FROM IMP_VAL
		 WHERE imp_session_sid = in_imp_session_sid
		   AND set_val_id IS NOT NULL
	)
	LOOP
		indicator_pkg.DeleteVal(in_act_id, r.set_val_id, 'Remerging import session');
	END LOOP;

	-- delete all old metric values from this session
	FOR r IN (
		SELECT set_region_metric_val_id
		  FROM IMP_VAL
		 WHERE imp_session_sid = in_imp_session_sid
		   AND set_region_metric_val_id IS NOT NULL
	)
	LOOP
		--indicator_pkg.DeleteVal(in_act_id, r.set_val_id, 'Remerging import session');
		region_metric_pkg.DeleteMetricValue(r.set_region_metric_val_id);
	END LOOP;

 	UPDATE imp_session
 	   SET merged_dtm = NULL,
		   unmerged_dtm = SYSDATE
 	 WHERE imp_session_sid = in_imp_session_sid;
END;

PROCEDURE mergeWithMainData(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_imp_session_sid			IN	security_pkg.T_SID_ID
)
AS
	v_set_val_id		IMP_VAL.set_val_id%TYPE;	
    v_app_sid			security_pkg.T_SID_ID;
BEGIN	
	-- RemoveMergedData does a security check for us
	RemoveMergedData(in_act_id, in_imp_session_sid);
	
    SELECT app_sid 
      INTO v_app_sid 
      FROM imp_session
     WHERE imp_session_sid = in_imp_session_sid;
     
	-- this won't merge stuff with conflicts!
    FOR r IN (
     	SELECT imp_val_id, start_dtm, end_dtm,
                CASE
                   WHEN factor_a IS NULL THEN val
                   ELSE factor_a * POWER(val, factor_b) + factor_c
                 END val,
                 CASE
                   WHEN factor_a IS NULL THEN NULL
                   ELSE val
                 END entry_val, maps_to_region_sid, maps_to_ind_sid, rid,
                maps_to_measure_conversion_id, note, is_text_ind,
                is_region_metric, measure_description, from_measure_description, ind_description, region_description
            FROM v$imp_merge
           WHERE imp_session_sid = in_imp_session_sid
  	)
  	LOOP
		IF r.is_region_metric = 1 THEN
			-- base unit
			IF r.maps_to_measure_conversion_id IS NULL THEN
				region_metric_pkg.SetMetricValue(r.maps_to_region_sid, r.maps_to_ind_sid, r.start_dtm, r.val, r.note, null, r.maps_to_measure_conversion_id, NULL, v_set_val_id);
			-- conversion unit
			ELSIF r.maps_to_measure_conversion_id = r.maps_to_measure_conversion_id THEN
				region_metric_pkg.SetMetricValue(r.maps_to_region_sid, r.maps_to_ind_sid, r.start_dtm, r.entry_val, r.note, null, r.maps_to_measure_conversion_id, NULL, v_set_val_id);
			END IF;
			UPDATE imp_val
			   SET set_region_metric_val_id	= v_set_val_id
			 WHERE ROWID = r.RID;
		ELSE
			IF r.is_text_ind = 1 THEN
				Indicator_Pkg.SetValue(in_act_id, r.maps_to_ind_sid, r.maps_to_region_sid, r.start_dtm, r.end_dtm, null, 0, 
					csr_data_pkg.SOURCE_TYPE_IMPORT, r.imp_val_id, 	r.maps_to_measure_conversion_id, r.entry_val, 
					  0, NVL(r.note, TO_CHAR(r.val)), v_set_val_id);
			ELSE
				Indicator_Pkg.SetValue(in_act_id, r.maps_to_ind_sid, r.maps_to_region_sid, r.start_dtm, r.end_dtm, r.val, 0, 
					csr_data_pkg.SOURCE_TYPE_IMPORT, r.imp_val_id, 	r.maps_to_measure_conversion_id, r.entry_val, 
					  0, r.note, v_set_val_id);
			END IF;
	        IF v_set_val_Id = -1 THEN
				RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_NOT_ALLOWED_WRITE, 'Cannot merge data -- possibly data for the period ('||TO_CHAR(r.start_dtm,'Mon yyyy')||' to '||TO_CHAR(r.end_dtm, 'Mon yyyy')||' is locked? See CUSTOMER.LOCK_START_DTM / LOCK_END_DTM.');
	        END IF;
	 		UPDATE imp_val 
	 		   SET set_val_id = v_set_val_id 
	 		 WHERE ROWID = r.RID;
		END IF;
  	END LOOP;
 	UPDATE imp_session
 	   SET merged_dtm = SYSDATE,
	       unmerged_dtm = NULL
 	 WHERE imp_session_sid = in_imp_session_sid;
END;

PROCEDURE GetUnmappedValues  (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_imp_session_sid			IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)	
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_imp_session_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT imp_val_id 
		  FROM imp_val iv, imp_ind ii, imp_region ir
 		 WHERE iv.imp_ind_id = ii.imp_ind_id
 		   AND iv.imp_region_id = ir.imp_region_id
		   AND ii.ignore = 0 
           AND ir.ignore = 0
           AND imp_session_sid = in_imp_session_sid
		MINUS
		SELECT imp_val_id 
		  FROM v$imp_val_mapped 
		 WHERE imp_session_sid = in_imp_session_sid;
END;



PROCEDURE getFileUpload(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_val_id		IN	imp_val.imp_val_id%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_file_upload_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT file_sid INTO v_file_Upload_sid FROM imp_val WHERE imp_val_id = in_imp_val_id;
	fileupload_pkg.GetFileUpload(in_act_id, v_file_upload_sid, out_cur);
END;

FUNCTION autoMapRegion(
	in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	imp_session.app_sid%TYPE,
	in_description		IN	imp_region.description%TYPE
)
RETURN region.region_sid%TYPE 
AS
	v_found_region_sid 	region.region_sid%TYPE;
	--
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_region_sid 		region.region_sid%TYPE;
	v_parent_sid 		region.parent_sid%TYPE;
	v_name 				region.name%TYPE;
	v_description 		region_description.description%TYPE;
	v_active 			region.active%TYPE;
	v_pos 				region.pos%TYPE;
	v_geo_latitude 		region.geo_latitude%TYPE;
	v_geo_longitude	 	region.geo_longitude%TYPE;
	v_geo_country 		region.geo_country%TYPE;
	v_geo_region		region.geo_region%TYPE;
	v_geo_city_id 		region.geo_city_id%TYPE;
	v_map_entity 		region.map_entity%TYPE;
	v_egrid_ref	 		region.egrid_ref%TYPE;
	v_geo_type 			region.geo_type%TYPE;
	v_region_type 		region.region_type%TYPE;
	v_lookup_key		region.lookup_key%TYPE;
	v_region_ref		region.region_ref%TYPE;
	v_disposal_dtm 		region.disposal_dtm%TYPE;
	v_acquisition_dtm	region.acquisition_dtm%TYPE;
	v_cnt				NUMBER(10);
BEGIN
	-- check for direct match on lookup_key
	SELECT MAX(region_sid), COUNT(region_sid)
	  INTO v_region_sid, v_cnt
	  FROM region
	 WHERE UPPER(lookup_key) = ltrim(UPPER(in_description),'0') -- strip trailing zeros
	   AND active=1;
	 
	IF v_cnt = 1 THEN
		RETURN v_region_Sid;
	END IF;
	
	-- check for direct match on region_ref
	-- Note; doing this separately (rather than an or, above) to ensure we don't break any existing functionality.
	-- If a region has a region_ref matching a different region's lookup key, it would break.
	SELECT MAX(region_sid), COUNT(region_sid)
	  INTO v_region_sid, v_cnt
	  FROM region
	 WHERE UPPER(region_ref) = UPPER(in_description)
	   AND active=1;
	 
	IF v_cnt = 1 THEN
		RETURN v_region_Sid;
	END IF;
	
	-- Trying by description
	SELECT MAX(region_sid), COUNT(region_sid)
	  INTO v_region_sid, v_cnt
	  FROM v$region
	 WHERE UPPER(description) = UPPER(in_description)
	   AND active=1;

	IF v_cnt = 1 THEN
		RETURN v_region_Sid;
	END IF;

	IF INSTR(in_description, '/') = 0 THEN
		-- If user doesn't pass a path we are done here
		RETURN NULL;
	END IF;

	-- Trying by path
	region_pkg.FindRegionPath(in_act, in_app_sid, in_description, '/', v_cur);
		
	FETCH v_cur INTO v_region_sid, v_parent_sid, v_name, v_description, v_active, v_pos,
		v_geo_latitude, v_geo_longitude, v_geo_country, v_geo_region, 
		v_geo_city_id, v_map_entity, v_egrid_ref, v_geo_type, v_region_type, v_disposal_dtm, v_acquisition_dtm, v_lookup_key, v_region_ref;
		
	IF v_cur%FOUND THEN
		v_found_region_sid := v_region_sid;
		-- try and get another 
		FETCH v_cur INTO v_region_sid, v_parent_sid, v_name, v_description, v_active, v_pos,
			v_geo_latitude, v_geo_longitude, v_geo_country, v_geo_region, 
			v_geo_city_id, v_map_entity, v_egrid_ref, v_geo_type, v_region_type, v_disposal_dtm, v_acquisition_dtm, v_lookup_key, v_region_ref;
		IF v_cur%NOTFOUND THEN
			-- nothing found so just one match!! hurrah!
			RETURN v_region_sid;
		END IF;
	END IF;
	
	-- dupe matches or not found
	RETURN NULL;
END;


PROCEDURE autoMapRegions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	out_auto_mapped		OUT NUMBER
)	   
AS 
	v_app_sid		security_pkg.T_SID_ID;
	v_maps_to_sid	security_pkg.T_SID_ID;
BEGIN
	out_auto_mapped := 0;
	-- check permission on file   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_imp_session_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	SELECT app_sid
	  INTO v_app_sid
	  FROM imp_session
	 WHERE imp_session_sid = in_imp_session_sid;
	 
	
	
	-- It's one at a time as the plans were a bit loopy (full scan of imp_val running autoMapRegion on each row)
	FOR r IN (
		SELECT DISTINCT ir.imp_region_id, ir.description
		  FROM imp_val iv
		  JOIN imp_region ir ON iv.imp_region_id = ir.imp_region_id AND iv.app_sid = ir.app_sid 
		  LEFT JOIN region r ON ir.maps_to_region_sid = r.region_sid AND ir.app_sid = r.app_sid
		 WHERE imp_session_sid = in_imp_session_sid 
		   AND (ir.maps_to_region_sid IS NULL OR r.active = 0) -- inactive regions are fair game - FB59802
	) 
	LOOP
		v_maps_to_sid := null;
		-- try the ID if descriptiion is a number
		BEGIN
			SELECT MIN(region_sid)
			  INTO v_maps_to_sid
			  FROM region
			 WHERE region_sid = TO_NUMBER(r.description, '9999999999');
		EXCEPTION
			WHEN VALUE_ERROR THEN
				v_maps_to_sid := NULL;
			WHEN INVALID_NUMBER THEN
				v_maps_to_sid := NULL;
		END;
		IF v_maps_to_sid IS NULL THEN
			v_maps_to_sid := autoMapRegion(in_act_id, v_app_sid, r.description);
		END IF;
		IF v_maps_to_sid IS NOT NULL THEN
		    UPDATE imp_region 
		       SET maps_to_region_sid = v_maps_to_sid
		     WHERE imp_region_id = r.imp_region_id;
		     
			out_auto_mapped := out_auto_mapped + 1;
		END IF;
	END LOOP;

	insertConflicts(in_act_id, in_imp_session_sid);
END;    

FUNCTION findIndicatorSid(
	in_description		IN	imp_ind.description%TYPE
)
RETURN ind.ind_sid%TYPE 
AS
	v_cur					security_pkg.T_OUTPUT_CUR;
	v_ind_sid				ind.ind_sid%TYPE;
	v_description 			ind_description.description%TYPE;
	v_cnt					NUMBER(10);

BEGIN

	-- Trying by ID
	BEGIN
		SELECT MIN(ind_sid)
		  INTO v_ind_sid
		  FROM ind
		 WHERE ind_sid = TO_NUMBER(in_description, '9999999999')
		   AND ind_type = csr_data_pkg.IND_TYPE_NORMAL;
	EXCEPTION
		WHEN VALUE_ERROR THEN
			v_ind_sid := NULL;
		WHEN INVALID_NUMBER THEN
			v_ind_sid := NULL;
	END;

	IF v_ind_sid IS NOT NULL THEN
		RETURN v_ind_sid;
	END IF;

	-- Trying by lookup_key
	SELECT MAX(ind_sid), COUNT(ind_sid)
	  INTO v_ind_sid, v_cnt
	  FROM ind
	 WHERE UPPER(lookup_key) = ltrim(UPPER(in_description),'0') -- strip trailing zeros
	   AND active=1
	   AND measure_sid IS NOT NULL
	   AND ind_type = csr_data_pkg.IND_TYPE_NORMAL;

	IF v_cnt = 1 THEN
		RETURN v_ind_sid;
	END IF;

	-- Trying by description
	SELECT MAX(ind_sid), COUNT(ind_sid)
	  INTO v_ind_sid, v_cnt
	  FROM v$ind i
	 WHERE UPPER(i.description) = UPPER(in_description)
	   AND active = 1
	   AND i.measure_sid IS NOT NULL
	   AND i.ind_type = csr_data_pkg.IND_TYPE_NORMAL;

	IF v_cnt = 1 THEN
		RETURN v_ind_sid;
	END IF;

	IF INSTR(in_description, '/') = 0 THEN
		-- If user doesn't pass a path we are done here
		RETURN NULL;
	END IF;

	-- Trying by path
	indicator_pkg.FindIndicatorByPath(
		in_path => in_description,
		out_cur => v_cur
	);

	FETCH v_cur INTO v_ind_sid, v_description;

	IF v_cur%FOUND THEN
		-- Try and get another 
		FETCH v_cur INTO v_ind_sid, v_description;
		IF v_cur%NOTFOUND THEN
			-- nothing found so just one match
			RETURN v_ind_sid;
		END IF;
	END IF;

	-- Dupe matches or not found
	RETURN NULL;
END;


PROCEDURE autoMapInds(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	out_auto_mapped		OUT NUMBER
)
AS
	v_maps_to_sid	security_pkg.T_SID_ID;
BEGIN
	out_auto_mapped := 0;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_imp_session_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- Iterate all unmapped indicators
	FOR r IN (
		SELECT DISTINCT ii.imp_ind_id, ii.description
		  FROM imp_val iv
		  JOIN imp_ind ii ON iv.imp_ind_id = ii.imp_ind_id
		   AND iv.app_sid = ii.app_sid
		 WHERE iv.imp_session_sid = in_imp_session_sid 
		   AND ii.maps_to_ind_sid IS NULL)
	LOOP

		v_maps_to_sid := findIndicatorSid(r.description);

		IF v_maps_to_sid IS NOT NULL THEN
			UPDATE imp_ind
			   SET maps_to_ind_sid = v_maps_to_sid
			 WHERE imp_ind_id = r.imp_ind_id;

			out_auto_mapped := out_auto_mapped + 1;
		END IF;
	END LOOP;

	insertConflicts(in_act_id, in_imp_session_sid);
END;

PROCEDURE RemoveDupeValConflicts(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- check permission on file   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_imp_session_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	 -- get rid of any nulls or zeros involved in conflicts
	FOR r IN (
			SELECT icv.imp_conflict_id, icv.imp_val_id
			  FROM imp_conflict IC
				JOIN imp_conflict_val icv ON ic.imp_conflict_id = icv.imp_conflict_id
				JOIN imp_val iv ON icv.imp_val_id = IV.imp_val_id
			 WHERE ic.imp_session_sid = in_imp_session_sid
			   AND NVL(iv.val,0) = 0
	)
	LOOP
		DELETE FROM imp_conflict_val
		  WHERE imp_conflict_id = r.imp_conflict_id 
		     AND imp_val_id = r.imp_val_id;
		 
		-- remove the underlying value too
		DELETE FROM imp_val
		 WHERE imp_val_id = r.imp_val_id;
	 END LOOP;
	 
	-- get rid of any dupe conflicts
	 FOR r IN (  
			SELECT imp_conflict_id, imp_measure_id, imp_val_id
			  FROM (
				SELECT icv.imp_conflict_id, icv.imp_val_id, iv.val, iv.imp_measure_id, 
					ROW_NUMBER() OVER (PARTITION BY icv.imp_conflict_id, iv.imp_measure_id, iv.val ORDER BY icv.imp_conflict_id, iv.val) RN
				  FROM imp_conflict IC
					JOIN imp_conflict_val icv ON ic.imp_conflict_id = icv.imp_conflict_id
					JOIN imp_val iv ON icv.imp_val_id = IV.imp_val_id
				 WHERE ic.imp_session_sid = in_imp_session_sid
				)
			WHERE RN > 1
	 )
	 LOOP
		DELETE FROM imp_conflict_val
		  WHERE imp_conflict_id = r.imp_conflict_id 
		     AND imp_val_id = r.imp_val_id;
		 
		-- remove the underlying value too
		DELETE FROM imp_val
		 WHERE imp_val_id = r.imp_val_id;
	 END LOOP;
	
	    
	-- TIDY UP?    
	FOR R IN (
		SELECT ic.imp_conflict_id
		  FROM imp_conflict IC
			LEFT JOIN imp_conflict_val ICV ON ic.imp_conflict_id = icv.imp_conflict_id            
		 WHERE ic.IMP_SESSION_SID = in_imp_session_sid
		 GROUP BY ic.imp_conflict_id
		HAVING COUNT(icv.imp_conflict_id) <= 1		
	)
	LOOP
		DELETE FROM imp_conflict_val
		 WHERE imp_conflict_id = r.imp_conflict_id;
		DELETE FROM imp_conflict
		 WHERE imp_conflict_id = r.imp_conflict_id;
	END LOOP;	
END;


PROCEDURE SumConflicts(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID
)
AS
	CURSOR cToDelete(in_imp_conflict_id IMP_CONFLICT.imp_conflict_id%TYPE) IS
    	SELECT imp_val_id FROM IMP_CONFLICT_VAL WHERE IMP_CONFLICT_ID = in_imp_conflict_id;
    rToDelete	cToDelete%ROWTYPE;
BEGIN
	-- check permission on file   	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_imp_session_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- synch measures first
	imp_pkg.SynchImpMeasures(security_pkg.getact, security_pkg.getapp);
	
	FOR r IN (
		SELECT iv.imp_conflict_id, 
			   SUM(iv.factor_a * POWER(iv.val, iv.factor_b) + iv.factor_c) VAL, 
			   iv.start_dtm, iv.end_dtm, stragg(iv.note) notes,
			   MAX(iv.file_sid) file_sid, iv.imp_session_sid, MIN(iv.imp_ind_id) imp_ind_id, MIN(iv.imp_region_id) imp_region_id
		  FROM v$imp_val_mapped iv
		 WHERE iv.imp_conflict_id IS NOT NULL
		   AND iv.imp_session_sid = in_imp_session_sid
		 GROUP BY iv.imp_conflict_id, iv.start_dtm, iv.end_dtm, iv.imp_session_sid, iv.maps_to_ind_sid, iv.maps_to_region_sid
	)
	LOOP
        -- grab a list of stuff to delete
        OPEN cToDelete(r.imp_conflict_id);
		-- delete the conflict (need to do this first because of integrity constraints)
		DELETE FROM IMP_CONFLICT_VAL WHERE imp_conflict_id = r.imp_conflict_id;
		DELETE FROM IMP_CONFLICT WHERE imp_conflict_id = r.imp_conflict_id;
		-- delete the conflicting values
        WHILE TRUE 
        LOOP
        	FETCH cToDelete INTO rToDelete;
            EXIT WHEN cToDelete%NOTFOUND;
            DELETE FROM IMP_VAL WHERE imp_val_id = rToDelete.imp_Val_id;
        END LOOP;
        CLOSE cToDelete;
		-- insert a new value which represents the sum of the conlficts
		INSERT INTO IMP_VAL 
			(imp_val_id, IMP_IND_ID, IMP_REGION_ID, Unknown, START_DTM, END_DTM, VAL, A, B, C, FILE_SID, IMP_SESSION_SID, note)
		VALUES
			(imp_val_id_seq.NEXTVAL, r.imp_ind_id, r.imp_region_id, NULL, r.start_dtm, r.end_dtm, r.VAL, NULL, NULL, NULL, r.file_sid, r.imp_session_sid, r.notes);		
	END LOOP;
END;

-- XXX: only used by RWE
-- via:
-- c:\cvs\fproot\App_Code\Clients\RWE\DatabaseMerge.cs - (43, 20) : public DataSet GetConflict()
-- c:\cvs\clients\rwe-ps\web\site\import\ExcelUpload.ashx - (66, 45) : DataSet dataSet = databaseMerge.GetConflict();
PROCEDURE GetDifferences(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	
BEGIN
	-- check permission on imp session
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_imp_session_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT iv.imp_val_id import_val_id, iv.val import_val, v.entry_val_number db_val, ii.maps_to_ind_sid, ir.maps_to_region_sid,
		  	   i.description ind_description, r.description region_description, iv.start_dtm, iv.end_dtm,
		  	   LTRIM(indicator_pkg.INTERNAL_GetIndPathString(i.ind_sid),'Indicators / ') ind_path, 
		   	   LTRIM(region_pkg.INTERNAL_GetRegionPathString(r.region_sid),'Regions / ') region_path
		  FROM imp_val iv 
		  JOIN imp_ind ii ON iv.imp_ind_id = ii.imp_ind_id
		  JOIN imp_region ir ON iv.imp_region_id = ir.imp_region_id
		  JOIN v$ind i ON ii.maps_to_ind_sid = i.ind_sid
		  JOIN v$region r ON ir.maps_to_region_sid = r.region_sid
		  JOIN val v ON iv.start_dtm = v.period_start_dtm  
		   AND iv.end_dtm = v.period_end_dtm 
		   AND ii.maps_to_ind_sid = v.ind_sid 
		   AND ir.maps_to_region_sid = v.region_sid
		 WHERE iv.val != v.entry_val_number
		   AND iv.imp_session_sid = in_imp_session_sid;
END;

PROCEDURE DeleteImportValue(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	in_imp_val_ids		IN	security_pkg.T_SID_IDS
)
AS

BEGIN
	-- check permission on imp session
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_imp_session_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	FORALL i IN INDICES OF in_imp_val_ids
		DELETE FROM imp_val iv
		 WHERE iv.imp_val_id = in_imp_val_ids(i);
END;

FUNCTION Varchar2ArrayToTable(
	in_varchars				IN T_VARCHAR2_ARRAY
) RETURN T_VARCHAR2_TABLE
AS 
	v_table 	T_VARCHAR2_TABLE := T_VARCHAR2_TABLE();
BEGIN
    IF in_varchars.COUNT = 0 OR (in_varchars.COUNT = 1 AND in_varchars(1) IS NULL) THEN
        -- hack for ODP.NET which doesn't support empty arrays - just return nothing
		RETURN v_table;
    END IF;

	FOR i IN in_varchars.FIRST .. in_varchars.LAST
	LOOP
		BEGIN
			v_table.extend;
			v_table(v_table.COUNT) := in_varchars(i);
		END;
	END LOOP;
	RETURN v_table;
END;

PROCEDURE GetIndName(
	dummy				IN security_pkg.T_ACT_ID,
	in_raw_ind_names	IN T_VARCHAR2_ARRAY,
	out_ind_name		OUT security_pkg.T_OUTPUT_CUR
)
AS

	ind_names T_VARCHAR2_TABLE;

BEGIN
	ind_names := Varchar2ArrayToTable(in_raw_ind_names);
	
	OPEN out_ind_name FOR
		SELECT n.column_value, i.name, i.ind_sid
		  FROM IMP_IND ii
		  JOIN IND i ON ii.maps_to_ind_sid = i.ind_sid
		 RIGHT JOIN TABLE(ind_names) n ON ii.description = n.column_value;
END;

PROCEDURE GetRegionName(
	dummy				IN security_pkg.T_ACT_ID,
	in_raw_region_names	IN T_VARCHAR2_ARRAY,
	out_region_name		OUT security_pkg.T_OUTPUT_CUR
)
AS

	region_names T_VARCHAR2_TABLE;

BEGIN
	region_names := Varchar2ArrayToTable(in_raw_region_names);
	
	OPEN out_region_name FOR
		SELECT n.column_value, r.name, r.region_sid
		  FROM IMP_REGION ir
		  JOIN REGION r ON ir.maps_to_region_sid = r.region_sid
		 RIGHT JOIN TABLE(region_names) n ON ir.description = n.column_value;
END;

PROCEDURE AddNewImportIndicator(
	in_ind_description		IN VARCHAR2,
	in_ind_sid				IN security_pkg.T_SID_ID
)
AS

	CURSOR cI IS
		SELECT * FROM IMP_IND ii
		 WHERE ii.description = in_ind_description
	FOR UPDATE;
	rI cI%ROWTYPE; 

BEGIN

	OPEN cI;
	FETCH cI INTO rI;
	IF cI%NOTFOUND THEN
		INSERT INTO IMP_IND (imp_ind_id, description, maps_to_ind_sid, ignore)
			VALUES (imp_ind_id_seq.nextval, in_ind_description, in_ind_sid, 0);
	ELSE
		UPDATE IMP_IND SET maps_to_ind_sid = in_ind_sid
			WHERE CURRENT OF cI;
	END IF;
	CLOSE cI;
		
END;

PROCEDURE AddNewImportRegion(
	in_region_description		IN VARCHAR2,
	in_region_sid				IN security_pkg.T_SID_ID
)
AS

	CURSOR cR IS
		SELECT * FROM IMP_REGION ir
		 WHERE ir.description = in_region_description
	FOR UPDATE;
	rR cR%ROWTYPE; 

BEGIN

	OPEN cR;
	FETCH cR INTO rR;
	IF cR%NOTFOUND THEN
		INSERT INTO IMP_REGION (imp_region_id, description, maps_to_region_sid, ignore)
		VALUES (imp_region_id_seq.nextval, in_region_description, in_region_sid, 0);
	ELSE
		UPDATE IMP_REGION SET maps_to_region_sid = in_region_sid
		 WHERE CURRENT OF cR;
	END IF;
	CLOSE cR;
		
END;

PROCEDURE AddNewImportMeasure(
	in_measure_description		IN VARCHAR2,
	in_measure_sid				IN security_pkg.T_SID_ID,
	in_measure_conversion_id	IN security_pkg.T_SID_ID,
	in_indicator_description	IN VARCHAR2
)
AS

	CURSOR cM IS
		SELECT * FROM IMP_MEASURE im
		 WHERE LOWER(im.description) = LOWER(in_measure_description)
	FOR UPDATE;
	rM cM%ROWTYPE; 

BEGIN

	OPEN cM;
	FETCH cM INTO rM;
	IF cM%NOTFOUND THEN
		INSERT INTO IMP_MEASURE (imp_measure_id, description, maps_to_measure_sid, maps_to_measure_conversion_id, imp_ind_id)
			SELECT
				imp_measure_id_seq.nextval,
				in_measure_description,
				in_measure_sid,
				in_measure_conversion_id,
				ii.imp_ind_id
			  FROM
				IMP_IND ii
			 WHERE
				ii.description = in_indicator_description;
	ELSE
		UPDATE IMP_MEASURE
		   SET
			maps_to_measure_sid = in_measure_sid,
			maps_to_measure_conversion_id = in_measure_conversion_id,
			imp_ind_id = (
				SELECT ii.imp_ind_id
				  FROM IMP_IND ii
				 WHERE ii.description = in_indicator_description
			)
		 WHERE CURRENT OF cM;
	END IF;
	CLOSE cM;
		
END;

PROCEDURE AddNewValue(
	in_imp_session_sid			IN	security_pkg.T_SID_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_ind_description			IN	VARCHAR2,
	in_region_description		IN	VARCHAR2,
	in_measure_description		IN	VARCHAR2,
	in_unknown					IN 	IMP_VAL.unknown%TYPE,
	in_start_dtm				IN 	IMP_VAL.start_dtm%TYPE,
	in_end_dtm					IN 	IMP_VAL.end_dtm%TYPE,
	in_file_sid					IN 	IMP_VAL.file_sid%TYPE,
	in_val						IN 	IMP_VAL.VAL%TYPE
)
AS
	v_a		IMP_VAL.a%type;
	v_b		IMP_VAL.b%type;
	v_c		IMP_VAL.c%type;
	v_id	security_pkg.T_SID_ID;
	v_count NUMBER(10);
BEGIN
	
	SELECT im.maps_to_measure_conversion_id
	  INTO v_id
	  FROM IMP_MEASURE im
	 WHERE LOWER(im.description) = LOWER(in_measure_description);
	
	IF v_id IS NULL THEN
		v_a := NULL;
		v_b:= NULL;
		v_c := NULL;
	ELSE
		SELECT COUNT(*)
		  INTO v_count
		  FROM MEASURE_CONVERSION_PERIOD mcp
		  JOIN IMP_MEASURE im ON mcp.measure_conversion_id = im.maps_to_measure_conversion_id
		 WHERE mcp.start_dtm <= in_start_dtm
		   AND (mcp.end_dtm > in_start_dtm OR mcp.end_dtm IS NULL);
		   
		IF v_count = 0 THEN
			SELECT mc.a, mc.b, mc.c
			  INTO v_a, v_b, v_c
			  FROM MEASURE_CONVERSION mc
			  JOIN IMP_MEASURE im ON mc.measure_conversion_id = im.maps_to_measure_conversion_id
			 WHERE im.description = in_measure_description;
		ELSE
			 SELECT mcp.a, mcp.b, mcp.c
			  INTO v_a, v_b, v_c
			  FROM MEASURE_CONVERSION_PERIOD mcp
			  JOIN IMP_MEASURE im ON mcp.measure_conversion_id = im.maps_to_measure_conversion_id
			 WHERE mcp.start_dtm <= in_start_dtm
			   AND (mcp.end_dtm > in_start_dtm OR mcp.end_dtm IS NULL);
		END IF;
	END IF;
	
	INSERT INTO IMP_VAL 
		(imp_val_id, imp_ind_id, imp_region_id, imp_measure_id, unknown, start_dtm, end_dtm, VAL, a, b, c, file_sid, imp_session_sid)
	VALUES (
		imp_val_id_seq.NEXTVAL,
		(
			SELECT ii.imp_ind_id
			  FROM IMP_IND ii
			 WHERE ii.description = in_ind_description
		),
		(
			SELECT ir.imp_region_id
			  FROM IMP_REGION ir
			 WHERE ir.description = in_region_description
		),
		(
			SELECT im.imp_measure_id
			  FROM IMP_MEASURE im
			 WHERE im.description = in_measure_description
		),
		in_unknown,
		in_start_dtm,
		in_end_dtm,
		in_val,
		v_a, v_b, v_c,
		in_file_sid,
		in_imp_session_sid
	);
END;

PROCEDURE GetMeasures(
	in_ind_sids			IN security_pkg.T_SID_IDS,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
IS
    t security.T_SID_TABLE;
BEGIN
    t := security_pkg.SidArrayToTable(in_ind_sids);
    
	OPEN out_cur FOR
		SELECT i.ind_sid AS indicator_sid, mc.description AS measure, mc.measure_sid, mc.measure_conversion_id
		  FROM measure_conversion mc
		  JOIN ind i ON mc.measure_sid = i.measure_sid
		 WHERE i.ind_sid IN (
				SELECT column_value ind_sid
				  FROM TABLE(t)
		)
		 UNION
		SELECT i.ind_sid AS indicator_sid, m.description AS measure, m.measure_sid, null
		  FROM measure m
		  JOIN ind i on m.measure_sid = i.measure_sid
		 WHERE i.ind_sid IN (
				SELECT column_value ind_sid
				  FROM TABLE(t)
		);
END;

PROCEDURE AutoParseSession(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_imp_session_sid		IN imp_session.imp_session_sid%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_imp_session_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	UPDATE imp_session
	   SET parse_started_dtm = SYSDATE, parsed_dtm = SYSDATE
	 WHERE imp_session_sid = in_imp_session_sid;
END;

PROCEDURE RefreshAllConflicts
AS
BEGIN
	DELETE FROM imp_conflict_val
	 WHERE app_sid = security_pkg.getApp;

	DELETE FROM imp_conflict
	 WHERE app_sid = security_pkg.getApp;

	FOR r IN (
		SELECT imp_session_sid 
		  FROM imp_session 
		 WHERE app_sid = security_pkg.getApp
	)
	LOOP
		imp_pkg.insertConflicts(security_pkg.getact, r.imp_session_sid);
	END LOOP;
END;

PROCEDURE GetMatchingDelegations(
	in_imp_session_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- XXX: security - check for some kind of write on top level Delegations node?
	OPEN out_cur FOR
		WITH top_delegation AS (
			SELECT d.delegation_sid
			  FROM delegation d
			  JOIN delegation_ind di ON d.app_sid = di.app_sid AND d.delegation_sid = di.delegation_sid
			  JOIN delegation_region dr ON d.app_sid = dr.app_sid AND d.delegation_sid = dr.delegation_sid
			 WHERE d.parent_sid = d.app_sid
			   AND (di.ind_sid, dr.region_sid) in (
					  SELECT ii.maps_to_ind_sid, ir.maps_to_region_sid
						FROM imp_val iv, imp_ind ii, imp_region ir
					   WHERE iv.app_sid = ii.app_sid AND iv.imp_ind_id = ii.imp_ind_id 
						 AND iv.app_sid = ir.app_sid AND iv.imp_region_id = ir.imp_region_id
						 AND iv.imp_session_sid = in_imp_session_sid
				   )
		)
		SELECT d.name, d.delegation_sid, d.editing_url, s.last_action_id, s.last_action_desc,
			   s.sheet_id, d.period_set_id, d.period_interval_id, s.start_dtm, s.end_dtm,
			   COUNT(*) OVER (PARTITION BY d.delegation_sid) deleg_match_cnt
		  FROM (
			SELECT delegation_sid, app_sid
			  FROM delegation
			 WHERE CONNECT_BY_ISLEAF = 1
			 START WITH delegation_sid IN (SELECT delegation_sid FROM top_delegation)
		   CONNECT BY PRIOR delegation_sid = parent_sid
			) lowest_delegation 
		  JOIN delegation d ON lowest_delegation.app_sid = d.app_sid AND lowest_delegation.delegation_sid = d.delegation_sid
		  JOIN sheet_with_last_action s ON d.app_sid = s.app_sid AND d.delegation_sid = s.delegation_sid
		 WHERE (s.start_dtm, s.end_dtm) in (
			SELECT iv.start_dtm, iv.end_dtm
			  FROM imp_val iv
			 WHERE iv.imp_session_sid = in_imp_session_sid
			)
		ORDER BY deleg_match_cnt, d.name, d.delegation_sid, s.start_dtm DESC;
END;

/*
* Copies data from data import session to the sheets of given delegations sids.
* Not to top delegations only as name suggests
*/
PROCEDURE MergeWithTopDelegSheets(
	in_imp_session_sid	IN	security_pkg.T_SID_ID,
	in_delegation_sids	IN	security_pkg.T_SID_IDS
)
AS
	v_val_id			NUMBER(10);
	t_delegation_sids 	security.T_SID_TABLE;
BEGIN
	--security_pkg.debugmsg('MergeWithTopDelegSheets');
	t_delegation_sids := security_pkg.SidArrayToTable(in_delegation_sids);
	FOR r IN (
		SELECT vim.imp_val_id, vim.start_dtm, vim.end_dtm,
				CASE
				   WHEN vim.factor_a IS NULL THEN val
				   WHEN vim.is_text_ind = 1 THEN NULL
				   ELSE vim.factor_a * POWER(vim.val, vim.factor_b) + vim.factor_c
				 END val,
				CASE
				   WHEN vim.factor_a IS NULL THEN NULL
				   WHEN vim.is_text_ind = 1 THEN NULL
				   ELSE vim.val
				 END entry_val, 
				vim.maps_to_region_sid, vim.maps_to_ind_sid,
				vim.maps_to_measure_conversion_id, 
				CASE 
				  WHEN vim.is_text_ind = 1 THEN NVL(vim.note, TO_CHAR(val))
				  ELSE vim.note
				 END note, 
				vim.is_text_ind,
				sv.sheet_id
			FROM v$imp_merge vim
				JOIN (
					SELECT d.delegation_sid, s.sheet_id, di.ind_sid, dr.region_sid, s.start_dtm, s.end_dtm
					  FROm delegation d
						JOIN sheet s on d.delegation_sid = s.delegation_sid and d.app_sid = s.app_sid
						JOIN delegation_ind di on d.delegation_sid = di.delegation_sid and d.app_sid = di.app_sid
						JOIN delegation_region dr on d.delegation_sid = dr.delegation_sid and d.app_sid = dr.app_sid
					   WHERE d.delegation_sid IN (
							SELECT column_value FROM TABLE(t_delegation_sids)
					   )
				)sv 
					ON vim.start_dtm = sv.start_dtm
					AND vim.end_dtm = sv.end_dtm
					AND vim.maps_to_ind_sid = sv.ind_sid
					AND vim.maps_to_region_sid = sv.region_sid
		   WHERE vim.imp_session_sid = in_imp_session_sid
	)
	LOOP
		--security_pkg.debugmsg('MergeWithTopDelegSheets sheet='||r.sheet_id||' val='||r.val||' note='||r.note);
		delegation_pkg.SaveValue(
			in_act_id				=> security_pkg.getact, 
			in_sheet_id				=> r.sheet_id, 
			in_ind_sid				=> r.maps_to_ind_sid, 
			in_region_sid			=> r.maps_to_region_sid, 
			in_val_number			=> r.val, 
			in_entry_conversion_id	=> r.maps_to_measure_conversion_id,
			in_entry_val_number		=> r.entry_val, 
			in_note					=> r.note, 
			in_reason				=> 'Import', 
			in_status				=> csr_data_pkg.SHEET_VALUE_ENTERED, 
			in_file_count			=> 0, 
			in_flag					=> null, 
			in_write_history		=> 1, 
			out_val_id				=> v_val_id);
	END LOOP;
END;

PROCEDURE GetVocab(
	in_all_user_vocab				IN NUMBER,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_imports_sid					imp_session.imp_session_sid%TYPE;
BEGIN

	v_imports_sid := securableobject_pkg.getSidFromPath(security_pkg.getACT, security_pkg.getApp, 'Imports');
	-- check permission on imports object
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_imports_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT iv.imp_tag_type_id tag_id, iv.phrase, itt.description tag, itt.means_ignore, 
			   COUNT(*) occurences, SUM(frequency) frequency -- we want distinct tag_id / phrases - may was well get this extra data in case we decide to do weightings later - only applies "across all users" as no pharase duplication for a single user
		  FROM imp_vocab iv
		  JOIN imp_tag_type itt ON iv.imp_tag_type_id = itt.imp_tag_type_id
		 WHERE iv.app_sid = security_pkg.GetApp 
		   AND iv.imp_tag_type_id <> 0 -- irrelevent
		   AND ((iv.csr_user_sid = security_pkg.GetSid) OR (in_all_user_vocab = 1))
		 GROUP BY iv.imp_tag_type_id, iv.phrase, itt.description, itt.means_ignore
		 ORDER BY phrase; -- just for efficient loading in c#
				
END;

PROCEDURE ClearUserVocab(
	in_csr_user_sid					IN csr_user.csr_user_sid%TYPE
)
AS
	v_imports_sid					imp_session.imp_session_sid%TYPE;
BEGIN

	v_imports_sid := securableobject_pkg.getSidFromPath(security_pkg.getACT, security_pkg.getApp, 'Imports');
	-- check permission on imports object
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_imports_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	DELETE FROM imp_vocab
	 WHERE app_sid = security_pkg.GetApp
	   AND csr_user_sid = in_csr_user_sid;
END;

PROCEDURE SetUserVocab(
	in_csr_user_sid					IN csr_user.csr_user_sid%TYPE,
	in_tag_type_id					IN imp_tag_type.imp_tag_type_id%TYPE,
	in_phrase						IN imp_vocab.phrase%TYPE
)
AS
	v_imports_sid					imp_session.imp_session_sid%TYPE;
BEGIN
	IF NVL(in_tag_type_id,-1) < 0 THEN
		RETURN; -- workaround for PITA bug
	END IF;

	v_imports_sid := securableobject_pkg.getSidFromPath(security_pkg.getACT, security_pkg.getApp, 'Imports');
	-- check permission on imports object
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_imports_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;


	BEGIN
		INSERT INTO imp_vocab (csr_user_sid, imp_tag_type_id, phrase, frequency) 
		VALUES (in_csr_user_sid, in_tag_type_id, in_phrase, 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- increment the frequency
			UPDATE imp_vocab 
			   SET frequency = frequency + 1
			 WHERE app_sid = security_pkg.getApp
			   AND csr_user_sid = in_csr_user_sid
			   AND imp_tag_type_id = in_tag_type_id
			   AND phrase = in_phrase;
	END;
				
END;

PROCEDURE GetMeasureSidFromIndicatorId(
	in_imp_ind_id					IN  imp_ind.imp_ind_id%TYPE,
	out_measure_sid					OUT	imp_measure.maps_to_measure_sid%TYPE
) AS
BEGIN
	SELECT measure_sid 
	  INTO out_measure_sid
	  FROM csr.ind i 
	  JOIN csr.imp_ind ii ON ii.maps_to_ind_sid = i.ind_sid 
	 WHERE ii.imp_ind_id = in_imp_ind_id;
	EXCEPTION
		WHEN OTHERS THEN
			out_measure_sid := -1;
END;

PROCEDURE UpdateImpValsForCustomMeasures(
	in_imp_session_id				IN imp_session.imp_session_sid%TYPE
) AS
	v_measure_sid imp_measure.maps_to_measure_sid%TYPE;
	v_measure_cur SYS_REFCURSOR;
	v_measure_record measure_pkg.t_measure_cur;
	t_custom_fields 	T_SPLIT_TABLE;
	v_custom_fields_count NUMBER;
	v_fractional_part NUMBER;
BEGIN
  FOR r in (
    SELECT imp_val_id, imp_ind_id, val, note FROM imp_val
    WHERE app_sid = security_pkg.getApp AND
	      imp_session_sid = in_imp_session_id
    )
  LOOP
    GetMeasureSidFromIndicatorId(r.imp_ind_id, v_measure_sid);
	IF v_measure_sid != -1 THEN
		--security_pkg.DebugMsg('for '||r.imp_ind_id||' found '||v_measure_sid);
		measure_pkg.GetMeasure(security_pkg.getACT, v_measure_sid, v_measure_cur);
		FETCH v_measure_cur INTO v_measure_record;
		--security_pkg.DebugMsg('desc '||v_measure_record.description||' cf='||v_measure_record.custom_field);
		
		IF v_measure_record.custom_field IS NOT NULL AND
		   LENGTH(TRIM(v_measure_record.custom_field)) > 0 AND
		   v_measure_record.custom_field != 'x' AND -- x indicates a checkbox measure
		   v_measure_record.custom_field != '|' AND -- Pipe indicates a text measure
		   v_measure_record.custom_field != '$' AND -- Dollar indicates a date measure
		   v_measure_record.custom_field != '&'     -- Ampersand indicates a file upload measure
		THEN
			t_custom_fields	:= Utils_Pkg.splitstring(v_measure_record.custom_field, CHR(13)||CHR(10));
			SELECT COUNT(*) INTO v_custom_fields_count FROM TABLE (t_custom_fields);
			FOR custom_field IN (
				SELECT item, pos FROM TABLE (t_custom_fields)
			)
			LOOP
				--security_pkg.DebugMsg('cf '||custom_field.item||' at pos '||custom_field.pos);
				IF r.note IS NOT NULL AND
				   LENGTH(TRIM(r.note)) > 0 AND
				   r.note = custom_field.item
				THEN
					-- Note matches a custom field value
					--security_pkg.DebugMsg('Note matches a custom field value');
					UPDATE imp_val
					   SET val=custom_field.pos, note=NULL
					 WHERE app_sid = security_pkg.getApp AND
						   imp_val_id = r.imp_val_id;
					EXIT;
				ELSIF r.val IS NOT NULL AND
					  TO_CHAR(r.val) = custom_field.item
				THEN	  
					-- Value matches a custom field value - NOT as an index
					--security_pkg.DebugMsg('Value matches a custom field value');
					UPDATE imp_val
					   SET val=custom_field.pos
					 WHERE app_sid = security_pkg.getApp AND
						   imp_val_id = r.imp_val_id;
					EXIT;
				END IF;
			END LOOP;

			IF r.val IS NOT NULL 
			THEN
				SELECT r.val - TRUNC(r.val) INTO v_fractional_part FROM DUAL;
				IF v_fractional_part = 0 AND
				   TRUNC(r.val) >= 0 AND
				   TRUNC(r.val) <= v_custom_fields_count
				THEN
					-- Value is an index
					--security_pkg.DebugMsg('Value '||r.val||' is a valid index');
					NULL;
				ELSE
					RAISE_APPLICATION_ERROR(-20001, '"Value '||r.val||' cannot be imported as matching custom field could not be found.');
				END IF;
			END IF;

		END IF;
	END IF;
  END LOOP;
END;

PROCEDURE UploadImage(
	in_cache_key	IN	aspen2.filecache.cache_key%type,
  	out_logo_id		OUT	security_pkg.T_SID_ID
)
AS
    v_id 		NUMBER;
BEGIN

 v_id := CSR.IMAGE_UPLOAD_PORTLET_SEQ.NEXTVAL;

	INSERT INTO CSR.IMAGE_UPLOAD_PORTLET (
		app_sid, file_name, image, mime_type, img_id
	)
		SELECT  app_sid, regexp_replace(filename, '[[:space:]]*','') , object, mime_type, v_id
		  FROM ASPEN2.FILECACHE
		 WHERE cache_key = in_cache_key;

     out_logo_id := v_id;
END;

PROCEDURE GetImage(
	in_img_id	IN	NUMBER,
	out_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
      SELECT app_sid, file_name, image, mime_type, img_id
      FROM CSR.IMAGE_UPLOAD_PORTLET
      where img_id = in_img_id
      AND app_sid = SYS_CONTEXT('SECURITY','APP');
END;

END Imp_Pkg;
/

