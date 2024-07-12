PROMPT >> Setting up scheduled alerts
BEGIN
	INSERT INTO chain.alert_entry_param_type (alert_entry_param_type_id, description) VALUES (chain.chain_pkg.ORDERED_PARAMS, 'Ordered params applied using String.Format("{0} are being used", "Ordered Params")');
	INSERT INTO chain.alert_entry_param_type (alert_entry_param_type_id, description) VALUES (chain.chain_pkg.NAMED_PARAMS, 'Named params applied using String.Format("{paramType} are being used", new KeyValuePair<string, string>("paramType", "Named Params"))');
		
	INSERT INTO chain.alert_entry_type (alert_entry_type_id, description, generator_pkg) VALUES (chain.chain_pkg.EVENT_ALERT, 'Chain event alerts', 'chain.event_pkg');
	INSERT INTO chain.alert_entry_type (alert_entry_type_id, description, generator_pkg) VALUES (chain.chain_pkg.ACTION_ALERT, 'Chain action alerts', 'chain.action_pkg');
END;
/
