-- Please update version.sql too -- this keeps clean builds in sync
define version=1690
@update_header

whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

SET DEFINE OFF;

BEGIN
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (2,'eGrid');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (7,'Greenhouse Gas Protocol V1.2');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (19,'Agrianual 2007 - Brazilian Agricultural Yearbook');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (20,'Intergovernmental Panel on Climate Change (IPCC) 2006 (Commercial & Institutional)');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (5,'Canada National Inventory Report 2011 (1990-2009)');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (6,'North American Climate Registry (2011)');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (9,'eGrid v1.1');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (12,'eGrid (Static Time Series)');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (18,'International Energy Agency (IEA) 2012');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (3,'Greenhouse Gas Protocol V1.1');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (4,'Australia National Greenhouse Accounts (NGA) 2011');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (11,'eGrid 2012 (2009) - State');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (13,'International Energy Agency (IEA) 2011');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (14,'UK Department for Environment, Food & Rural Affairs (Defra) - Time Series 2007-2012');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (15,'UK Department for Environment, Food & Rural Affairs (Defra) - 2012');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (16,'US Environmental Protection Agency eGRID (Sub Region & US Average)');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (17,'US EPA eGRID Sub Region (Non-Baseload) TS');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (1,'UK Department for Environment, Food & Rural Affairs (Defra) - 2010');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (8,'UK Department for Environment, Food & Rural Affairs (Defra) - 2011');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	BEGIN
		INSERT INTO CSR.STD_FACTOR_SET (STD_FACTOR_SET_ID, NAME) VALUES (10,'eGrid 2012 (2009)');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

END;
/


BEGIN

UPDATE csr.std_factor_set
    SET name = CASE name
        WHEN 'Climate Registry'           THEN 'North American Climate Registry'
        WHEN 'DEFRA'                      THEN 'UK Department for Environment, Food & Rural Affairs (Defra) – 2010'
        WHEN 'DEFRA 2011'                 THEN 'UK Department for Environment, Food & Rural Affairs (Defra) – 2011'
        WHEN 'Defra 2012'                 THEN 'UK Department for Environment, Food & Rural Affairs (Defra) – 2012'
        WHEN 'Defra TS'                   THEN 'UK Department for Environment, Food & Rural Affairs (Defra) – Time Series 2007-2012'
        WHEN 'GHG Protocol'               THEN 'Greenhouse Gas Protocol V1.1'
        WHEN 'GHG Protocol - v1.2 (2011)' THEN 'Greenhouse Gas Protocol V1.2'
        WHEN 'IEA 2011'                   THEN 'International Energy Agency (IEA) 2011'
        WHEN 'IEA 2012'                   THEN 'International Energy Agency (IEA) 2012'
        WHEN 'Intergovernmental Panel on Climate Change (IPCC)' THEN 'Intergovernmental Panel on Climate Change (IPCC) 2006'
        WHEN 'NGA'                        THEN 'Australia National Greenhouse Accounts (NGA) 2011'
        WHEN 'US EPA eGRID Sub Region (Average Load) TS'        THEN 'US Environmental Protection Agency eGRID (Sub Region & US Average)'
        ELSE name
    END;

INSERT INTO csr.std_factor_set (std_factor_set_id, name)
VALUES (21, 'Greenhouse Gas Protocol V1.3');

INSERT INTO csr.std_factor_set (std_factor_set_id, name)
VALUES (22, 'US Environmental Protection Agency eGRID (State)');

INSERT INTO csr.std_factor_set (std_factor_set_id, name)
VALUES (23, 'North American Climate Registry (2012)');

COMMIT;
END;
/

@update_tail