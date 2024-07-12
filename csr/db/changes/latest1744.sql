-- Please update version too -- this keeps clean builds in sync
define version=1744
@update_header

whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

SET DEFINE OFF;

-- Insert deleted factor types back in
BEGIN INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (12573, 12564, 'Transport Fuel - Biodiesel / Diesel Blend (B2) (Volume) (Direct)', 8, 0); EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
/
BEGIN INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (12574, 12564, 'Transport Fuel - Biodiesel / Diesel Blend (B5) (Volume) (Direct)', 8, 0); EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
/
BEGIN INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (12577, 12564, 'Transport Fuel - Biodiesel / Diesel Blend (B50) (Volume) (Direct)', 8, 0); EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
/
BEGIN INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (12597, 12564, 'Transport Fuel - Biofuels (Other Liquid) (Volume) (Direct)', 8, 0); EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
/

-- New factor types
BEGIN
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15380, 15065, 'Transport Fuel - Biodiesel / Diesel Blend (B2) (Energy - GCV/HHV) (Direct)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15381, 15065, 'Transport Fuel - Biodiesel / Diesel Blend (B5) (Energy - GCV/HHV) (Direct)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15382, 15065, 'Transport Fuel - Biodiesel / Diesel Blend (B50) (Energy - GCV/HHV) (Direct)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15383, 15099, 'Transport Fuel - Biodiesel / Diesel Blend (B2) (Energy - NCV/LHV) (Direct)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15384, 15099, 'Transport Fuel - Biodiesel / Diesel Blend (B5) (Energy - NCV/LHV) (Direct)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15385, 15099, 'Transport Fuel - Biodiesel / Diesel Blend (B50) (Energy - NCV/LHV) (Direct)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15386, 15133, 'Transport Fuel - Biodiesel / Diesel Blend (B2) (Mass) (Direct)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15387, 15133, 'Transport Fuel - Biodiesel / Diesel Blend (B5) (Mass) (Direct)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15388, 15133, 'Transport Fuel - Biodiesel / Diesel Blend (B50) (Mass) (Direct)', 8, 0);

INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15389, 15167, 'Transport Fuel - Biodiesel / Diesel Blend (B2) (Energy - GCV/HHV) (Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15390, 15167, 'Transport Fuel - Biodiesel / Diesel Blend (B5) (Energy - GCV/HHV) (Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15391, 15167, 'Transport Fuel - Biodiesel / Diesel Blend (B50) (Energy - GCV/HHV) (Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15392, 15201, 'Transport Fuel - Biodiesel / Diesel Blend (B2) (Energy - NCV/LHV) (Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15393, 15201, 'Transport Fuel - Biodiesel / Diesel Blend (B5) (Energy - NCV/LHV) (Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15394, 15201, 'Transport Fuel - Biodiesel / Diesel Blend (B50) (Energy - NCV/LHV) (Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15395, 15235, 'Transport Fuel - Biodiesel / Diesel Blend (B2) (Mass) (Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15396, 15235, 'Transport Fuel - Biodiesel / Diesel Blend (B5) (Mass) (Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15397, 15235, 'Transport Fuel - Biodiesel / Diesel Blend (B50) (Mass) (Upstream)', 8, 0);

INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15398, 15269, 'Transport Fuel - Biodiesel / Diesel Blend (B2) (Energy - GCV/HHV) (Direct & Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15399, 15269, 'Transport Fuel - Biodiesel / Diesel Blend (B5) (Energy - GCV/HHV) (Direct & Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15400, 15269, 'Transport Fuel - Biodiesel / Diesel Blend (B50) (Energy - GCV/HHV) (Direct & Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15401, 15303, 'Transport Fuel - Biodiesel / Diesel Blend (B2) (Energy - NCV/LHV) (Direct & Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15402, 15303, 'Transport Fuel - Biodiesel / Diesel Blend (B5) (Energy - NCV/LHV) (Direct & Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15403, 15303, 'Transport Fuel - Biodiesel / Diesel Blend (B50) (Energy - NCV/LHV) (Direct & Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15404, 15337, 'Transport Fuel - Biodiesel / Diesel Blend (B2) (Mass) (Direct & Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15405, 15337, 'Transport Fuel - Biodiesel / Diesel Blend (B5) (Mass) (Direct & Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15406, 15337, 'Transport Fuel - Biodiesel / Diesel Blend (B50) (Mass) (Direct & Upstream)', 8, 0);

INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15407, 15065, 'Transport Fuel - Biofuels (Other Liquid) (Energy - GCV/HHV) (Direct)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15408, 15099, 'Transport Fuel - Biofuels (Other Liquid) (Energy - NCV/LHV) (Direct)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15409, 15133, 'Transport Fuel - Biofuels (Other Liquid) (Mass) (Direct)', 8, 0);

INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15410, 15167, 'Transport Fuel - Biofuels (Other Liquid) (Energy - GCV/HHV) (Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15411, 15201, 'Transport Fuel - Biofuels (Other Liquid) (Energy - NCV/LHV) (Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15412, 15235, 'Transport Fuel - Biofuels (Other Liquid) (Mass) (Upstream)', 8, 0);

INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15413, 15269, 'Transport Fuel - Biofuels (Other Liquid) (Energy - GCV/HHV) (Direct & Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15414, 15303, 'Transport Fuel - Biofuels (Other Liquid) (Energy - NCV/LHV) (Direct & Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15415, 15337, 'Transport Fuel - Biofuels (Other Liquid) (Mass) (Direct & Upstream)', 8, 0);

INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15416, 15063, 'Transport Fuel - Biofuels (Other Liquid) (Volume) (Upstream)', 8, 0);
INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID, PARENT_ID, NAME, STD_MEASURE_ID, EGRID) VALUES (15417, 15064, 'Transport Fuel - Biofuels (Other Liquid) (Volume) (Direct & Upstream)', 8, 0);
END;
/

@update_tail