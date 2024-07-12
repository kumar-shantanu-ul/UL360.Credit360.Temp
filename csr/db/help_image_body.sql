CREATE OR REPLACE PACKAGE BODY CSR.help_image_pkg AS

/*************************************************************
	Image only procedures
*************************************************************/

PROCEDURE IsImageFresh(
	in_image_id			IN	help_image.image_id%TYPE,
	in_lang_id			IN 	help_lang.help_lang_id%TYPE,
	in_sha1				IN	help_image.sha1%TYPE,
	out_image_fresh		OUT	NUMBER
)
AS
BEGIN
	SELECT COUNT(*)
	  INTO out_image_fresh
	  FROM help_image
	 WHERE image_id = in_image_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND sha1 = in_sha1
	   AND image_lang_id
	    IN (
			SELECT help_lang_id
			  FROM help_lang
			 START WITH help_lang_id = in_lang_id
			CONNECT BY PRIOR base_lang_id = help_lang_id
	);
END;

PROCEDURE GetImage(
	in_image_id			IN	help_image.image_id%TYPE,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, image_id, mime_type, sha1, filename, description, data, modified_dtm, width, height, recycled
		  FROM help_image
		 WHERE image_id = in_image_id
		   AND app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND image_lang_id
		    IN (
				SELECT help_lang_id
				  FROM help_lang
				 START WITH help_lang_id = in_lang_id
				CONNECT BY PRIOR base_lang_id = help_lang_id
		);
END;

PROCEDURE GetImagesWithSids(
	in_image_ids		IN security_pkg.T_SID_IDS,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
IS
	t security.T_SID_TABLE;
BEGIN
	t := security_pkg.SidArrayToTable(in_image_ids);
	
	OPEN out_cur FOR
		SELECT * FROM (
			SELECT image_id id, 0 is_tag, mime_type, filename, description, modified_dtm, LENGTH(data) data_length, NVL(description, filename) text
			  FROM help_image
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND recycled = 0
			   AND image_id
			    IN (
					SELECT column_value image_id
						FROM TABLE(t)
			)
			   AND image_lang_id
			    IN (
					SELECT help_lang_id
					  FROM help_lang
					 START WITH help_lang_id = in_lang_id
					CONNECT BY PRIOR base_lang_id = help_lang_id
			)
		) ORDER BY LOWER(text);
END;

PROCEDURE GetImagesByRecycledState(
	in_recycled			IN  help_image.recycled%TYPE,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT * FROM (
			SELECT image_id id, 0 is_tag, mime_type, filename, description, modified_dtm, LENGTH(data) data_length, NVL(description, filename) text
			  FROM help_image
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND recycled = in_recycled
			   AND image_lang_id
			    IN (
					SELECT help_lang_id
					  FROM help_lang
					 START WITH help_lang_id = in_lang_id
					CONNECT BY PRIOR base_lang_id = help_lang_id
			)
		) ORDER BY LOWER(text);
END;



PROCEDURE GetImages(
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetImagesByRecycledState(0, in_lang_id, out_cur);
END;



PROCEDURE GetRecycledImages(
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetImagesByRecycledState(1, in_lang_id, out_cur);
END;



PROCEDURE CreateImage(
	in_mime_type			IN	help_image.mime_type%TYPE,
	in_filename				IN	help_image.filename%TYPE,
	in_description			IN	help_image.description%TYPE,
	in_lang_id				IN help_lang.help_lang_id%TYPE,
	out_data				OUT	help_image.data%TYPE,
	out_image_id			OUT	help_image.image_id%TYPE
)
AS
BEGIN
	INSERT INTO help_image 
		(image_id, mime_type, sha1, filename, description, image_lang_id, data, app_sid, recycled)
	VALUES 
		(help_image_id_seq.nextval, in_mime_type, 'ABCD', in_filename, in_description, in_lang_id, EMPTY_BLOB(), SYS_CONTEXT('SECURITY', 'APP'), 0)
	RETURNING image_id, data INTO out_image_id, out_data;
END;



PROCEDURE SetImageDescription(
	in_image_id			IN  help_image.image_id%TYPE,
	in_description		IN  help_image.description%TYPE
)
AS
BEGIN
	UPDATE help_image 
	   SET description = in_description
	 WHERE image_id = in_image_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;



PROCEDURE SetImageDimensionsAndSHA1(
	in_image_id			IN  help_image.image_id%TYPE,
	in_width			IN  number,
	in_height			IN  number
)
AS
BEGIN
	UPDATE help_image
	   SET width = NVL(in_width, 0), height = NVL(in_height, 0), sha1 = dbms_crypto.hash(data, dbms_crypto.hash_sh1)
	 WHERE image_id = in_image_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;



PROCEDURE RecycleImage(
	in_image_id				IN  help_image.image_id%TYPE
)
AS
BEGIN
	UPDATE help_image
	   SET recycled = 1 
	 WHERE image_id = in_image_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE UnrecycleImage(
	in_image_id				IN  help_image.image_id%TYPE
)
AS
BEGIN
	UPDATE help_image
	   SET recycled = 0
	 WHERE image_id = in_image_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE DeleteImage(
	in_image_id				IN  help_image.image_id%TYPE
)
AS
BEGIN
	DELETE FROM help_image
	 WHERE image_id = in_image_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetImageDetails (
	in_image_id				IN  help_image.image_id%TYPE,
	in_lang_id				IN help_lang.help_lang_id%TYPE,
	out_image_cur			OUT	SYS_REFCURSOR,
	out_tags_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- GetImage(in_image_id, out_image_cur);
	-- we don't care about the binary data AND it's faster retrieve time without it, so lets get everything but
	
	OPEN out_image_cur FOR
		SELECT image_id, mime_type, modified_dtm, sha1, filename, description, width, height, recycled
		  FROM help_image
		 WHERE image_id = in_image_id
	   	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   	   AND image_lang_id
			IN (
				SELECT help_lang_id
				  FROM help_lang
				 START WITH help_lang_id = in_lang_id
				CONNECT BY PRIOR base_lang_id = help_lang_id
		);

	GetImageTags(in_image_id, in_lang_id, out_tags_cur);
END;

/*************************************************************
	Mixed use procedures
*************************************************************/

PROCEDURE GetImageTagChildren(
	in_tag_id			IN  help_tag.tag_id%TYPE,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT * FROM (
			SELECT tag_id id, tag text, 1 is_tag, null mime_type, null filename, null data_length
			  FROM help_tag
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND parent_tag_id = in_tag_id
			UNION ALL
			SELECT i.image_id id, NVL(i.description, i.filename) text, 0 is_tag, mime_type, filename, LENGTH(data) data_length 
			  FROM help_image i, help_image_tag it
			 WHERE it.parent_tag_id = in_tag_id
			   AND it.image_id = i.image_id
			   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND i.recycled = 0
			   AND i.image_lang_id
			    IN (
					SELECT help_lang_id
					  FROM help_lang
					 START WITH help_lang_id = in_lang_id
					CONNECT BY PRIOR base_lang_id = help_lang_id
			)
		) ORDER BY is_tag desc, LOWER(text);
END;



PROCEDURE AddImageToTag(
	in_tag_id			IN  help_tag.tag_id%TYPE,
	in_image_id			IN  help_image.image_id%TYPE,
	out_cur				OUT SYS_REFCURSOR
)
AS
	v_tag_id			help_tag.tag_id%TYPE;
	v_image_id			help_image.image_id%TYPE;
BEGIN
	
	BEGIN
		SELECT tag_id 
		  INTO v_tag_id
		  FROM help_tag
		 WHERE tag_id = in_tag_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');	
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
				'Tag with id '||in_tag_id||' not found in application with sid '||SYS_CONTEXT('SECURITY', 'APP'));
	END;
	
	BEGIN
		SELECT image_id 
		  INTO v_image_id
		  FROM help_image
		 WHERE image_id = in_image_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');	
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
				'Image with id '||in_tag_id||' not found in application with sid '||SYS_CONTEXT('SECURITY', 'APP'));
	END;
	
	INSERT INTO help_image_tag
		(parent_tag_id, image_id)
	values
		(v_tag_id, v_image_id);

	OPEN out_cur FOR
		SELECT image_id id, NVL(description, filename) text, 0 is_tag, mime_type, filename, LENGTH(data) data_length
		  FROM help_image
		 WHERE image_id = v_image_id;
END;



PROCEDURE RemoveImageFromTag(
	in_parent_tag_id	IN  help_tag.tag_id%TYPE,
	in_image_id			IN  help_image.image_id%TYPE
)
AS
BEGIN
	DELETE FROM help_image_tag
	 WHERE parent_tag_id IN (
			SELECT tag_id 
			  FROM help_tag 
			 WHERE tag_id = in_parent_tag_id 
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 )
	   AND image_id IN (
			SELECT image_id 
			  FROM help_image 
			 WHERE image_id = in_image_id 
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 );
END;



PROCEDURE GetImageTags(
	in_image_id			IN  help_image.image_id%TYPE,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT SYS_REFCURSOR			
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT t.tag_id, t.tag
		  FROM help_image i, help_image_tag it, help_tag t
		 WHERE i.image_id = in_image_id
		   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND it.image_id = i.image_id
		   AND t.tag_id = it.parent_tag_id
           AND t.app_sid = i.app_sid
           AND i.image_lang_id
			IN (
				SELECT help_lang_id
				  FROM help_lang
				 START WITH help_lang_id = in_lang_id
				CONNECT BY PRIOR base_lang_id = help_lang_id
		);
END;

/*************************************************************
	Tag only procedures
*************************************************************/

PROCEDURE GetOrCreateRootTagId(
	out_tag_id			OUT help_tag.tag_id%TYPE
)
AS
BEGIN

	BEGIN
		SELECT tag_id 
		  INTO out_tag_id
		  FROM help_tag
		 WHERE parent_tag_id is null
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO help_tag
				(tag_id, tag, app_sid, parent_tag_id)
			values
				(help_tag_id_seq.nextval, 'Tags', SYS_CONTEXT('SECURITY', 'APP'), null)
			RETURNING tag_id INTO out_tag_id;
	END;
END;



PROCEDURE AddTag(
	in_parent_tag_id	IN  help_tag.tag_id%TYPE,
	in_text				IN  help_tag.tag%TYPE,
	out_cur				OUT SYS_REFCURSOR
)
AS
	v_parent_tag_id		help_tag.tag_id%TYPE;
	v_tag_id			help_tag.tag_id%TYPE;
BEGIN
	
	BEGIN
		SELECT tag_id 
		  INTO v_parent_tag_id
		  FROM help_tag
		 WHERE tag_id = in_parent_tag_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');	
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
				'Tag with id '||in_parent_tag_id||' not found in application with sid '||SYS_CONTEXT('SECURITY', 'APP'));
	END;
	
	INSERT INTO help_tag
		(tag_id, tag, app_sid, parent_tag_id)
	VALUES                         -- disallow commas
		(help_tag_id_seq.nextval, REPLACE(in_text, ',', ''), SYS_CONTEXT('SECURITY', 'APP'), v_parent_tag_id)
	RETURNING tag_id INTO v_tag_id;
	
	OPEN out_cur FOR
		SELECT tag_id id, tag text, 1 is_tag, null mime_type, null filename, null data_length
		  FROM help_tag 
		 WHERE tag_id = v_tag_id;
END;



PROCEDURE SetTagText(
	in_tag_id			IN  help_tag.tag_id%TYPE,
	in_text				IN  help_tag.tag%TYPE
)
AS
BEGIN
	UPDATE help_tag
	   SET tag = REPLACE(in_text, ',', '') -- disallow commas
	 WHERE tag_id = in_tag_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;



PROCEDURE RemoveTag(
	in_tag_id			IN  help_tag.tag_id%TYPE
)
AS
BEGIN
	DELETE FROM help_tag
	 WHERE tag_id IN (
		SELECT tag_id
		  FROM help_tag  
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   CONNECT BY PRIOR tag_id = parent_tag_id 
		 START WITH tag_id = in_tag_id
	);
END;



END;
/
