-- Please update version.sql too -- this keeps clean builds in sync
define version=54
@update_header

PROMPT reupload product types

update gt_product_answers set gt_product_type_id = null;

delete from GT_PRODUCT_TYPE;

PROMPT Insert new Dental gt prod type group

UPDATE GT_PRODUCT_TYPE_GROUP SET GT_PRODUCT_TYPE_GROUP_ID = 9 
WHERE GT_PRODUCT_TYPE_GROUP_ID = 8;

INSERT INTO GT_PRODUCT_TYPE_GROUP (
   GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION) 
VALUES (8 , 'Dental');

PROMPT Now pump in the actual final data for product types

INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(1 ,1 ,'Shower Gel /cream' ,75 ,1 ,20 ,2 ,3 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(2 ,1 ,'Hair and Body wash' ,75 ,1 ,20 ,2 ,3 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(3 ,1 ,'Bath Foam / soak' ,75 ,2 ,20 ,2 ,4 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(4 ,1 ,'Bubble bath' ,75 ,2 ,20 ,2 ,4 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(5 ,1 ,'Hand Wash' ,75 ,3 ,20 ,4 ,2 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(6 ,1 ,'Bath Oil' ,0 ,2 ,20 ,2 ,4 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(7 ,1 ,'Bath Salts' ,0 ,2 ,20 ,2 ,4 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(8 ,1 ,'Detergent Body Scrub' ,62.5 ,1 ,20 ,2 ,3 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(9 ,1 ,'Emulsion Body Scrub' ,80 ,1 ,20 ,4 ,3 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(10 ,1 ,'Salt / Sugar Scrub' ,0 ,1 ,20 ,4 ,3 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(11 ,1 ,'Soap (Bar)' ,0 ,2 ,20 ,4 ,4 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(12 ,1 ,'Talc' ,0 ,4 ,10 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(13 ,2 ,'Pre shave' ,0 ,4 ,10 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(14 ,2 ,'Mens aftershave lotion / balm' ,75 ,4 ,20 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(15 ,2 ,'Shave gel' ,75 ,3 ,20 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(16 ,3 ,'Hand Cream' ,77.5 ,4 ,20 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(17 ,3 ,'Hand Cream SPF' ,65 ,4 ,20 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(18 ,3 ,'Body Cream' ,70 ,4 ,20 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(19 ,3 ,'Body Lotion' ,80 ,4 ,20 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(20 ,3 ,'Body / massage oil' ,0 ,4 ,20 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(21 ,4 ,'Cleanser' ,75 ,4 ,20 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(22 ,4 ,'Toner' ,87.5 ,4 ,20 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(23 ,4 ,'Day Cream' ,62.5 ,4 ,20 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(24 ,4 ,'Night Cream' ,75 ,4 ,20 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(25 ,4 ,'Serum - Water / Silicone' ,32.5 ,4 ,10 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(26 ,4 ,'Serum - Oil / Water' ,82.5 ,4 ,10 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(27 ,4 ,'Exfoliator (Detergent)' ,77.5 ,3 ,10 ,2 ,2 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(28 ,4 ,'Exfoliator (Emulsion)' ,80 ,3 ,10 ,4 ,2 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(29 ,4 ,'Facial Wash (Detergent) - premium' ,75 ,3 ,20 ,3 ,2 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(30 ,4 ,'Facial Wash (Detergent) - Good' ,75 ,3 ,20 ,2 ,2 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(31 ,4 ,'Facial Wash (Emulsion)' ,77.5 ,3 ,20 ,4 ,2 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(32 ,4 ,'Moisturiser' ,75 ,4 ,20 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(33 ,4 ,'Eye Cream' ,77.5 ,4 ,5 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(34 ,4 ,'Wipes' ,7.5 ,4 ,2 ,3 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(35 ,4 ,'Anti-perspirant - Roll On' ,75 ,4 ,1 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(36 ,4 ,'Anti-perspirant - Aerosol' ,0 ,4 ,5 ,2 ,2 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(37 ,4 ,'Anti-perspirant - Stick' ,0 ,4 ,1 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(38 ,4 ,'Deodorants - Wipe' ,75 ,4 ,1 ,3 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(39 ,4 ,'Lip Salve (Oily)' ,0 ,4 ,2 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(40 ,4 ,'Lip Cream' ,60 ,4 ,2 ,3 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(41 ,4 ,'Gel Cream' ,75 ,4 ,2 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(42 ,4 ,'Emulsion Spray' ,57.5 ,4 ,2 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(43 ,5 ,'Shampoo - Clear' ,75 ,1 ,20 ,2 ,3 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(44 ,5 ,'Shampoo - Cold pearl' ,75 ,1 ,20 ,2 ,3 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(45 ,5 ,'Shampoo - Hot pearl' ,75 ,1 ,20 ,4 ,3 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(46 ,5 ,'Conditioner (including Intensive)' ,88 ,1 ,20 ,4 ,3 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(47 ,5 ,'Conditioner (Leave In)' ,96.5 ,4 ,20 ,4 ,2 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(48 ,5 ,'Serum (Silicone)' ,0 ,4 ,10 ,2 ,2 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(49 ,5 ,'Heat Spray' ,50 ,4 ,5 ,2 ,2 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(50 ,5 ,'Styling Spray' , 0,4 ,10 ,2 ,2 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(51 ,5 ,'Hair Spray (non aerosol)' ,27.5 ,4 ,10 ,2 ,2 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(52 ,5 ,'Wax' ,0 ,4 ,20 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(53 ,5 ,'Gel' ,94 ,4 ,20 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(54 ,5 ,'Clay' ,0 ,4 ,20 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(55 ,5 ,'Ringing Gel' ,30 ,4 ,10 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(56 ,5 ,'Shine Spray (Si / ETOH)' ,0 ,4 ,10 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(57 ,5 ,'Straightening / curling balm' ,96.5 ,4 ,20 ,4 ,2 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(58 ,5 ,'Curl cream' ,88.5 ,4 ,10 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(59 ,5 ,'Waterproof Gellee' ,21 ,4 ,10 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(60 ,5 ,'Hair Colourant' ,65 ,1 ,-1 ,4 ,2 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(61 ,5 ,'Putty' ,47.5 ,4 ,5 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(62 ,6 ,'Nail Polish' ,0 ,4 ,2 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(63 ,6 ,'Lipsticks' ,0 ,4 ,2 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(64 ,6 ,'Foundation W/S' ,35 ,4 ,2 ,3 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(65 ,6 ,'Foundation O/W' ,60 ,4 ,2 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(66 ,6 ,'Eyeshadow' ,0 ,4 ,2 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(67 ,6 ,'EMUR Pads' ,0 ,4 ,2 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(68 ,6 ,'EMUR Lotion' ,62.5 ,4 ,20 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(69 ,6 ,'EMUR Gel' ,82.5 ,4 ,20 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(70 ,6 ,'Antiaging cream' ,65 ,4 ,20 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(71 ,6 ,'Mascara - Waterproof' ,0 ,4 ,2 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(72 ,6 ,'Mascara - Emulsion' ,50 ,4 ,2 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(73 ,6 ,'Mascara - Gel' ,0.95 ,4 ,2 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(74 ,7 ,'Sun Lotion' ,65 ,4 ,2 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(75 ,7 ,'Sun spray' ,60.42 ,4 ,2 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(76 ,7 ,'Aftersun gel' ,72.5 ,4 ,2 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(77 ,7 ,'Aftersun spray' ,67.5 ,4 ,2 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(78 ,7 ,'Aftersun lotion' ,82.5 ,4 ,2 ,4 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(79 ,7 ,'Cooling Spray' ,82.5 ,4 ,2 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(80 ,8 ,'Tothpaste - gels' ,15 ,3 ,2 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(81 ,8 ,'Tothpaste - standard pastes' ,45 ,3 ,2 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(82 ,8 ,'Tothpaste - specialist pastes' ,25 ,3 ,2 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(83 ,8 ,'Mouthwash' ,80 ,3 ,2 ,2 ,0 );
INSERT INTO GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID, GT_PRODUCT_TYPE_GROUP_ID, DESCRIPTION, AV_WATER_CONTENT_PCT, GT_WATER_USE_TYPE_ID, PROD_USE_PER_APP_ML, MNFCT_ENERGY_SCORE, USE_ENERGY_SCORE) VALUES 
(84 ,9 ,'Sponges' ,0 ,3 ,20 ,2 ,0 );


@update_tail
