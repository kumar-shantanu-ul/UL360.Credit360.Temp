-- Please update version.sql too -- this keeps clean builds in sync
define version=3224
define minor_version=1
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
BEGIN
	-- Missing basedata related to imp/exp. Prod is fine as it run the latest, but any newer databases won't be, so putting this
	-- in to try and set all databases to the correct set.
	BEGIN
		INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (1, 'DataView Exporter');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN
		INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (2, 'DataView Exporter (Xml Mappable)');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN
		INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (3, 'Batched Exporter');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN
		INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (4, 'Stored Procedure Exporter');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	UPDATE csr.auto_exp_exporter_plugin SET plugin_type_id = 1 WHERE plugin_id = 1;
	UPDATE csr.auto_exp_exporter_plugin SET plugin_type_id = 1 WHERE plugin_id = 2;
	UPDATE csr.auto_exp_exporter_plugin SET plugin_type_id = 1 WHERE plugin_id = 3;
	UPDATE csr.auto_exp_exporter_plugin SET plugin_type_id = 4 WHERE plugin_id = 13;
	UPDATE csr.auto_exp_exporter_plugin SET plugin_type_id = 3 WHERE plugin_id = 19;
	UPDATE csr.auto_exp_exporter_plugin SET plugin_type_id = 2 WHERE plugin_id = 21;
	UPDATE csr.auto_exp_exporter_plugin SET plugin_type_id = 2 WHERE plugin_id = 22;

END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
