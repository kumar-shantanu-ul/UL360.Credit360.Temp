-- Please update version.sql too -- this keeps clean builds in sync
define version=3442
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.gresb_service_config ADD (
	OAUTH_URL           VARCHAR2(255) 
);


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.gresb_service_config
   SET client_id = 'kmVpq1pFvf5YMoTTqPnrzWPT9T4IZ9n3nozcwB6TUZ0',
	   client_secret = '-DPrH555MjIgM2GMpIaXjq53a1rFp4X6odd26uHjDz0',
	   url = 'https://demo-api.gresb.com',
       oauth_url = 'https://demo-portal.gresb.com'
 WHERE name = 'sandbox';
 
 UPDATE csr.gresb_service_config
   SET client_id = 'KEfVI74RtLMc11jajkb_OHY7NVcYYV5S1uNv2cxG5D0',
       client_secret = 'mfZBnzPrWbaI3SIDcKx-1ldXzIHcXS-nnIPed1SStpc',
       oauth_url = 'https://portal.gresb.com'
 WHERE name = 'live';
 
 ALTER TABLE csr.gresb_service_config MODIFY OAUTH_URL NOT NULL;
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../property_body

@update_tail
