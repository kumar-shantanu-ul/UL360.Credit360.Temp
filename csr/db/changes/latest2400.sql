-- Please update version.sql too -- this keeps clean builds in sync
define version=2400
@update_header

DELETE FROM csr.plugin
      WHERE plugin_id IN (
		SELECT p.plugin_id
		  FROM csr.plugin p
		  LEFT JOIN csr.teamroom_type_tab ttt on p.plugin_id = ttt.plugin_id
		 WHERE js_class = 'MarksAndSpencer.Teamroom.InitiativesPanel'
		   AND ttt.plugin_id IS NULL
	);
	
-- Putting this in as I am fed up with something/someone inserting customer plugins without an app_sid
-- if this breaks on your dev environment it means you have a customer plugin without an app_sid, 
-- you can either fix it putting the relevant app_sid in, or if you don't care/dont use that plugin, just remove them with
-- DELETE FROM csr.plugin
--       WHERE app_sid IS NULL
--         AND js_include NOT LIKE '/csr/%';
delete from csr.plugin where not (app_sid IS NOT NULL OR (app_sid IS NULL AND js_include LIKE '/csr/%'));

ALTER TABLE csr.plugin ADD 
CONSTRAINT chk_core_plugin_is_core CHECK (app_sid IS NOT NULL OR (app_sid IS NULL AND js_include LIKE '/csr/%'));

@update_tail
