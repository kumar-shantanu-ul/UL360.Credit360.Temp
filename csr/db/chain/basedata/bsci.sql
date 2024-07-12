BEGIN
	INSERT INTO chain.bsci_rsp (rsp_id, label)
	VALUES (1, 'Yes');

	INSERT INTO chain.bsci_rsp (rsp_id, label)
	VALUES (2, 'No');

	INSERT INTO chain.bsci_rsp (rsp_id, label)
	VALUES (3, 'Orphan');

	INSERT INTO chain.bsci_rsp (rsp_id, label)
	VALUES (4, 'Idle');
END;
/