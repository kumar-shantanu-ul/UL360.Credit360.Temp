-- Please update version.sql too -- this keeps clean builds in sync
define version=45
@update_header

PROMPT Add CAS numbers and effect to chem table

ALTER TABLE SUPPLIER.GT_HAZZARD_CHEMICAL
 ADD (CAS_NUMBER  VARCHAR2(32 BYTE));

ALTER TABLE SUPPLIER.GT_HAZZARD_CHEMICAL
 ADD (ENV_EFFECT  VARCHAR2(1024 BYTE));

-- red 
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '64-17-5 3', ENV_EFFECT='High usage and high experimental partitioning to aqueous phase ' WHERE gt_hazzard_chemical_id = 1;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = null, ENV_EFFECT='High usage and high experimental partitioning to aqueous phase ' WHERE gt_hazzard_chemical_id = 2;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '112-02-7 7', ENV_EFFECT='High usage and potent experimental ecotoxicity value' WHERE gt_hazzard_chemical_id = 3;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '541-02-6 3', ENV_EFFECT='High usage and potent ecotoxicity estimate' WHERE gt_hazzard_chemical_id = 4;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = null, ENV_EFFECT='Very potent estimate of ecotoxicity / Extremely high estimated partitioning to sludge and extremely potent daphnid ecotoxicity estimate' WHERE gt_hazzard_chemical_id = 5;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '1119-97-7', ENV_EFFECT='Very potent experimental ecotoxicity ' WHERE gt_hazzard_chemical_id = 6;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '4390-04-9;60908-77-2', ENV_EFFECT=' High usage very potent estimate of ecotoxicity / high estimated partitioning to sludge' WHERE gt_hazzard_chemical_id = 7;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '19666-16-1', ENV_EFFECT='High usage and very potent estimate of ecotoxicity' WHERE gt_hazzard_chemical_id = 8;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '5333-42-6 3', ENV_EFFECT='Potent default ecotoxicity used' WHERE gt_hazzard_chemical_id = 9;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '3380-34-5', ENV_EFFECT='Very toxic to aquatic organisms' WHERE gt_hazzard_chemical_id = 10;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '13463-41-7', ENV_EFFECT='High partitioning to water and very potent experimental ecotoxicity' WHERE gt_hazzard_chemical_id = 11;


--orange 
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '97-59-6 3', ENV_EFFECT='Default daphnid ecotoxicity value used ' WHERE gt_hazzard_chemical_id = 12;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '64-17-5 3', ENV_EFFECT='High usage and high experimental partitioning to aqueous phase ' WHERE gt_hazzard_chemical_id = 13;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '12042-91-0', ENV_EFFECT='Potent default ecotoxicity used' WHERE gt_hazzard_chemical_id = 14;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '68411-27-8 3', ENV_EFFECT='High usage and potent estimated ecotoxicity' WHERE gt_hazzard_chemical_id = 15;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '61789-40-0', ENV_EFFECT='High usage  ' WHERE gt_hazzard_chemical_id = 16;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '540-97-6 3', ENV_EFFECT='High usage and potent ecotoxicity estimate Collate ' WHERE gt_hazzard_chemical_id = 17;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '65381-09-1;73398-61-5', ENV_EFFECT='High usage limited data on constituents and constituent composition, high partitioning estimates to sludge and soil and high earthworm ecotoxicity estimates' WHERE gt_hazzard_chemical_id = 18;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '7789-77-7 4', ENV_EFFECT='Potent default ecotoxicity used ' WHERE gt_hazzard_chemical_id = 19;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '22047-49-0 3', ENV_EFFECT='High usage high estimated partitioning to sludge and potent earthworm ecotoxicity estimate' WHERE gt_hazzard_chemical_id = 20;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '52304-36-6', ENV_EFFECT='High usage and high partitioning to water and moderate ecotoxicity estimate' WHERE gt_hazzard_chemical_id = 21;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '118-60-5', ENV_EFFECT='High usage potent experimental ecotoxicity estimate' WHERE gt_hazzard_chemical_id = 22;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '111-60-4 3', ENV_EFFECT='High usage and potent ecotoxicity estimate / potent daphnid ecotoxicity estimate' WHERE gt_hazzard_chemical_id = 23;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '3055-97-8 3', ENV_EFFECT='High estimated partitioning to water and potent default ecotoxicity estimate used' WHERE gt_hazzard_chemical_id = 24;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '5274-68-0', ENV_EFFECT='Default daphnid ecotoxicity value used ' WHERE gt_hazzard_chemical_id = 25;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '557-04-0', ENV_EFFECT='Potent default ecotoxicity used ' WHERE gt_hazzard_chemical_id = 26;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '103597-45-1', ENV_EFFECT='High usage extremely high estimated partitioning to sludge and high potent earthworm ecotoxicity estimate' WHERE gt_hazzard_chemical_id = 27;
UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '1338-41-6 3', ENV_EFFECT='Potent ecotoxicity ' WHERE gt_hazzard_chemical_id = 28;


 
 
 
@update_tail
