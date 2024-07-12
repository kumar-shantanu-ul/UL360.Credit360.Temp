-- Please update version.sql too -- this keeps clean builds in sync
define version=2508
@update_header

-- Defra 2013 SID is 35
UPDATE csr.std_factor 
SET start_dtm=date '1990-01-01'
WHERE std_factor_set_id=35
AND factor_type_id IN (SELECT factor_type_id FROM csr.factor_type WHERE name LIKE '%Road Vehicle Distance%Motorbike%Average%Gasoline%')
AND end_dtm = '01-JAN-13';

-- Defra 2014 SID is 49
UPDATE csr.std_factor 
SET start_dtm=date '1990-01-01'
WHERE std_factor_set_id=49
AND factor_type_id IN (SELECT factor_type_id FROM csr.factor_type WHERE name LIKE '%Road Vehicle Distance%Motorbike%Average%Gasoline%')
AND end_dtm = '01-JAN-13';

@update_tail