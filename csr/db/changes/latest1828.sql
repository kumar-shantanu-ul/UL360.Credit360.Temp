-- Please update version.sql too -- this keeps clean builds in sync
define version=1828
@update_header

UPDATE CSR.STD_FACTOR SET value = 2.5443 WHERE std_factor_id = 184332957;
UPDATE CSR.STD_FACTOR SET value = 2.538 WHERE std_factor_id = 184324792;
UPDATE CSR.STD_FACTOR SET value = 1.5326 WHERE std_factor_id = 184332958;
UPDATE CSR.STD_FACTOR SET value = 1.4929 WHERE std_factor_id = 184324794;

@update_tail