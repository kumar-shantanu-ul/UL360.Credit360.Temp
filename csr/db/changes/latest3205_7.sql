-- Please update version.sql too -- this keeps clean builds in sync
define version=3205
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.alert_frame_body
   SET html = REPLACE(html, '<img alt="Message body" title="The body of the message" style="vertical-align:middle" src="/csr/site/alerts/renderMergeField.ashx?field=BODY&'||'amp;text=Message+body&'||'amp;lang=en"></img>', '<mergefield name="BODY" />')
 WHERE html LIKE '%<img alt="Message body" title="The body of the message" style="vertical-align:middle" src="/csr/site/alerts/renderMergeField.ashx?field=BODY&'||'amp;text=Message+body&'||'amp;lang=en"></img>%';

UPDATE csr.default_alert_frame_body
   SET html = REPLACE(html, '<img alt="Message body" title="The body of the message" style="vertical-align:middle" src="/csr/site/alerts/renderMergeField.ashx?field=BODY&'||'amp;text=Message+body&'||'amp;lang=en"></img>', '<mergefield name="BODY" />')
 WHERE html LIKE '%<img alt="Message body" title="The body of the message" style="vertical-align:middle" src="/csr/site/alerts/renderMergeField.ashx?field=BODY&'||'amp;text=Message+body&'||'amp;lang=en"></img>%';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
