-- Please update version.sql too -- this keeps clean builds in sync
define version=30
@update_header

set define off;


-- tab i
UPDATE GT_PRODUCT_TYPE SET description = 'Shower Gel /cream', unit='ml', gt_water_use_type_id = 1, water_usage_factor = 20, mnfct_energy_score = 2, use_energy_score = 3, gt_access_visc_type_id = 2 WHERE gt_product_type_id=1;
UPDATE GT_PRODUCT_TYPE SET description = 'Hair & Body wash', unit='ml', gt_water_use_type_id = 1, water_usage_factor = 20, mnfct_energy_score = 2, use_energy_score = 3, gt_access_visc_type_id = 2 WHERE gt_product_type_id=2;
UPDATE GT_PRODUCT_TYPE SET description = 'Bath Foam / soak', unit='ml', gt_water_use_type_id = 2, water_usage_factor = 20, mnfct_energy_score = 2, use_energy_score = 4, gt_access_visc_type_id = 1 WHERE gt_product_type_id=3;
UPDATE GT_PRODUCT_TYPE SET description = 'Bubble bath', unit='ml', gt_water_use_type_id = 2, water_usage_factor = 20, mnfct_energy_score = 2, use_energy_score = 4, gt_access_visc_type_id = 1 WHERE gt_product_type_id=4;
UPDATE GT_PRODUCT_TYPE SET description = 'Hand Wash', unit='ml', gt_water_use_type_id = 3, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 2, gt_access_visc_type_id = 1 WHERE gt_product_type_id=5;
UPDATE GT_PRODUCT_TYPE SET description = 'Bath Oil', unit='ml', gt_water_use_type_id = 2, water_usage_factor = 20, mnfct_energy_score = 2, use_energy_score = 4, gt_access_visc_type_id = 1 WHERE gt_product_type_id=6;
UPDATE GT_PRODUCT_TYPE SET description = 'Bath Salts', unit='ml', gt_water_use_type_id = 2, water_usage_factor = 20, mnfct_energy_score = 2, use_energy_score = 4, gt_access_visc_type_id = 4 WHERE gt_product_type_id=7;
UPDATE GT_PRODUCT_TYPE SET description = 'Bath Salts', unit='g', gt_water_use_type_id = 2, water_usage_factor = 20, mnfct_energy_score = 2, use_energy_score = 4, gt_access_visc_type_id = 4 WHERE gt_product_type_id=136;
UPDATE GT_PRODUCT_TYPE SET description = 'Detergent Body Scrub', unit='ml', gt_water_use_type_id = 1, water_usage_factor = 20, mnfct_energy_score = 2, use_energy_score = 3, gt_access_visc_type_id = 2 WHERE gt_product_type_id=8;
UPDATE GT_PRODUCT_TYPE SET description = 'Emulsion Body Scrub', unit='ml', gt_water_use_type_id = 1, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 3, gt_access_visc_type_id = 2 WHERE gt_product_type_id=9;
UPDATE GT_PRODUCT_TYPE SET description = 'Salt / Sugar Scrub', unit='g', gt_water_use_type_id = 1, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 3, gt_access_visc_type_id = 4 WHERE gt_product_type_id=10;
UPDATE GT_PRODUCT_TYPE SET description = 'Soap (Bar)', unit='g', gt_water_use_type_id = 2, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 4, gt_access_visc_type_id = 4 WHERE gt_product_type_id=11;
UPDATE GT_PRODUCT_TYPE SET description = 'Talc', unit='g', gt_water_use_type_id = 4, water_usage_factor = 10, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=12;
UPDATE GT_PRODUCT_TYPE SET description = 'Shower oil', unit='ml', gt_water_use_type_id = 1, water_usage_factor = 20, mnfct_energy_score = 2, use_energy_score = 3, gt_access_visc_type_id = 1 WHERE gt_product_type_id=133;

UPDATE GT_PRODUCT_TYPE SET description = 'Pre shave', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 10, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=13;
UPDATE GT_PRODUCT_TYPE SET description = 'Mens aftershave lotion / balm', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=14;
UPDATE GT_PRODUCT_TYPE SET description = 'Shave gel', unit='ml', gt_water_use_type_id = 5, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=15;


UPDATE GT_PRODUCT_TYPE SET description = 'Hand Cream', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=16;
UPDATE GT_PRODUCT_TYPE SET description = 'Hand Cream SPF', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=17;
UPDATE GT_PRODUCT_TYPE SET description = 'Body Cream', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=18;
UPDATE GT_PRODUCT_TYPE SET description = 'Body Lotion', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=19;
UPDATE GT_PRODUCT_TYPE SET description = 'Body / massage oil', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=20;

UPDATE GT_PRODUCT_TYPE SET description = 'Cleanser', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=21;
UPDATE GT_PRODUCT_TYPE SET description = 'Toner', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=22;
UPDATE GT_PRODUCT_TYPE SET description = 'Day Cream', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=23;
UPDATE GT_PRODUCT_TYPE SET description = 'Night Cream', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=24;
UPDATE GT_PRODUCT_TYPE SET description = 'Serum - Water / Silicone', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 10, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=25;
UPDATE GT_PRODUCT_TYPE SET description = 'Serum - Oil / Water', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 10, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=26;
UPDATE GT_PRODUCT_TYPE SET description = 'Exfoliator (Detergent)', unit='ml', gt_water_use_type_id = 5, water_usage_factor = 10, mnfct_energy_score = 2, use_energy_score = 2, gt_access_visc_type_id = 2 WHERE gt_product_type_id=27;
UPDATE GT_PRODUCT_TYPE SET description = 'Exfoliator (Emulsion)', unit='ml', gt_water_use_type_id = 5, water_usage_factor = 10, mnfct_energy_score = 4, use_energy_score = 2, gt_access_visc_type_id = 2 WHERE gt_product_type_id=28;
UPDATE GT_PRODUCT_TYPE SET description = 'Facial Wash (Detergent) - premium', unit='ml', gt_water_use_type_id = 5, water_usage_factor = 20, mnfct_energy_score = 3, use_energy_score = 2, gt_access_visc_type_id = 2 WHERE gt_product_type_id=29;
UPDATE GT_PRODUCT_TYPE SET description = 'Facial Wash (Detergent) - Good', unit='ml', gt_water_use_type_id = 5, water_usage_factor = 20, mnfct_energy_score = 2, use_energy_score = 2, gt_access_visc_type_id = 2 WHERE gt_product_type_id=30;
UPDATE GT_PRODUCT_TYPE SET description = 'Facial Wash (Emulsion)', unit='ml', gt_water_use_type_id = 5, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 2, gt_access_visc_type_id = 2 WHERE gt_product_type_id=31;
UPDATE GT_PRODUCT_TYPE SET description = 'Moisturiser', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=32;
UPDATE GT_PRODUCT_TYPE SET description = 'Eye Cream', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 5, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=33;
UPDATE GT_PRODUCT_TYPE SET description = 'Wipes', unit='g', gt_water_use_type_id = 4, water_usage_factor = 2, mnfct_energy_score = 3, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=34;
UPDATE GT_PRODUCT_TYPE SET description = 'Anti-perspirant - Roll On', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=35;
UPDATE GT_PRODUCT_TYPE SET description = 'Anti-perspirant - Aerosol', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 5, mnfct_energy_score = 2, use_energy_score = 2, gt_access_visc_type_id = 1 WHERE gt_product_type_id=36;
UPDATE GT_PRODUCT_TYPE SET description = 'Anti-perspirant - Stick', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=37;
UPDATE GT_PRODUCT_TYPE SET description = 'Deodorants - Wipe', unit='g', gt_water_use_type_id = 4, water_usage_factor = 1, mnfct_energy_score = 3, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=38;
UPDATE GT_PRODUCT_TYPE SET description = 'Lip Salve (Oily)', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 2, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=39;
UPDATE GT_PRODUCT_TYPE SET description = 'Lip Cream', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 2, mnfct_energy_score = 3, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=40;
UPDATE GT_PRODUCT_TYPE SET description = 'Gel Cream', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 2, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=41;
UPDATE GT_PRODUCT_TYPE SET description = 'Emulsion Spray', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 2, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=42;
UPDATE GT_PRODUCT_TYPE SET description = 'Skin Lotion', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 2, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=138;
UPDATE GT_PRODUCT_TYPE SET description = 'Skin Gel', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 2, mnfct_energy_score = 3, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=139;


UPDATE GT_PRODUCT_TYPE SET description = 'Shampoo - Clear', unit='ml', gt_water_use_type_id = 1, water_usage_factor = 20, mnfct_energy_score = 2, use_energy_score = 3, gt_access_visc_type_id = 1 WHERE gt_product_type_id=43;
UPDATE GT_PRODUCT_TYPE SET description = 'Shampoo - Cold pearl', unit='ml', gt_water_use_type_id = 1, water_usage_factor = 20, mnfct_energy_score = 2, use_energy_score = 3, gt_access_visc_type_id = 1 WHERE gt_product_type_id=44;
UPDATE GT_PRODUCT_TYPE SET description = 'Shampoo - Hot pearl', unit='ml', gt_water_use_type_id = 1, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 3, gt_access_visc_type_id = 1 WHERE gt_product_type_id=45;
UPDATE GT_PRODUCT_TYPE SET description = 'Conditioner (including Intensive)', unit='ml', gt_water_use_type_id = 1, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 3, gt_access_visc_type_id = 2 WHERE gt_product_type_id=46;
UPDATE GT_PRODUCT_TYPE SET description = 'Conditioner (Leave In)', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 2, gt_access_visc_type_id = 1 WHERE gt_product_type_id=47;
UPDATE GT_PRODUCT_TYPE SET description = 'Serum (Silicone)', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 10, mnfct_energy_score = 2, use_energy_score = 2, gt_access_visc_type_id = 1 WHERE gt_product_type_id=48;
UPDATE GT_PRODUCT_TYPE SET description = 'Heat Spray', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 5, mnfct_energy_score = 2, use_energy_score = 2, gt_access_visc_type_id = 1 WHERE gt_product_type_id=49;
UPDATE GT_PRODUCT_TYPE SET description = 'Styling Spray', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 10, mnfct_energy_score = 2, use_energy_score = 2, gt_access_visc_type_id = 1 WHERE gt_product_type_id=50;
UPDATE GT_PRODUCT_TYPE SET description = 'Hair Spray (non aerosol)', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 10, mnfct_energy_score = 2, use_energy_score = 2, gt_access_visc_type_id = 1 WHERE gt_product_type_id=51;
UPDATE GT_PRODUCT_TYPE SET description = 'Wax', unit='g', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=52;
UPDATE GT_PRODUCT_TYPE SET description = 'Gel', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=53;
UPDATE GT_PRODUCT_TYPE SET description = 'Clay', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=54;
UPDATE GT_PRODUCT_TYPE SET description = 'Ringing Gel', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 10, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=55;
UPDATE GT_PRODUCT_TYPE SET description = 'Shine Spray (Si / ETOH)', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 10, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=56;
UPDATE GT_PRODUCT_TYPE SET description = 'Straightening / curling balm', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 2, gt_access_visc_type_id = 2 WHERE gt_product_type_id=57;
UPDATE GT_PRODUCT_TYPE SET description = 'Curl cream', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 10, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=58;
UPDATE GT_PRODUCT_TYPE SET description = 'Waterproof Gellee', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 10, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=59;
UPDATE GT_PRODUCT_TYPE SET description = 'Hair Colourant', unit='ml', gt_water_use_type_id = 1, water_usage_factor = -1, mnfct_energy_score = 4, use_energy_score = 2, gt_access_visc_type_id = 2 WHERE gt_product_type_id=60;
UPDATE GT_PRODUCT_TYPE SET description = 'Putty', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 5, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=61;

UPDATE GT_PRODUCT_TYPE SET description = 'Sun Lotion', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 2, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=74;
UPDATE GT_PRODUCT_TYPE SET description = 'Sun spray', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 2, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=75;
UPDATE GT_PRODUCT_TYPE SET description = 'Aftersun gel', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 2, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=76;
UPDATE GT_PRODUCT_TYPE SET description = 'Aftersun spray', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 2, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=77;
UPDATE GT_PRODUCT_TYPE SET description = 'Aftersun lotion', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 2, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=78;
UPDATE GT_PRODUCT_TYPE SET description = 'Cooling Spray', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 2, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=79;

UPDATE GT_PRODUCT_TYPE SET description = 'Tothpaste - gels', unit='ml', gt_water_use_type_id = 5, water_usage_factor = 2, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=80;
UPDATE GT_PRODUCT_TYPE SET description = 'Tothpaste - standard pastes', unit='ml', gt_water_use_type_id = 5, water_usage_factor = 2, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=81;
UPDATE GT_PRODUCT_TYPE SET description = 'Tothpaste - specialist pastes', unit='ml', gt_water_use_type_id = 5, water_usage_factor = 2, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=82;
UPDATE GT_PRODUCT_TYPE SET description = 'Mouthwash', unit='ml', gt_water_use_type_id = 5, water_usage_factor = 2, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=83;


-- tab 2 
UPDATE GT_PRODUCT_TYPE SET description = 'Bath milk', unit='ml', gt_water_use_type_id = 2, water_usage_factor = 20, mnfct_energy_score = 3, use_energy_score = 4, gt_access_visc_type_id = 2 WHERE gt_product_type_id=85;
UPDATE GT_PRODUCT_TYPE SET description = 'Blemish Stick', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=86;
UPDATE GT_PRODUCT_TYPE SET description = 'Blemish Stick', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=137;
UPDATE GT_PRODUCT_TYPE SET description = 'Blush Cheek Colour powder', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=87;
UPDATE GT_PRODUCT_TYPE SET description = 'Blusher powder', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=88;
UPDATE GT_PRODUCT_TYPE SET description = 'Body Balm', unit='ml', gt_water_use_type_id = 1, water_usage_factor = 15, mnfct_energy_score = 3, use_energy_score = 3, gt_access_visc_type_id = 1 WHERE gt_product_type_id=89;
UPDATE GT_PRODUCT_TYPE SET description = 'Body Exfoliator', unit='ml', gt_water_use_type_id = 1, water_usage_factor = 10, mnfct_energy_score = 3, use_energy_score = 3, gt_access_visc_type_id = 2 WHERE gt_product_type_id=90;
UPDATE GT_PRODUCT_TYPE SET description = 'Body Wash', unit='ml', gt_water_use_type_id = 1, water_usage_factor = 10, mnfct_energy_score = 3, use_energy_score = 3, gt_access_visc_type_id = 2 WHERE gt_product_type_id=91;
UPDATE GT_PRODUCT_TYPE SET description = 'Bronzing Gel', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=92;
UPDATE GT_PRODUCT_TYPE SET description = 'Bronzer', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 3, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=93;
UPDATE GT_PRODUCT_TYPE SET description = 'Bronzing Pearls', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=94;
UPDATE GT_PRODUCT_TYPE SET description = 'Bronzing Powder', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=95;
UPDATE GT_PRODUCT_TYPE SET description = 'Cheek Colour', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=96;
UPDATE GT_PRODUCT_TYPE SET description = 'Concealer', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=97;
UPDATE GT_PRODUCT_TYPE SET description = 'Cream Blush', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=98;
UPDATE GT_PRODUCT_TYPE SET description = 'Crème Touch', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=99;
UPDATE GT_PRODUCT_TYPE SET description = 'Eye Liquid Liner', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=100;
UPDATE GT_PRODUCT_TYPE SET description = 'Eyeshadow powder', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=101;
UPDATE GT_PRODUCT_TYPE SET description = 'Foundation Intelligent Colour (anhydrous)', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=102;
UPDATE GT_PRODUCT_TYPE SET description = 'Foundation Age Rewind (W/Si)', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 3, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=103;
UPDATE GT_PRODUCT_TYPE SET description = 'Foundation Intelligent Balance Mousse (anhydrous)', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=104;
UPDATE GT_PRODUCT_TYPE SET description = 'Foundation Lift & Luminate (W/Si)', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=105;
UPDATE GT_PRODUCT_TYPE SET description = 'Foundation Essential Moisture (O/W)', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=106;
UPDATE GT_PRODUCT_TYPE SET description = 'Foundation Instant Radiance (W/Si)', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 3, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=107;
UPDATE GT_PRODUCT_TYPE SET description = 'Foundation mineral perfection (powder)', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=108;
UPDATE GT_PRODUCT_TYPE SET description = 'Foundation Compact (anhydrous)', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=109;
UPDATE GT_PRODUCT_TYPE SET description = 'Foundation P&P (W/Si)', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 3, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=110;
UPDATE GT_PRODUCT_TYPE SET description = 'Foundation Stay Perfect (W/Si)', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 3, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=111;
UPDATE GT_PRODUCT_TYPE SET description = 'Illuminating Powder', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=112;
UPDATE GT_PRODUCT_TYPE SET description = 'Lip Gloss', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=113;
UPDATE GT_PRODUCT_TYPE SET description = 'Lipstick', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=115;
UPDATE GT_PRODUCT_TYPE SET description = 'Loose Powder', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=116;
UPDATE GT_PRODUCT_TYPE SET description = 'Make up base shine free', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=117;
UPDATE GT_PRODUCT_TYPE SET description = 'Make up Base Colour calming', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=118;
UPDATE GT_PRODUCT_TYPE SET description = 'Mascara - gel (Lash & brow)', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=119;
UPDATE GT_PRODUCT_TYPE SET description = 'Mascara Emulsion  - Sensitive eyes', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=120;
UPDATE GT_PRODUCT_TYPE SET description = 'Mascara Emulsion  - Stay Perfect', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=121;
UPDATE GT_PRODUCT_TYPE SET description = 'Mascara Emulsion  - Lift & Curve', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=122;
UPDATE GT_PRODUCT_TYPE SET description = 'Mascara Emulsion  - Extravagant Lashes', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=123;
UPDATE GT_PRODUCT_TYPE SET description = 'Mascara Emulsion  - Dream Lash', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=124;
UPDATE GT_PRODUCT_TYPE SET description = 'Mascara Emulsion  -Lash 360', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=125;
UPDATE GT_PRODUCT_TYPE SET description = 'Mascara Emulsion -Extreme Length', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=126;
UPDATE GT_PRODUCT_TYPE SET description = 'Mascara Emulsion  - Intense volume W/proof', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=127;
UPDATE GT_PRODUCT_TYPE SET description = 'Mascara Emulsion - Intense volume', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=128;
UPDATE GT_PRODUCT_TYPE SET description = 'Nail base coat', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=129;
UPDATE GT_PRODUCT_TYPE SET description = 'Nail Care', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=130;
UPDATE GT_PRODUCT_TYPE SET description = 'Pressed Powder', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=132;
UPDATE GT_PRODUCT_TYPE SET description = 'Skin illuminator', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=134;
UPDATE GT_PRODUCT_TYPE SET description = 'Tinted Moisturiser', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=135;
UPDATE GT_PRODUCT_TYPE SET description = 'Nail Polish / Colour', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=62;
UPDATE GT_PRODUCT_TYPE SET description = 'Foundation W/S', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 2, mnfct_energy_score = 3, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=64;
UPDATE GT_PRODUCT_TYPE SET description = 'Foundation O/W', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 2, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=65;
UPDATE GT_PRODUCT_TYPE SET description = 'EMUR Pads', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 2, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=67;
UPDATE GT_PRODUCT_TYPE SET description = 'EMUR Lotion', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=68;
UPDATE GT_PRODUCT_TYPE SET description = 'EMUR Gel', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=69;
UPDATE GT_PRODUCT_TYPE SET description = 'Antiaging cream', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 20, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=70;
UPDATE GT_PRODUCT_TYPE SET description = 'Mascara - Waterproof', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 2, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=71;
UPDATE GT_PRODUCT_TYPE SET description = 'Mascara - Emulsion', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=72;
UPDATE GT_PRODUCT_TYPE SET description = 'Mascara - Gel', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=73;
UPDATE GT_PRODUCT_TYPE SET description = 'Eye Liner Pencil', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=140;
UPDATE GT_PRODUCT_TYPE SET description = 'Lip Liner Pencil', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=141;
UPDATE GT_PRODUCT_TYPE SET description = 'Eyeshadow mousse', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 3 WHERE gt_product_type_id=142;
UPDATE GT_PRODUCT_TYPE SET description = 'Felt tip products (lip/eye)', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=143;
UPDATE GT_PRODUCT_TYPE SET description = 'Nail top coat', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 2, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=144;
UPDATE GT_PRODUCT_TYPE SET description = 'Foundation W/Si Mattifying Fdn', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 3, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=145;
UPDATE GT_PRODUCT_TYPE SET description = 'Foundation W/Si Essentially Natural Fdn', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 3, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=146;
UPDATE GT_PRODUCT_TYPE SET description = 'Foundation W/Si Instant Radiance Fdn', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.3, mnfct_energy_score = 3, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=147;
UPDATE GT_PRODUCT_TYPE SET description = 'Instant Radiance/Under Eye Concealer', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 2 WHERE gt_product_type_id=148;
UPDATE GT_PRODUCT_TYPE SET description = 'Hotpour concealers', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=149;
UPDATE GT_PRODUCT_TYPE SET description = 'Bronzing Silk Legs/Stocking Cream', unit='ml', gt_water_use_type_id = 4, water_usage_factor = 5, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 1 WHERE gt_product_type_id=150;
UPDATE GT_PRODUCT_TYPE SET description = 'Blush stick', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=151;
UPDATE GT_PRODUCT_TYPE SET description = 'Cream Blush', unit='g', gt_water_use_type_id = 4, water_usage_factor = 0.1, mnfct_energy_score = 4, use_energy_score = 0, gt_access_visc_type_id = 4 WHERE gt_product_type_id=152;


		
@update_tail