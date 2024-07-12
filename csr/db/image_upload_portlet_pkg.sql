CREATE OR REPLACE PACKAGE CSR.IMAGE_UPLOAD_PORTLET_PKG AS

PROCEDURE UploadImage(
	in_cache_key	IN	aspen2.filecache.cache_key%TYPE,
 	out_logo_id		OUT	image_upload_portlet.img_id%TYPE
);

PROCEDURE SetImageBlob(
	in_blob			IN	image_upload_portlet.image%TYPE,
	in_filename		IN	image_upload_portlet.file_name%TYPE,
	in_mime_type	IN	image_upload_portlet.mime_type%TYPE,
	out_image_id	OUT	image_upload_portlet.img_id%TYPE
);

PROCEDURE GetImage(
	in_img_id	IN	image_upload_portlet.img_id%TYPE,
	out_cur		OUT	SYS_REFCURSOR
);

END IMAGE_UPLOAD_PORTLET_PKG;
/
