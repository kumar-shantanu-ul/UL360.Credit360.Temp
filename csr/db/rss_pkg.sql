CREATE OR REPLACE PACKAGE CSR.rss_pkg IS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

 
/*
 *	CreateFeed
 */
PROCEDURE CreateFeed(
	in_name					  IN	RSS_FEED.name%TYPE,
	in_description		IN	RSS_FEED.description%TYPE,
	in_is_public      IN  NUMBER,
  in_web_name       IN  VARCHAR2,
	out_cur           OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE AmendFeed(
  in_rss_feed_sid   IN  security_pkg.T_SID_ID,
  in_name					  IN	RSS_FEED.name%TYPE,
	in_description		IN	RSS_FEED.description%TYPE,
	in_is_public      IN  NUMBER,
	in_web_name       IN  VARCHAR2,
	out_cur           OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE INTERNAL_SetIsPublic(
    in_feed_sid			IN security_pkg.T_SID_ID,
    in_is_public		IN NUMBER
);

FUNCTION INTERNAL_GetIsPublic(
	in_feed_sid			IN security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION GetFeedSidForItemId(
	in_rss_feed_item_id 		IN	RSS_FEED_ITEM.rss_feed_item_id%TYPE
) 
RETURN security_pkg.T_SID_ID;

PROCEDURE GetFeeds(
    out_cur		      OUT security_pkg.T_OUTPUT_CUR
);


/*
 *	Create Feed Item
 */
PROCEDURE CreateFeedItem(
	in_rss_feed_sid 		IN	RSS_FEED_ITEM.rss_feed_sid%TYPE,
	in_title				IN  RSS_FEED_ITEM.title%TYPE,
	in_description			IN  RSS_FEED_ITEM.description%TYPE,
	in_link					IN  RSS_FEED_ITEM.link%TYPE,
	in_published_dtm		IN  RSS_FEED_ITEM.published_dtm%TYPE,
	out_cur		      		OUT security_pkg.T_OUTPUT_CUR
);

/*
 *	Delete Feed Item
 */
PROCEDURE DeleteFeedItem(
	in_rss_feed_item_id		IN	RSS_FEED_ITEM.rss_feed_item_id%TYPE
);

/*
 *	Update Feed Item
 */
PROCEDURE UpdateFeedItem(
	in_rss_feed_item_id		IN	RSS_FEED_ITEM.rss_feed_item_id%TYPE,
	in_title				IN  RSS_FEED_ITEM.title%TYPE,
	in_description			IN  RSS_FEED_ITEM.description%TYPE,
	in_link					IN  RSS_FEED_ITEM.link%TYPE,
	in_published_dtm		IN  RSS_FEED_ITEM.published_dtm%TYPE,
	out_cur		      		OUT security_pkg.T_OUTPUT_CUR
);


PROCEDURE UpdateFeedXml(
	in_rss_feed_sid 		IN  RSS_FEED.rss_feed_sid%TYPE,
--	out_xml			    OUT	XMLType
  in_xml              IN XMLType
);


 
PROCEDURE GetFeed(
	in_rss_feed_sid 		IN	RSS_FEED.rss_feed_sid%TYPE,
	out_cur		      		OUT security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetFeedWithItems(
	in_rss_feed_sid 		  IN	security_pkg.T_SID_ID,
	feed_cur  	      		OUT security_pkg.T_OUTPUT_CUR,
	items_cur		      		OUT security_pkg.T_OUTPUT_CUR
);


/*
 *	Get Feed Item
 */
PROCEDURE GetFeedItem(
	in_rss_feed_item_id IN	RSS_FEED_ITEM.rss_feed_item_id%TYPE,
	out_cur		      	OUT security_pkg.T_OUTPUT_CUR
);

/* 
 * Get date modified
 */
PROCEDURE GetModifiedDtm(
	in_feed_sid			IN	rss_feed.rss_feed_sid%TYPE,
	out_modified_dtm	OUT	rss_feed.last_modified_dtm%TYPE
);


/**
 * Get available feeds
 *
 */
PROCEDURE GetCachedFeedsList(
    out_cur		      OUT security_pkg.T_OUTPUT_CUR
);


PROCEDURE SetCachedFeed(
  in_rss_url        default_rss_feed.rss_url%TYPE,
  in_rss_name       default_rss_feed.name%TYPE
);


PROCEDURE RemoveCachedFeed(
	in_rss_url			IN RSS_CACHE.rss_url%TYPE
);

END rss_pkg;
/