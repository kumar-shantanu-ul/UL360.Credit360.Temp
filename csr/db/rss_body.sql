CREATE OR REPLACE PACKAGE BODY CSR.rss_pkg IS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sid_id			IN security_pkg.T_SID_ID,
	in_class_id			IN security_pkg.T_CLASS_ID,
	in_name				IN security_pkg.T_SO_NAME,
	in_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sid_id			IN security_pkg.T_SID_ID,
	in_new_name		IN security_pkg.T_SO_NAME
) AS
BEGIN
	--update rss_feed set name = in_new_name where rss_feed_sid = in_sid_id;
	web_pkg.RenameObject(in_act_id, in_sid_id, in_new_name);
END;

PROCEDURE DeleteObject(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_sid_id		IN security_pkg.T_SID_ID
) AS
BEGIN
    -- delete stuff
    DELETE FROM rss_feed_item
     WHERE rss_feed_sid = in_sid_id;
    DELETE FROM rss_feed 
     WHERE rss_feed_sid = in_sid_id;
    -- tidy web resource
	web_pkg.DeleteObject(in_act_id, in_sid_id);
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS	
BEGIN	 
	web_pkg.MoveObject(in_act_id, in_sid_id, in_new_parent_sid_id, in_old_parent_sid_id);
END;



PROCEDURE INTERNAL_SetIsPublic(
    in_feed_sid			IN security_pkg.T_SID_ID,
    in_is_public		IN NUMBER
)
AS
	v_act_id		      security_pkg.T_ACT_ID;
	v_app_sid         security_pkg.T_SID_ID;
BEGIN
    v_act_id := security_pkg.GetACT();
    v_app_sid := security_pkg.GetApp();
	
    -- always remove (hmm - this could in theory remove a DENY ACE...)
    acl_pkg.RemoveACEsForSid(
      v_act_id,
      acl_pkg.GetDACLIDForSID(in_feed_sid),
      security_pkg.SID_BUILTIN_EVERYONE
    );

    -- now optionally reinsert
    IF in_is_public = 1 THEN
      acl_pkg.AddACE(
        v_act_id,
        acl_pkg.GetDACLIDForSID(in_feed_sid),
        -1,
        security_pkg.ACE_TYPE_ALLOW,
        security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
        security_pkg.SID_BUILTIN_EVERYONE,
        security_pkg.PERMISSION_STANDARD_READ
      );
    END IF;
END;


FUNCTION INTERNAL_GetIsPublic(
	in_feed_sid			IN security_pkg.T_SID_ID
) RETURN NUMBER
AS
    acl_cur             security_pkg.T_OUTPUT_CUR;
    v_app_sid           security_pkg.T_SID_ID;
    v_act_id		    security_pkg.T_ACT_ID;
    v_acl_id            security_pkg.T_ACL_ID;
    v_acl_index         security_pkg.T_ACL_INDEX;
    v_ace_type          security_pkg.T_ACE_TYPE;
    v_ace_flags         security_pkg.T_ACE_FLAGS;
    v_sid_id            security_pkg.T_SID_ID;
    v_permission_set    security_pkg.T_PERMISSION;
BEGIN
    v_app_sid := security_pkg.GetApp();
    v_act_id := security_pkg.GetAct();

    acl_pkg.GetDACL(v_act_id, in_feed_sid, acl_cur);

    LOOP 
        FETCH acl_cur INTO v_acl_id, v_acl_index, v_ace_type, v_ace_flags, v_sid_id, v_permission_set;
        EXIT WHEN acl_cur%NOTFOUND;   

        IF v_sid_id = security_pkg.SID_BUILTIN_EVERYONE AND v_ace_type = security_pkg.ACE_TYPE_ALLOW THEN
            RETURN 1;
        END IF;
    END LOOP;

    RETURN 0;
END;


FUNCTION GetFeedSidForItemId(
	in_rss_feed_item_id 		IN	RSS_FEED_ITEM.rss_feed_item_id%TYPE
) 
RETURN security_pkg.T_SID_ID
AS
    v_act_id    		security_pkg.T_ACT_ID;
	v_rss_feed_sid	    security_pkg.T_SID_ID;
BEGIN
    v_act_id    := security_pkg.GetAct();

    -- fetch sid of feed the item belongs to 
    SELECT rss_feed_sid 
      INTO v_rss_feed_sid 
      FROM RSS_FEED_ITEM
     WHERE rss_feed_item_id = in_rss_feed_item_id;

    -- check permission....
    IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_rss_feed_sid, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    RETURN v_rss_feed_sid;
END;


/*
 *	CreateFeed
 */
PROCEDURE CreateFeed(
  in_name					  IN	RSS_FEED.name%TYPE,
	in_description		IN	RSS_FEED.description%TYPE,
	in_is_public      IN  NUMBER,
	in_web_name       IN  VARCHAR2,
	out_cur           OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid		security_pkg.T_SID_ID;
	v_act_id		security_pkg.T_ACT_ID;
	v_wwwroot_sid   security_pkg.T_SID_ID;
	v_user_sid		  security_pkg.T_SID_ID;
  v_out_feed_sid  security_pkg.T_SID_ID;
BEGIN
	v_app_sid 	:= security_pkg.GetApp();
	v_act_id	  := security_pkg.GetAct();
	v_user_sid	:= security_pkg.GetSID();
	
	-- get securable object RSSFeeds
	v_wwwroot_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'wwwroot');
	
	-- create as a web resource with a rewrite
	web_pkg.CreateResource(v_act_id, 
      v_wwwroot_sid, 
      securableobject_pkg.GetSIDFromPath(v_act_id, v_wwwroot_sid, 'rss'),
      Replace(in_web_name,'/','\'),
      class_pkg.getClassID('RssFeed'), 
      '/csr/public/rss.aspx?feed={sid}', 
      v_out_feed_sid
  );
    
	INTERNAL_SetIsPublic(v_out_feed_sid, in_is_public);
    
	INSERT INTO RSS_FEED
				(rss_feed_sid, app_sid, NAME, description, owner_sid
				)
		 VALUES (v_out_feed_sid, v_app_sid, in_name, in_description, v_user_sid
				);

  -- finally return the information about feed
  GetFeed(v_out_feed_sid, out_cur);
  
END;

/*
 *	AmendFeed
 */
PROCEDURE AmendFeed(
  in_rss_feed_sid   IN  security_pkg.T_SID_ID,
  in_name					  IN	RSS_FEED.name%TYPE,
	in_description		IN	RSS_FEED.description%TYPE,
	in_is_public      IN  NUMBER,
	in_web_name       IN  VARCHAR2,
	out_cur           OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid		    security_pkg.T_SID_ID;
	v_act_id		    security_pkg.T_ACT_ID;
	v_owner_sid     security_pkg.T_SID_ID;
	v_user_sid		  security_pkg.T_SID_ID;
BEGIN
	v_app_sid 	:= security_pkg.GetApp();
	v_act_id	  := security_pkg.GetAct();
	v_user_sid	:= security_pkg.GetSID();
		 
  -- check permission....
	SELECT owner_sid INTO v_owner_sid FROM rss_feed WHERE rss_feed_sid = in_rss_feed_sid;
	
	IF v_owner_sid != v_user_sid THEN
      RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing feed details.');
	END IF;
	
		 
	-- update name
  securableobject_pkg.RenameSO(v_act_id, in_rss_feed_sid, in_web_name);
	   
	-- set 'publicly available'
	INTERNAL_SetIsPublic(in_rss_feed_sid, in_is_public);
    
  -- update description, as name got updated in RenameSO
	UPDATE RSS_FEED SET
        name = in_name,
        description = in_description
     WHERE app_sid =  v_app_sid
			 AND rss_feed_sid = in_rss_feed_sid;
				
  -- return new info
  -- finally return the information about feed
  GetFeed(in_rss_feed_sid, out_cur);
  
END;



/*
 *	Get Feeds
 */
PROCEDURE GetFeeds(
    out_cur		      OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid	        security_pkg.T_SID_ID;
	v_act_id          security_pkg.T_ACT_ID;
  v_rss_root_sid    security_pkg.T_SID_ID;
BEGIN
	v_app_sid         := security_pkg.GetApp;
	v_act_id          := security_pkg.GetACT;
	v_rss_root_sid    := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'wwwroot/rss');
    
  --securableobject_pkg.GetChildrenWithPerm(v_act_id, v_rss_root_sid, security_pkg.PERMISSION_READ, out_cur);   

    OPEN out_cur FOR
    SELECT rf.name, rf.description, so.name so_name, so.sid_id sid_id
        FROM TABLE(securableobject_pkg.GetChildrenWithPermAsTable(v_act_id, v_rss_root_sid, security_pkg.PERMISSION_READ))so,
         RSS_FEED rf
       WHERE rf.rss_feed_sid = so.sid_id;

END;


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
)
AS
	v_user_sid 				  security_pkg.T_SID_ID;
	v_new_feed_item_id	RSS_FEED_ITEM.RSS_FEED_ITEM_ID%TYPE;
	v_act_id				    security_pkg.T_ACT_ID;
BEGIN
	v_user_sid 	:= security_pkg.GetSID();
	v_act_id	  := security_pkg.GetACT();
	
	
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_rss_feed_sid,  security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied creating feed items');
	END IF;
	
	INSERT INTO rss_feed_item 
		(RSS_FEED_ITEM_ID, RSS_FEED_SID, title, description, link, published_dtm, owner_sid)
	VALUES
		(RSS_FEED_ITEM_ID_SEQ.NEXTVAL, in_rss_feed_sid, in_title, in_description, in_link, in_published_dtm	, v_user_sid)
	RETURNING RSS_FEED_ITEM_ID INTO v_new_feed_item_id;

	GetFeedItem(v_new_feed_item_id, out_cur);

END;


/*
 *	Delete Feed Item
 */
PROCEDURE DeleteFeedItem(
	in_rss_feed_item_id		IN	RSS_FEED_ITEM.rss_feed_item_id%TYPE
)
AS
	v_user_sid 				  security_pkg.T_SID_ID;
	v_act_id				    security_pkg.T_ACT_ID;
	v_rss_feed_sid			security_pkg.T_SID_ID;
	v_count					    NUMBER(10);
BEGIN

	v_user_sid 	:= security_pkg.GetSID();
	v_act_id	:= security_pkg.GetACT();
	
	-- get the owner of the sid
	SELECT rss_feed_sid 
	  INTO v_rss_feed_sid 
	  FROM rss_feed_item 
	 WHERE rss_feed_item_id = in_rss_feed_item_id;
	
	
	-- only owner of item and feed owner has the ability to delete items
	SELECT Count(* )
	INTO   v_count
	FROM   rss_feed_item
	WHERE  rss_feed_item_id = in_rss_feed_item_id
		   AND owner_sid = v_user_sid
			OR (rss_feed_item_id = in_rss_feed_item_id
				AND v_user_sid = (SELECT owner_sid
								  FROM   rss_feed
								  WHERE  rss_feed_sid = v_rss_feed_sid)); 
	IF v_count = 1 THEN
		DELETE FROM rss_feed_item 
		   WHERE rss_feed_item_id = in_rss_feed_item_id;
	ELSE
	-- it's not the item owner, nor the feed owner
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
			'You have no permission to delete this item');			
	END IF;
	
END;
	
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
)
AS
  v_rss_feed_sid  security_pkg.T_SID_ID;
  v_act_id        security_pkg.T_ACT_ID;
BEGIN
  v_act_id    := security_pkg.GetAct();

  v_rss_feed_sid := GetFeedSidForItemId(in_rss_feed_item_id);
	-- check permission here
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_rss_feed_sid,  security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating feed item');
	END IF;
	
	UPDATE rss_feed_item 
	   SET 
		title = in_title,
		description = in_description,
		link = in_link,
		published_dtm = in_published_dtm
	WHERE
		rss_feed_item_id = in_rss_feed_item_id;
	
	GetFeedItem(in_rss_feed_item_id, out_cur);

END;



PROCEDURE UpdateFeedXml(
	in_rss_feed_sid 		IN  RSS_FEED.rss_feed_sid%TYPE,
--	out_xml			    OUT	XMLType
  in_xml              IN XMLType
)
AS
  v_act_id    security_pkg.T_ACT_ID;
BEGIN
  v_act_id    := security_pkg.GetAct();

  -- check permission....
  -- hmmm... shall we check this permissoin here ? ? is just update, so in any case the security should be checking while making changes actually to prevent...
  -- otherwise let's say the hole will allow to change db records but the update script will not let to update xml which will create some discrepencies, am I correct?
/*	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_rss_feed_sid,  security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied getting feed');
	END IF;*/
	
	UPDATE RSS_FEED
     SET xml = in_xml,
					last_modified_dtm = SYSDATE
   WHERE rss_feed_sid = in_rss_feed_sid;
 
END;




PROCEDURE GetFeed(
	in_rss_feed_sid 		IN	RSS_FEED.rss_feed_sid%TYPE,
	out_cur		      		OUT security_pkg.T_OUTPUT_CUR
)
AS
  v_user_sid        security_pkg.T_SID_ID;
  v_act_id          security_pkg.T_ACT_ID;
BEGIN
  v_user_sid  := security_pkg.GetSid();
  v_act_id    := security_pkg.GetAct();
  
  -- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_rss_feed_sid,  security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied getting feed');
	END IF;

	OPEN out_cur FOR
    SELECT rss_feed_sid,
           name,
           description,
           Internal_getispublic(rss_feed_sid)                    is_public,
           CASE
             WHEN owner_sid = v_user_sid THEN 1
             ELSE 0
           END                                                   is_owner,
					 rf.last_modified_dtm,
           cu.full_name                                          owner_name,
           cu.email                                              owner_email,
           securableobject_pkg.Getname(v_act_id,in_rss_feed_sid) so_name
    FROM   rss_feed rf,
           csr_user cu
    WHERE  rf.owner_sid = cu.csr_user_sid
      AND rss_feed_sid = in_rss_feed_sid; 
END;


PROCEDURE GetFeedWithItems(
	in_rss_feed_sid 		  IN	security_pkg.T_SID_ID,
	feed_cur  	      		OUT security_pkg.T_OUTPUT_CUR,
	items_cur		      		OUT security_pkg.T_OUTPUT_CUR
)

AS
  v_act_id    security_pkg.T_ACT_ID;
  v_user_sid        security_pkg.T_SID_ID;
BEGIN
  v_act_id    := security_pkg.GetAct();
  v_user_sid  := security_pkg.GetSid();

  -- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_rss_feed_sid,  security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading feed with SID '||in_rss_feed_sid);
	END IF;
 
	-- fetch feed details
	GetFeed(in_rss_feed_sid, feed_cur);

	-- get items for feed
  OPEN items_cur FOR
		SELECT  rss_feed_item_id,
						 title,
						 description,
						 published_dtm,
						 link
						 ||rss_feed_item_id link,
						 owner_sid,
             cu.full_name    owner_name,
             cu.email    owner_email
		 FROM    rss_feed_item rfi,
             csr_user cu
    WHERE rfi.owner_sid = cu.csr_user_sid
		  AND rss_feed_sid = in_rss_feed_sid
			AND published_dtm IS NOT NULL
		ORDER BY published_dtm DESC; 

END;


/*
 *	Get Feed Item
 */
PROCEDURE GetFeedItem(
	in_rss_feed_item_id IN	RSS_FEED_ITEM.rss_feed_item_id%TYPE,
	out_cur		      	OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid		security_pkg.T_SID_ID;
  v_act_id    security_pkg.T_ACT_ID;
  v_rss_feed_sid security_pkg.T_SID_ID;
BEGIN
	v_app_sid 	:= security_pkg.GetApp();
	v_act_id    := security_pkg.GetAct();

  -- get rss_feed_sid to be able to check security before fetching full set
  SELECT rss_feed_sid 
    INTO v_rss_feed_sid 
    FROM rss_feed_item 
   WHERE rss_feed_item_id = in_rss_feed_item_id;

  -- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_rss_feed_sid,  security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied getting feed items');
	END IF;
	
	OPEN out_cur FOR
			SELECT RSS_FEED_ITEM_ID, rss_feed_sid, title, description, published_dtm,  published_dtm, link || rss_feed_item_id link , owner_sid, 
			(SELECT full_name 
			   FROM csr_user 
			  WHERE csr_user_sid = owner_sid) owner_name
		  FROM rss_feed_item
		 WHERE rss_feed_item_id = in_rss_feed_item_id;
END;

 

/*
 *	cached feeds
 */
PROCEDURE GetCachedFeedsList(
    out_cur		      OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	v_app_sid := security_pkg.GetApp();
	
	OPEN out_cur FOR
		SELECT rc.rss_url, rc.last_updated, drf.name
		  FROM rss_cache rc, default_rss_feed drf
		 WHERE rc.rss_url = drf.rss_url
		   AND drf.app_sid = v_app_sid;
END;


PROCEDURE SetCachedFeed(
  in_rss_url        default_rss_feed.rss_url%TYPE,
  in_rss_name       default_rss_feed.name%TYPE
)
AS
    v_app_sid	security_pkg.T_SID_ID;
BEGIN
    v_app_sid := security_pkg.GetApp();
    
    BEGIN
        INSERT INTO RSS_CACHE (rss_url)
          VALUES (in_rss_url);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL; -- ignore
    END;
    
    
    BEGIN
		 INSERT INTO DEFAULT_RSS_FEED (app_sid, rss_url, name)
				VALUES (v_app_sid, in_rss_url, in_rss_name);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
			 UPDATE DEFAULT_RSS_FEED
				SET name = in_rss_name
			WHERE app_sid = v_app_sid
			  AND rss_url = in_rss_url;
    END;

END;


PROCEDURE RemoveCachedFeed(
	in_rss_url			IN RSS_CACHE.rss_url%TYPE
)
AS
	v_app_sid	security_pkg.T_SID_ID;
	v_in_use		NUMBER;
BEGIN
   v_app_sid := security_pkg.GetApp();
	
	DELETE FROM DEFAULT_RSS_FEED 
			 WHERE app_sid = v_app_sid 
			   AND rss_url = in_rss_url;
	
	-- delete the association to portlets
	-- in case the feed was in use
  DELETE FROM TAB_PORTLET_RSS_FEED 
  WHERE tab_portlet_id IN (
    SELECT tprf.tab_portlet_id 
      FROM tab_portlet_rss_feed tprf, tab_portlet tp, tab t
     WHERE t.tab_id = tp.tab_id
       AND tp.tab_portlet_id = tprf.tab_portlet_id
       AND t.app_sid= v_app_sid
       AND tprf.rss_url = in_rss_url
  );

	-- remove from rss_cache if not in use anymore
   SELECT COUNT(*) 
	INTO v_in_use 
	FROM DEFAULT_RSS_FEED
	WHERE rss_url = in_rss_url;
	
	IF v_in_use = 0 THEN
  
		DELETE FROM RSS_CACHE 
				 WHERE rss_url = in_rss_url;
	END IF;
END;


PROCEDURE GetModifiedDtm(
	in_feed_sid			IN	rss_feed.rss_feed_sid%TYPE,
	out_modified_dtm	OUT	rss_feed.last_modified_dtm%TYPE
)
AS
BEGIN
	-- TODO: does this need a security check?  The original code didn't have one.
	BEGIN
		SELECT last_modified_dtm
		  INTO out_modified_dtm
		  FROM rss_feed
		 WHERE rss_feed_sid = in_feed_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_modified_dtm := NULL;
	END;
END;

END rss_pkg;
/
