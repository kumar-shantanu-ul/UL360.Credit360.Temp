-- Please update version.sql too -- this keeps clean builds in sync
define version=1021
@update_header

BEGIN
	BEGIN
		INSERT INTO ct.currency (currency_id, description, symbol) VALUES (1, 'U.S. Dollar', 'USD');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ct.currency 
			   SET description = 'U.S. Dollar',
				   symbol = 'USD'
			 WHERE currency_id = 1;
	END;

	BEGIN
		INSERT INTO ct.currency (currency_id, description, symbol) VALUES (2, 'British Pound', 'GBP');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ct.currency 
			   SET description = 'British Pound',
				   symbol = 'GBP'
			 WHERE currency_id = 2;
	END;

	BEGIN
		INSERT INTO ct.currency (currency_id, description, symbol) VALUES (3, 'E.U. Euro', 'EUR');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ct.currency 
			   SET description = 'E.U. Euro',
				   symbol = 'EUR'
			 WHERE currency_id = 3;
	END;

	BEGIN
		INSERT INTO ct.currency (currency_id, description, symbol) VALUES (4, 'Chinese Yuan Renminbi', 'CNY');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ct.currency 
			   SET description = 'Chinese Yuan Renminbi',
				   symbol = 'CNY'
			 WHERE currency_id = 4;
	END;

	BEGIN
		INSERT INTO ct.currency (currency_id, description, symbol) VALUES (5, 'Australian Dollar', 'AUD');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ct.currency 
			   SET description = 'Australian Dollar',
				   symbol = 'AUD'
			 WHERE currency_id = 5;
	END;

	BEGIN
		INSERT INTO ct.currency (currency_id, description, symbol) VALUES (6, 'Japanese Yen', 'JPY');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ct.currency 
			   SET description = 'Japanese Yen',
				   symbol = 'JPY'
			 WHERE currency_id = 6;
	END;
END;
/

@update_tail
