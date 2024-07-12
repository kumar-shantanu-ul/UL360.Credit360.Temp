CREATE OR REPLACE PACKAGE BODY DONATIONS.letter_pkg
IS

PROCEDURE GetTemplateList(
	in_act					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF in_region_group_sid IS NULL THEN
		OPEN out_cur FOR
			SELECT letter_template_id, name, 0 region_group_sid
			  FROM letter_template
			 WHERE app_sid = in_app_sid;
	ELSE
		OPEN out_cur FOR
			SELECT t.letter_template_id, name, rg.region_group_sid
			  FROM letter_template t, region_group rg
			 WHERE t.app_sid = in_app_sid
			   AND rg.region_group_sid(+) = in_region_group_sid
			   AND rg.letter_template_id(+) = t.letter_template_id;
	END IF;
END;

PROCEDURE GetSelectedTemplate(
	in_act					IN	security_pkg.T_ACT_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_template_id			letter_template.letter_template_id%TYPE;	
BEGIN
	-- Fetch the template ID
	SELECT letter_template_id
	  INTO v_template_id
	  FROM region_group
	 WHERE region_group_sid = in_region_group_sid;
	 
	 -- Get the template
	 GetTemplate(in_act, v_template_id, out_cur);
END;


PROCEDURE GetTemplate(
	in_act					IN	security_pkg.T_ACT_ID,
	in_template_id			IN	letter_template.letter_template_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT letter_template_id, name, data
		  FROM letter_template
		 WHERE letter_template_id = in_template_id;
END;

PROCEDURE NewTemplateFromCache(
	in_act					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	out_template_id			OUT	letter_template.letter_template_id%TYPE
)
AS
BEGIN
	-- Generate a new template id
	SELECT letter_template_id_seq.NEXTVAL
	  INTO out_template_id
	  FROM dual;
	  
	-- Get the data from the cache and put it into the letter_template table
	INSERT INTO letter_template
		(letter_template_id, app_sid, name, data) 
    	SELECT out_template_id, in_app_sid, filename, object
          FROM aspen2.filecache 
         WHERE cache_key = in_cache_key;
    
    IF SQL%ROWCOUNT = 0 THEN
    	-- pah! not found
        RAISE_APPLICATION_ERROR(-20001, 'Cache Key "'||in_cache_key||'" not found');
    END IF;
END;

PROCEDURE AssocTemplateWithRegionGroup(
	in_act					IN	security_pkg.T_ACT_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	in_template_id			IN	letter_template.letter_template_id%TYPE
)
AS
BEGIN	
	UPDATE region_group
	   SET letter_template_id = in_template_id
	 WHERE region_group_sid = in_region_group_sid;
END;


PROCEDURE DeleteTemplate(
	in_act					IN	security_pkg.T_ACT_ID,
	in_template_id			IN	letter_template.letter_template_id%TYPE
)
AS
BEGIN
	-- Remove references to the tmplate
	UPDATE region_group
	   SET letter_template_id = NULL
	 WHERE letter_template_id = in_template_id;
	 
	-- Remove the template
	DELETE FROM letter_template
		WHERE letter_template_id = in_template_id;
END;



-- If the region group supplied has no body text then the default body text will be returned
-- Region group can be null, in which case the default body text is returned
PROCEDURE GetBodyTextForRegionGroup(
	in_act								IN	security_pkg.T_ACT_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	in_status_sid					IN	donation_status.donation_status_sid%TYPE,
	out_cur								OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_count 				NUMBER(10);
BEGIN
	IF in_region_group_sid IS NULL THEN
		-- Select the default text body, i.e. one that has 
		-- no entry in the letter_body_region_group table
		OPEN out_cur FOR
			SELECT letter_body_text_id, body_text, NULL region_group_sid, ds.letter_active
			  FROM letter_body_text lbt, donation_status ds
             WHERE lbt.donation_status_sid = ds.donation_status_sid
               AND  letter_body_text_id  IN (
                    SELECT letter_body_text_id
                      FROM letter_body_text 
                     WHERE donation_status_sid = in_status_sid
				MINUS
				    SELECT letter_body_text_id
				      FROM letter_body_region_group
			 );
    
	ELSE
		-- Does this region group have a body text
		SELECT COUNT(0)
		  INTO v_count
		  FROM letter_body_region_group
		 WHERE region_group_sid = in_region_group_sid
		   AND donation_status_sid = in_status_sid;
		   
		IF v_count = 0 THEN
			-- Call ourselves, passing NULL for the region group sid (will get default)
			GetBodyTextForRegionGroup(in_act, NULL, in_status_sid, out_cur);
		ELSE
			-- Select the body text for the given region group
			OPEN out_cur FOR
				SELECT lbt.letter_body_text_id,lbt.body_text, lbrg.region_group_sid, ds.letter_active
				  FROM letter_body_text lbt, letter_body_region_group lbrg, donation_status ds
				 WHERE lbt.letter_body_text_id = lbrg.letter_body_text_id
				   AND lbrg.region_group_sid = in_region_group_sid
				   AND lbrg.donation_status_sid = in_status_sid
				   AND lbt.donation_status_sid = in_status_sid
				   AND ds.donation_status_sid = in_status_sid;
		END IF;
	END IF;
END;

PROCEDURE GetBodyText(
	in_act					IN	security_pkg.T_ACT_ID,
	in_body_text_id			IN	letter_body_text.letter_body_text_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT letter_body_text_id, donation_status_sid, body_text
		  FROM letter_body_text
		 WHERE letter_body_text_id = in_body_text_id;
END;


PROCEDURE SetBodyText(
	in_act					IN	security_pkg.T_ACT_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	in_status_sid			IN	donation_status.donation_status_sid%TYPE,
	in_text	    			IN	letter_body_text.body_text%TYPE,
	in_active               IN  donation_status.letter_active%TYPE DEFAULT 1,
	out_body_text_id		OUT	letter_body_text.letter_body_text_id%TYPE
)
AS
BEGIN
	IF in_region_group_sid IS NULL THEN
		BEGIN
			SELECT letter_body_text_id 
			  INTO out_body_text_id
			  FROM (
			    SELECT letter_body_text_id
			     FROM letter_body_text
			    WHERE donation_status_sid = in_status_sid
			    MINUS
			    SELECT letter_body_text_id
			      FROM letter_body_region_group
			  );
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				out_body_text_id := NULL;
		END;
	ELSE
		BEGIN
			SELECT lbt.letter_body_text_id
			  INTO out_body_text_id
			  FROM letter_body_text lbt, letter_body_region_group lbrg
			 WHERE lbt.letter_body_text_id = lbrg.letter_body_text_id
			   AND lbrg.region_group_sid = in_region_group_sid
			   AND lbrg.donation_status_sid = in_status_sid
			   AND lbt.donation_status_sid = in_status_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				out_body_text_id := NULL;
		END;
	END IF;
	   
	IF out_body_text_id IS NULL THEN
		
		-- Get new ID
		SELECT letter_template_id_seq.NEXTVAL
		  INTO out_body_text_id
		  FROM dual;
		
		-- Insert text body
		INSERT INTO letter_body_text
			(letter_body_text_id, donation_status_sid, body_text)
			VALUES (out_body_text_id, in_status_sid, in_text);
			
		-- Relate to region group if required
		IF in_region_group_sid IS NOT NULL THEN
			INSERT INTO letter_body_region_group
				(region_group_sid, letter_body_text_id, donation_status_sid)
				VALUES (in_region_group_sid, out_body_text_id, in_status_sid);
		END IF;

	ELSE
		-- Simple update required
		UPDATE letter_body_text
		   SET body_text = in_text
		 WHERE letter_body_text_id = out_body_text_id;

	END IF;
	
	IF in_region_group_sid IS NULL THEN
        -- Update the active flag
		UPDATE donation_status
		   SET letter_active = in_active
		 WHERE donation_status_sid = in_status_sid;
	END IF;
	
END;


PROCEDURE DeleteBodyText(
	in_act					IN	security_pkg.T_ACT_ID,
	in_body_text_id			IN	letter_body_text.letter_body_text_id%TYPE
)
AS
BEGIN
	-- Delete region group relationship
	DELETE FROM letter_body_region_group
		WHERE letter_body_text_id = in_body_text_id;
	
	-- Delete the body text
	DELETE FROM letter_body_text
		WHERE letter_body_text_id = in_body_text_id;
END;

PROCEDURE DeleteBodyTextForRegionGroup(
	in_act					IN	security_pkg.T_ACT_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	in_status_sid			IN	donation_status.donation_status_sid%TYPE
)
AS
	v_body_text_id			letter_body_text.letter_body_text_id%TYPE;
BEGIN
	-- We need the body text ID
	BEGIN
		SELECT letter_body_text_id
		  INTO v_body_text_id
		  FROM letter_body_region_group
		 WHERE region_group_sid = in_region_group_sid
		   AND donation_status_sid = in_status_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN;
	END;
	
	-- Delete region group relationship
	DELETE FROM letter_body_region_group
		WHERE region_group_sid = in_region_group_sid
		  AND donation_status_sid = in_status_sid;
	
	-- Delete the body text
	DELETE FROM letter_body_text
		WHERE donation_status_sid = in_status_sid
		  AND letter_body_text_id = v_body_text_id;
END;

PROCEDURE GetStatusToActiveMapping (
    in_act					IN	security_pkg.T_ACT_ID,
    in_app_sid				IN	security_pkg.T_SID_ID,
    out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT ds.donation_status_sid, 
           ds.letter_active
          FROM donation_status ds
         WHERE app_sid = in_app_sid;
END;

END letter_pkg;
/
