
-- Please update version.sql too -- this keeps clean builds in sync
define version=193
@update_header

ALTER TABLE RSS_FEED ADD (xml SYS.XMLType);

@..\portlet_pkg
@..\portlet_body
@..\rss_pkg
@..\rss_body

@update_tail

