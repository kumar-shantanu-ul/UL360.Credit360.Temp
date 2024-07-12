-- Please update version.sql too -- this keeps clean builds in sync
define version=1071
@update_header


UPDATE chain.card
   SET js_include = '/csr/site/ct/cards/ec/commutingBreakdown.js'
 WHERE js_include = '/csr/site/ct/cards/commutingBreakdown.js';
 
UPDATE chain.card
   SET js_include = '/csr/site/ct/cards/ec/carCommuting.js'
 WHERE js_include = '/csr/site/ct/cards/carCommuting.js';
 
UPDATE chain.card
   SET js_include = '/csr/site/ct/cards/ec/busCommuting.js'
 WHERE js_include = '/csr/site/ct/cards/busCommuting.js';
 
UPDATE chain.card
   SET js_include = '/csr/site/ct/cards/ec/trainCommuting.js'
 WHERE js_include = '/csr/site/ct/cards/trainCommuting.js';
 
UPDATE chain.card
   SET js_include = '/csr/site/ct/cards/ec/motorbikeCommuting.js'
 WHERE js_include = '/csr/site/ct/cards/motorbikeCommuting.js';


UPDATE chain.card
   SET js_include = '/csr/site/ct/cards/ec/bikeCommuting.js'
 WHERE js_include = '/csr/site/ct/cards/bikeCommuting.js';
 
UPDATE chain.card
   SET js_include = '/csr/site/ct/cards/ec/walkCommuting.js'
 WHERE js_include = '/csr/site/ct/cards/walkCommuting.js';
 
commit;

DECLARE
v_card_id         chain.card.card_id%TYPE;
v_desc            chain.card.description%TYPE;
v_class           chain.card.class_type%TYPE;
v_js_path         chain.card.js_include%TYPE;
v_js_class        chain.card.js_class_type%TYPE;
v_css_path        chain.card.css_include%TYPE;
v_actions         chain.T_STRING_LIST;
BEGIN
-- CarbonTrust.Cards.TravellersBusinessTravel
v_desc := 'Travellers Business Travel - used by CarbonTrust tool';
v_class := 'Credit360.CarbonTrust.Cards.BusinessTravelWizard';
v_js_path := '/csr/site/ct/cards/bt/travellersBusinessTravel.js';
v_js_class := 'CarbonTrust.Cards.TravellersBusinessTravel';
v_css_path := '';
BEGIN
INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
RETURNING card_id INTO v_card_id;
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
UPDATE chain.card
SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
WHERE js_class_type = v_js_class
RETURNING card_id INTO v_card_id;
END;
DELETE FROM chain.card_progression_action
WHERE card_id = v_card_id
AND action NOT IN ('default');
v_actions := chain.T_STRING_LIST('default');
FOR i IN v_actions.FIRST .. v_actions.LAST
LOOP
BEGIN
INSERT INTO chain.card_progression_action (card_id, action)
VALUES (v_card_id, v_actions(i));
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
NULL;
END;
END LOOP;
-- CarbonTrust.Cards.CarBusinessTravel
v_desc := 'Car Business Travel - used by CarbonTrust tool';
v_class := 'Credit360.CarbonTrust.Cards.BusinessTravelWizard';
v_js_path := '/csr/site/ct/cards/bt/carBusinessTravel.js';
v_js_class := 'CarbonTrust.Cards.CarBusinessTravel';
v_css_path := '';
BEGIN
INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
RETURNING card_id INTO v_card_id;
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
UPDATE chain.card
SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
WHERE js_class_type = v_js_class
RETURNING card_id INTO v_card_id;
END;
DELETE FROM chain.card_progression_action
WHERE card_id = v_card_id
AND action NOT IN ('default');
v_actions := chain.T_STRING_LIST('default');
FOR i IN v_actions.FIRST .. v_actions.LAST
LOOP
BEGIN
INSERT INTO chain.card_progression_action (card_id, action)
VALUES (v_card_id, v_actions(i));
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
NULL;
END;
END LOOP;
-- CarbonTrust.Cards.BusBusinessTravel
v_desc := 'Bus Business Travel - used by CarbonTrust tool';
v_class := 'Credit360.CarbonTrust.Cards.BusinessTravelWizard';
v_js_path := '/csr/site/ct/cards/bt/busBusinessTravel.js';
v_js_class := 'CarbonTrust.Cards.BusBusinessTravel';
v_css_path := '';
BEGIN
INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
RETURNING card_id INTO v_card_id;
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
UPDATE chain.card
SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
WHERE js_class_type = v_js_class
RETURNING card_id INTO v_card_id;
END;
DELETE FROM chain.card_progression_action
WHERE card_id = v_card_id
AND action NOT IN ('default');
v_actions := chain.T_STRING_LIST('default');
FOR i IN v_actions.FIRST .. v_actions.LAST
LOOP
BEGIN
INSERT INTO chain.card_progression_action (card_id, action)
VALUES (v_card_id, v_actions(i));
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
NULL;
END;
END LOOP;
-- CarbonTrust.Cards.RailBusinessTravel
v_desc := 'Rail Business Travel - used by CarbonTrust tool';
v_class := 'Credit360.CarbonTrust.Cards.BusinessTravelWizard';
v_js_path := '/csr/site/ct/cards/bt/railBusinessTravel.js';
v_js_class := 'CarbonTrust.Cards.RailBusinessTravel';
v_css_path := '';
BEGIN
INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
RETURNING card_id INTO v_card_id;
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
UPDATE chain.card
SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
WHERE js_class_type = v_js_class
RETURNING card_id INTO v_card_id;
END;
DELETE FROM chain.card_progression_action
WHERE card_id = v_card_id
AND action NOT IN ('default');
v_actions := chain.T_STRING_LIST('default');
FOR i IN v_actions.FIRST .. v_actions.LAST
LOOP
BEGIN
INSERT INTO chain.card_progression_action (card_id, action)
VALUES (v_card_id, v_actions(i));
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
NULL;
END;
END LOOP;
-- CarbonTrust.Cards.AirBusinessTravel
v_desc := 'Air Business Travel - used by CarbonTrust tool';
v_class := 'Credit360.CarbonTrust.Cards.BusinessTravelWizard';
v_js_path := '/csr/site/ct/cards/bt/airBusinessTravel.js';
v_js_class := 'CarbonTrust.Cards.AirBusinessTravel';
v_css_path := '';
BEGIN
INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
RETURNING card_id INTO v_card_id;
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
UPDATE chain.card
SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
WHERE js_class_type = v_js_class
RETURNING card_id INTO v_card_id;
END;
DELETE FROM chain.card_progression_action
WHERE card_id = v_card_id
AND action NOT IN ('default');
v_actions := chain.T_STRING_LIST('default');
FOR i IN v_actions.FIRST .. v_actions.LAST
LOOP
BEGIN
INSERT INTO chain.card_progression_action (card_id, action)
VALUES (v_card_id, v_actions(i));
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
NULL;
END;
END LOOP;
-- CarbonTrust.Cards.BikeBusinessTravel
v_desc := 'Bike Business Travel - used by CarbonTrust tool';
v_class := 'Credit360.CarbonTrust.Cards.BusinessTravelWizard';
v_js_path := '/csr/site/ct/cards/bt/bikeBusinessTravel.js';
v_js_class := 'CarbonTrust.Cards.BikeBusinessTravel';
v_css_path := '';
BEGIN
INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
RETURNING card_id INTO v_card_id;
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
UPDATE chain.card
SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
WHERE js_class_type = v_js_class
RETURNING card_id INTO v_card_id;
END;
DELETE FROM chain.card_progression_action
WHERE card_id = v_card_id
AND action NOT IN ('default');
v_actions := chain.T_STRING_LIST('default');
FOR i IN v_actions.FIRST .. v_actions.LAST
LOOP
BEGIN
INSERT INTO chain.card_progression_action (card_id, action)
VALUES (v_card_id, v_actions(i));
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
NULL;
END;
END LOOP;
-- CarbonTrust.Cards.WalkBusinessTravel
v_desc := 'Walking Business Travel - used by CarbonTrust tool';
v_class := 'Credit360.CarbonTrust.Cards.BusinessTravelWizard';
v_js_path := '/csr/site/ct/cards/bt/walkBusinessTravel.js';
v_js_class := 'CarbonTrust.Cards.WalkBusinessTravel';
v_css_path := '';
BEGIN
INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
RETURNING card_id INTO v_card_id;
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
UPDATE chain.card
SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
WHERE js_class_type = v_js_class
RETURNING card_id INTO v_card_id;
END;
DELETE FROM chain.card_progression_action
WHERE card_id = v_card_id
AND action NOT IN ('default');
v_actions := chain.T_STRING_LIST('default');
FOR i IN v_actions.FIRST .. v_actions.LAST
LOOP
BEGIN
INSERT INTO chain.card_progression_action (card_id, action)
VALUES (v_card_id, v_actions(i));
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
NULL;
END;
END LOOP;
-- CarbonTrust.Cards.EmployeeCommute
v_desc := 'Employee Commute Survey - used by CarbonTrust tool';
v_class := 'Credit360.CarbonTrust.Cards.EmployeeCommute';
v_js_path := '/csr/site/ct/cards/surveys/employeeCommute.js';
v_js_class := 'CarbonTrust.Cards.EmployeeCommute';
v_css_path := '';
BEGIN
INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
RETURNING card_id INTO v_card_id;
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
UPDATE chain.card
SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
WHERE js_class_type = v_js_class
RETURNING card_id INTO v_card_id;
END;
DELETE FROM chain.card_progression_action
WHERE card_id = v_card_id
AND action NOT IN ('default');
v_actions := chain.T_STRING_LIST('default');
FOR i IN v_actions.FIRST .. v_actions.LAST
LOOP
BEGIN
INSERT INTO chain.card_progression_action (card_id, action)
VALUES (v_card_id, v_actions(i));
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
NULL;
END;
END LOOP;
END;
/

BEGIN
INSERT INTO chain.card_group(card_group_id, name, description)
VALUES(30, 'Business Travel Wizard', 'Carbon Trust Business Travel Wizard');
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
UPDATE chain.card_group
SET description='Carbon Trust Business Travel Wizard'
WHERE card_group_id=30;
END;
/
DECLARE
v_card_group_id                 chain.card_group.card_group_id%TYPE DEFAULT 30;
v_position                              NUMBER(10) DEFAULT 1;
BEGIN
-- clear the app_sid
user_pkg.logonadmin;
FOR r IN (
SELECT host FROM chain.v$chain_host WHERE '.'||chain_implementation||'.' LIKE '%.CT.%'
) LOOP
user_pkg.logonadmin(r.host);
DELETE FROM chain.card_group_progression
WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
AND card_group_id = v_card_group_id;
DELETE FROM chain.card_group_card
WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
AND card_group_id = v_card_group_id;
INSERT INTO chain.card_group_card (card_group_id, card_id, position, required_permission_set,
invert_capability_check, force_terminate, required_capability_id)
SELECT v_card_group_id, card_id, v_position, NULL, 0, 0, NULL
FROM chain.card
WHERE js_class_type = 'CarbonTrust.Cards.TravellersBusinessTravel';
v_position := v_position + 1;
INSERT INTO chain.card_group_card (card_group_id, card_id, position, required_permission_set,
invert_capability_check, force_terminate, required_capability_id)
SELECT v_card_group_id, card_id, v_position, NULL, 0, 0, NULL
FROM chain.card
WHERE js_class_type = 'CarbonTrust.Cards.CarBusinessTravel';
v_position := v_position + 1;
INSERT INTO chain.card_group_card (card_group_id, card_id, position, required_permission_set,
invert_capability_check, force_terminate, required_capability_id)
SELECT v_card_group_id, card_id, v_position, NULL, 0, 0, NULL
FROM chain.card
WHERE js_class_type = 'CarbonTrust.Cards.MotorbikeBusinessTravel';
v_position := v_position + 1;
INSERT INTO chain.card_group_card (card_group_id, card_id, position, required_permission_set,
invert_capability_check, force_terminate, required_capability_id)
SELECT v_card_group_id, card_id, v_position, NULL, 0, 0, NULL
FROM chain.card
WHERE js_class_type = 'CarbonTrust.Cards.BusBusinessTravel';
v_position := v_position + 1;
INSERT INTO chain.card_group_card (card_group_id, card_id, position, required_permission_set,
invert_capability_check, force_terminate, required_capability_id)
SELECT v_card_group_id, card_id, v_position, NULL, 0, 0, NULL
FROM chain.card
WHERE js_class_type = 'CarbonTrust.Cards.RailBusinessTravel';
v_position := v_position + 1;
INSERT INTO chain.card_group_card (card_group_id, card_id, position, required_permission_set,
invert_capability_check, force_terminate, required_capability_id)
SELECT v_card_group_id, card_id, v_position, NULL, 0, 0, NULL
FROM chain.card
WHERE js_class_type = 'CarbonTrust.Cards.AirBusinessTravel';
v_position := v_position + 1;
INSERT INTO chain.card_group_card (card_group_id, card_id, position, required_permission_set,
invert_capability_check, force_terminate, required_capability_id)
SELECT v_card_group_id, card_id, v_position, NULL, 0, 0, NULL
FROM chain.card
WHERE js_class_type = 'CarbonTrust.Cards.BikeBusinessTravel';
v_position := v_position + 1;
INSERT INTO chain.card_group_card (card_group_id, card_id, position, required_permission_set,
invert_capability_check, force_terminate, required_capability_id)
SELECT v_card_group_id, card_id, v_position, NULL, 0, 0, NULL
FROM chain.card
WHERE js_class_type = 'CarbonTrust.Cards.WalkBusinessTravel';
v_position := v_position + 1;
END LOOP;
-- clear the app_sid
user_pkg.logonadmin;
END;
/


BEGIN
INSERT INTO chain.card_group(card_group_id, name, description)
VALUES(31, 'Employee Commute Survey', 'Carbon Trust Employee Commute Survey');
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
UPDATE chain.card_group
SET description='Carbon Trust Employee Commute Survey'
WHERE card_group_id=31;
END;
/
DECLARE
	v_card_group_id                 chain.card_group.card_group_id%TYPE DEFAULT 31;
	v_position                              NUMBER(10) DEFAULT 1;
BEGIN
	-- clear the app_sid
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT host FROM chain.v$chain_host WHERE '.'||chain_implementation||'.' LIKE '%.CT.%'
	) LOOP
		security.user_pkg.logonadmin(r.host);
		DELETE FROM chain.card_group_progression
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND card_group_id = v_card_group_id;
		DELETE FROM chain.card_group_card
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  AND card_group_id = v_card_group_id;
		INSERT INTO chain.card_group_card (card_group_id, card_id, position, required_permission_set,
			invert_capability_check, force_terminate, required_capability_id)
		SELECT v_card_group_id, card_id, v_position, NULL, 0, 0, NULL
		  FROM chain.card
		 WHERE js_class_type = 'CarbonTrust.Cards.EmployeeCommute';
		v_position := v_position + 1;
	END LOOP;
	-- clear the app_sid
	security.user_pkg.logonadmin;
END;
/

@update_tail