CREATE OR REPLACE PACKAGE BODY CSR.IMAGE_UPLOAD_PORTLET_PKG AS

PROCEDURE UploadImage(
	in_cache_key	IN	aspen2.filecache.cache_key%TYPE,
	out_logo_id		OUT	image_upload_portlet.img_id%TYPE
)
AS
	v_act_id	security_pkg.T_ACT_ID;
	v_app_id	security_pkg.T_SID_ID;
	v_id 		NUMBER;
BEGIN
	v_act_id := security_pkg.GetAct();
	v_app_id := security_pkg.GetApp();
	v_id := image_upload_portlet_seq.NEXTVAL;
	INSERT INTO image_upload_portlet (
		app_sid, file_name, image, mime_type, img_id
	)
		SELECT app_sid, regexp_replace(filename, '[[:space:]]*','') , object, mime_type, v_id
		  FROM aspen2.filecache
		 WHERE cache_key = in_cache_key;

	out_logo_id := v_id;
END;

PROCEDURE SetImageBlob(
	in_blob			IN	image_upload_portlet.image%TYPE,
	in_filename		IN	image_upload_portlet.file_name%TYPE,
	in_mime_type	IN	image_upload_portlet.mime_type%TYPE,
	out_image_id	OUT	image_upload_portlet.img_id%TYPE
)
AS
	v_id 		NUMBER;
BEGIN
	v_id := image_upload_portlet_seq.NEXTVAL;
	
	INSERT INTO image_upload_portlet 
		(file_name, image, mime_type, img_id)
	VALUES
		(regexp_replace(in_filename, '[[:space:]]*',''), in_blob, in_mime_type, v_id);

	out_image_id := v_id;
END;

PROCEDURE GetImage(
	in_img_id	IN	image_upload_portlet.img_id%TYPE,
	out_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, file_name, image, mime_type, img_id
		  FROM image_upload_portlet
		 WHERE img_id = in_img_id
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');
END;

END IMAGE_UPLOAD_PORTLET_PKG;
/
