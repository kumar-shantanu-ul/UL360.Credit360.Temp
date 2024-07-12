CREATE OR REPLACE PACKAGE CSR.help_image_pkg AS

/*************************************************************
	Image only procedures
*************************************************************/

PROCEDURE IsImageFresh(
	in_image_id			IN	help_image.image_id%TYPE,
	in_lang_id			IN 	help_lang.help_lang_id%TYPE,
	in_sha1				IN	help_image.sha1%TYPE,
	out_image_fresh		OUT	NUMBER
);

PROCEDURE GetImage(
	in_image_id			IN	help_image.image_id%TYPE,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetImages(
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetImagesWithSids(
	in_image_ids		IN security_pkg.T_SID_IDS,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetRecycledImages(
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE CreateImage(
	in_mime_type			IN	help_image.mime_type%TYPE,
	in_filename				IN	help_image.filename%TYPE,
	in_description			IN	help_image.description%TYPE,
	in_lang_id				IN help_lang.help_lang_id%TYPE,
	out_data				OUT	help_image.data%TYPE,
	out_image_id			OUT	help_image.image_id%TYPE
);

PROCEDURE SetImageDescription(
	in_image_id			IN  help_image.image_id%TYPE,
	in_description		IN  help_image.description%TYPE
);

PROCEDURE SetImageDimensionsAndSHA1(
	in_image_id			IN  help_image.image_id%TYPE,
	in_width			IN  number,
	in_height			IN  number
);

PROCEDURE RecycleImage(
	in_image_id				IN  help_image.image_id%TYPE
);

PROCEDURE UnrecycleImage(
	in_image_id				IN  help_image.image_id%TYPE
);

PROCEDURE DeleteImage(
	in_image_id				IN  help_image.image_id%TYPE
);

PROCEDURE GetImageDetails (
	in_image_id				IN  help_image.image_id%TYPE,
	in_lang_id				IN help_lang.help_lang_id%TYPE,
	out_image_cur			OUT	SYS_REFCURSOR,
	out_tags_cur			OUT	SYS_REFCURSOR
);

/*************************************************************
	Mixed use procedures
*************************************************************/

PROCEDURE GetImageTagChildren(
	in_tag_id			IN  help_tag.tag_id%TYPE,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE AddImageToTag(
	in_tag_id			IN  help_tag.tag_id%TYPE,
	in_image_id			IN  help_image.image_id%TYPE,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE RemoveImageFromTag(
	in_parent_tag_id	IN  help_tag.tag_id%TYPE,
	in_image_id			IN  help_image.image_id%TYPE
);

PROCEDURE GetImageTags(
	in_image_id			IN  help_image.image_id%TYPE,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT SYS_REFCURSOR			
);

/*************************************************************
	Tag only procedures
*************************************************************/

PROCEDURE GetOrCreateRootTagId(
	out_tag_id			OUT help_tag.tag_id%TYPE
);

PROCEDURE AddTag(
	in_parent_tag_id	IN  help_tag.tag_id%TYPE,
	in_text				IN  help_tag.tag%TYPE,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE SetTagText(
	in_tag_id			IN  help_tag.tag_id%TYPE,
	in_text				IN  help_tag.tag%TYPE
);

PROCEDURE RemoveTag(
	in_tag_id			IN  help_tag.tag_id%TYPE
);


END;
/
