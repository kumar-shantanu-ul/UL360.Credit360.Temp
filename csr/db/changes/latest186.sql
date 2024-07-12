-- Please update version.sql too -- this keeps clean builds in sync
define version=186
@update_header


-- 
-- SEQUENCE: RSS_FEED_ITEM_ID_SEQ 
--

CREATE SEQUENCE RSS_FEED_ITEM_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

-- 
-- TABLE: DEFAULT_RSS_FEED 
--

CREATE TABLE DEFAULT_RSS_FEED(
    APP_SID    NUMBER(10, 0)     NOT NULL,
    RSS_URL    VARCHAR2(1024)    NOT NULL,
    NAME       VARCHAR2(255),
    CONSTRAINT PK445 PRIMARY KEY (APP_SID, RSS_URL)
)
;



-- 
-- TABLE: RSS_CACHE 
--

CREATE TABLE RSS_CACHE(
    RSS_URL         VARCHAR2(1024)    NOT NULL,
    LAST_UPDATED    DATE,
    XML             SYS.XMLType,
    CONSTRAINT PK446 PRIMARY KEY (RSS_URL)
)
;



-- 
-- TABLE: RSS_FEED 
--

CREATE TABLE RSS_FEED(
    RSS_FEED_SID    NUMBER(10, 0)     NOT NULL,
    APP_SID         NUMBER(10, 0)     NOT NULL,
    NAME            VARCHAR2(256),
    DESCRIPTION     VARCHAR2(1024),
    OWNER_SID       NUMBER(10, 0)     NOT NULL,
    CONSTRAINT PK_RSS_FEED PRIMARY KEY (RSS_FEED_SID)
)
;



-- 
-- TABLE: RSS_FEED_ITEM 
--

CREATE TABLE RSS_FEED_ITEM(
    RSS_FEED_ITEM_ID    NUMBER(10, 0)     NOT NULL,
    RSS_FEED_SID        NUMBER(10, 0)     NOT NULL,
    TITLE               VARCHAR2(255)     NOT NULL,
    DESCRIPTION         CLOB,
    PUBLISHED_DTM       DATE              DEFAULT SYSDATE,
    LINK                VARCHAR2(1024)    NOT NULL,
    OWNER_SID           NUMBER(10, 0)     NOT NULL,
    CONSTRAINT PK448 PRIMARY KEY (RSS_FEED_ITEM_ID)
)
;


-- 
-- TABLE: TAB_PORTLET_RSS_FEED 
--

CREATE TABLE TAB_PORTLET_RSS_FEED(
    TAB_PORTLET_ID    NUMBER(10, 0)     NOT NULL,
    RSS_URL           VARCHAR2(1024)    NOT NULL,
    CONSTRAINT PK449 PRIMARY KEY (TAB_PORTLET_ID, RSS_URL)
)
;

-- 
-- TABLE: DEFAULT_RSS_FEED 
--

ALTER TABLE DEFAULT_RSS_FEED ADD CONSTRAINT RefCUSTOMER880 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

ALTER TABLE DEFAULT_RSS_FEED ADD CONSTRAINT RefRSS_CACHE881 
    FOREIGN KEY (RSS_URL)
    REFERENCES RSS_CACHE(RSS_URL)
;



-- 
-- TABLE: RSS_FEED 
--

ALTER TABLE RSS_FEED ADD CONSTRAINT RefCUSTOMER882 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

ALTER TABLE RSS_FEED ADD CONSTRAINT RefCSR_USER883 
    FOREIGN KEY (OWNER_SID)
    REFERENCES CSR_USER(CSR_USER_SID)
;


-- 
-- TABLE: RSS_FEED_ITEM 
--

ALTER TABLE RSS_FEED_ITEM ADD CONSTRAINT RefCSR_USER884 
    FOREIGN KEY (OWNER_SID)
    REFERENCES CSR_USER(CSR_USER_SID)
;

ALTER TABLE RSS_FEED_ITEM ADD CONSTRAINT RefRSS_FEED885 
    FOREIGN KEY (RSS_FEED_SID)
    REFERENCES RSS_FEED(RSS_FEED_SID)
;



-- 
-- TABLE: TAB_PORTLET_RSS_FEED 
--

ALTER TABLE TAB_PORTLET_RSS_FEED ADD CONSTRAINT RefTAB_PORTLET886 
    FOREIGN KEY (TAB_PORTLET_ID)
    REFERENCES TAB_PORTLET(TAB_PORTLET_ID)
;

ALTER TABLE TAB_PORTLET_RSS_FEED ADD CONSTRAINT RefRSS_CACHE887 
    FOREIGN KEY (RSS_URL)
    REFERENCES RSS_CACHE(RSS_URL)
;




/*
 * security  config for Rss Feed
 */

 DECLARE
	new_class_id 	security_pkg.T_SID_ID;
	v_act 			security_pkg.T_ACT_ID;
	v_attribute_id	security_pkg.T_ATTRIBUTE_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	

	
	-- create csr classes
	BEGIN	
		class_pkg.CreateClass(v_act, NULL, 'RssFeed', 'csr.rss_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=class_pkg.GetClassId('RssFeed');
	END;
	
	user_pkg.LOGOFF(v_ACT);
END;
/


COMMIT;

@../rss_pkg
@../rss_body

-- grant security to access rss_pkg
grant execute on rss_pkg to security;

@update_tail
