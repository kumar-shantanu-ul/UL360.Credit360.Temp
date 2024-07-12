-- Please update version.sql too -- this keeps clean builds in sync
define version=1691
@update_header

whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

SET DEFINE OFF;

BEGIN

INSERT INTO csr.std_factor_set (std_factor_set_id, name)
VALUES (24, 'Australia National Greenhouse Accounts (NGA) 2012');

INSERT INTO csr.std_factor_set (std_factor_set_id, name)
VALUES (25, 'China National Bureau of Statistics');

INSERT INTO csr.std_factor_set (std_factor_set_id, name)
VALUES (26, 'Taiwan Bureau of Energy');

INSERT INTO csr.std_factor_set (std_factor_set_id, name)
VALUES (27, 'Canada National Inventory Report 2012 (1990-2010)');

INSERT INTO csr.std_factor_set (std_factor_set_id, name)
VALUES (28, 'Canada National Inventory Report 2013 (1990-2011)');

INSERT INTO csr.std_factor_set (std_factor_set_id, name)
VALUES (29, 'New Zealand Ministry for the Environment');

COMMIT;
END;
/

@update_tail