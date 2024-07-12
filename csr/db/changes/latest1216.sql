-- Please update version.sql too -- this keeps clean builds in sync
define version=1216
@update_header

ALTER TABLE CSR.WORKSHEET_COLUMN_TYPE ADD (REQUIRED NUMBER(1, 0) DEFAULT 0 NOT NULL);
ALTER TABLE CSR.WORKSHEET_ROW RENAME COLUMN ROW_ID TO ROW_NUMBER;
ALTER TABLE CSR.WORKSHEET_ROW DROP COLUMN ROW_INDEX;
ALTER TABLE CT.PS_ITEM RENAME COLUMN ROW_ID TO ROW_NUMBER;
ALTER TABLE CT.PS_ITEM ADD CONSTRAINT TUC_PS_ITEM_UNIQUE_ROW UNIQUE (WORKSHEET_ID, ROW_NUMBER);
ALTER TABLE CT.PS_ITEM ADD CONSTRAINT TCC_PS_ITEM_WORKHSEET CHECK ((WORKSHEET_ID IS NULL AND ROW_NUMBER IS NULL) OR (WORKSHEET_ID IS NOT NULL AND ROW_NUMBER IS NOT NULL));
ALTER TABLE CT.PS_ITEM MODIFY SUPPLIER_ID NULL;

CREATE OR REPLACE VIEW ct.v$ps_item (
    app_sid, company_sid, supplier_id, breakdown_id, region_id, item_id, description,
	spend, currency_id, purchase_date, created_by_sid, created_dtm, modified_by_sid,
	last_modified_dtm, row_number, worksheet_id, 
	eio_id, kg_co2,
	spend_in_company_currency,	company_currency_id
)
AS
SELECT
    app_sid, 
	company_sid, 
	supplier_id, 
	breakdown_id, 
	region_id, 
	item_id, 
	description,
	spend, 
	currency_id, 
	purchase_date, 
	created_by_sid, 
	created_dtm, 
	modified_by_sid,
	last_modified_dtm, 
	row_number, 
	worksheet_id,
	eio_id, 
	kg_co2,
	spend * util_pkg.GetConversionToDollar(currency_id, purchase_date) * util_pkg.GetConversionFromDollar(company_pkg.GetCompanyCurrency(), purchase_date) spend_in_company_currency,
	company_pkg.GetCompanyCurrency() company_currency_id
 FROM ps_item;

BEGIN
	INSERT INTO CHAIN.CARD(CARD_ID, DESCRIPTION, CLASS_TYPE, JS_CLASS_TYPE, JS_INCLUDE) VALUES (CHAIN.CARD_ID_SEQ.NEXTVAL, 'Defaults for the products and services upload', 'Credit360.CarbonTrust.Cards.PSUploadDefaults', 'CarbonTrust.Cards.PSUploadDefaults', '/csr/site/ct/cards/psUploadDefaults.js');	
	INSERT INTO CHAIN.CARD(CARD_ID, DESCRIPTION, CLASS_TYPE, JS_CLASS_TYPE, JS_INCLUDE) VALUES (CHAIN.CARD_ID_SEQ.NEXTVAL, 'Pick a sheet of an uploaded excel file. Provides cache uploader if no sheet is provided.', 'Credit360.Excel.Cards.ExcelUpload', 'Credit360.Excel.Cards.SheetPicker', '/csr/site/excel/cards/sheetPicker.js');
	INSERT INTO CHAIN.CARD(CARD_ID, DESCRIPTION, CLASS_TYPE, JS_CLASS_TYPE, JS_INCLUDE) VALUES (CHAIN.CARD_ID_SEQ.NEXTVAL, 'Pick the sheet header row and allows column tagging.', 'Credit360.Excel.Cards.ExcelUpload', 'Credit360.Excel.Cards.ColumnTagger', '/csr/site/excel/cards/columnTagger.js');
	INSERT INTO CHAIN.CARD(CARD_ID, DESCRIPTION, CLASS_TYPE, JS_CLASS_TYPE, JS_INCLUDE) VALUES (CHAIN.CARD_ID_SEQ.NEXTVAL, 'Maps well known columns types (value_mappers) to known types.', 'Credit360.Excel.Cards.ExcelUpload', 'Credit360.Excel.Cards.ValueMapper', '/csr/site/excel/cards/valueMapper.js');
	INSERT INTO CHAIN.CARD(CARD_ID, DESCRIPTION, CLASS_TYPE, JS_CLASS_TYPE, JS_INCLUDE) VALUES (CHAIN.CARD_ID_SEQ.NEXTVAL, 'Displays the results of the test run before the user saves.', 'Credit360.Excel.Cards.ExcelUpload', 'Credit360.Excel.Cards.TestResults', '/csr/site/excel/cards/testResults.js');
END;
/

BEGIN
    INSERT INTO chain.card_group(card_group_id, name, description)
    VALUES(35, 'Products and Services Upload Wizard', 'Carbon Trust Products and Services Upload Wizard');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        UPDATE chain.card_group
           SET description='Carbon Trust Products and Services Upload Wizard'
         WHERE card_group_id=35;
END;
/

DECLARE
    v_card_group_id                     chain.card_group.card_group_id%TYPE DEFAULT 35;
    v_position                          NUMBER(10) DEFAULT 1;
BEGIN

    -- clear the app_sid
    security.user_pkg.logonadmin;

    FOR r IN (
        SELECT host FROM chain.v$chain_host WHERE host IN ('ct.credit360.com', 'ctdev.credit360.com')
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
             WHERE js_class_type = 'CarbonTrust.Cards.PSUploadDefaults';

        v_position := v_position + 1;

        INSERT INTO chain.card_group_card (card_group_id, card_id, position, required_permission_set,
               invert_capability_check, force_terminate, required_capability_id)
            SELECT v_card_group_id, card_id, v_position, NULL, 0, 0, NULL
              FROM chain.card
             WHERE js_class_type = 'Credit360.Excel.Cards.SheetPicker';

        v_position := v_position + 1;

        INSERT INTO chain.card_group_card (card_group_id, card_id, position, required_permission_set,
               invert_capability_check, force_terminate, required_capability_id)
            SELECT v_card_group_id, card_id, v_position, NULL, 0, 0, NULL
              FROM chain.card
             WHERE js_class_type = 'Credit360.Excel.Cards.ColumnTagger';

        v_position := v_position + 1;

        INSERT INTO chain.card_group_card (card_group_id, card_id, position, required_permission_set,
               invert_capability_check, force_terminate, required_capability_id)
            SELECT v_card_group_id, card_id, v_position, NULL, 0, 0, NULL
              FROM chain.card
             WHERE js_class_type = 'Credit360.Excel.Cards.ValueMapper';

        v_position := v_position + 1;

        INSERT INTO chain.card_group_card (card_group_id, card_id, position, required_permission_set,
               invert_capability_check, force_terminate, required_capability_id)
            SELECT v_card_group_id, card_id, v_position, NULL, 0, 0, NULL
              FROM chain.card
             WHERE js_class_type = 'Credit360.Excel.Cards.TestResults';

        v_position := v_position + 1;

    END LOOP;

    -- clear the app_sid
    security.user_pkg.logonadmin;

END;
/

BEGIN
	delete from ct.ps_item where worksheet_id is not null;
	delete from csr.worksheet_row;
	delete from csr.worksheet_column_value_map;
	delete from csr.worksheet_value_map_value;
	delete from csr.worksheet_value_map;
	delete from csr.worksheet_column;
	delete from csr.worksheet_column_type;
	delete from csr.worksheet_value_mapper;
	delete from csr.worksheet_type;
	
	INSERT INTO CSR.WORKSHEET_TYPE (WORKSHEET_TYPE_ID, DESCRIPTION) VALUES (100, 'Products and Services');
	
	INSERT INTO CSR.WORKSHEET_VALUE_MAPPER (VALUE_MAPPER_ID, CLASS_TYPE, MAPPER_NAME, MAPPER_DESCRIPTION, JS_COMPONENT_PATH, JS_COMPONENT) VALUES (100, 'Credit360.CarbonTrust.Excel.CurrencyMapper', 'Currency codes', 'Map the currency codes that were found in the worksheet to currencies that the system uses', '/csr/site/ct/components/excel/CurrencyCombo.js', 'CarbonTrust.excel.CurrencyCombo');
	INSERT INTO CSR.WORKSHEET_VALUE_MAPPER (VALUE_MAPPER_ID, CLASS_TYPE, MAPPER_NAME, MAPPER_DESCRIPTION, JS_COMPONENT_PATH, JS_COMPONENT) VALUES (101, 'Credit360.CarbonTrust.Excel.RegionMapper', 'Regions', 'Map the regions that were found in the worksheet to regions that the system uses', '/csr/site/ct/components/excel/CountryCombo.js', 'CarbonTrust.excel.CountryCombo');
	INSERT INTO CSR.WORKSHEET_VALUE_MAPPER (VALUE_MAPPER_ID, CLASS_TYPE, MAPPER_NAME, MAPPER_DESCRIPTION, JS_COMPONENT_PATH, JS_COMPONENT) VALUES (102, 'Credit360.CarbonTrust.Excel.BreakdownMapper', '{breakdownTypePlural}', 'Map the {breakdownTypePlural} that were found in the worksheet to {breakdownTypePlural} that the system uses', '/csr/site/ct/components/excel/BreakdownPicker.js', 'CarbonTrust.excel.BreakdownPicker');
	INSERT INTO CSR.WORKSHEET_VALUE_MAPPER (VALUE_MAPPER_ID, CLASS_TYPE, MAPPER_NAME, MAPPER_DESCRIPTION, JS_COMPONENT_PATH, JS_COMPONENT) VALUES (103, 'Credit360.CarbonTrust.Excel.SupplierMapper', 'Suppliers', 'Map the suppliers that were found in the worksheet to suppliers that the system uses', '/csr/site/ct/components/excel/SupplierCombo.js', 'CarbonTrust.excel.SupplierCombo');	
		
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION, REQUIRED) VALUES (1000, 100,  1, NULL, 'Description', 'The description of the product or service', 1);
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION, REQUIRED) VALUES (1001, 100,  2, NULL, 'Purchase date', 'The date when the product or service was purchased', 1);
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION, REQUIRED) VALUES (1002, 100,  3, NULL, 'Spend', 'Spend amount', 1);
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1003, 100,  4, 100, 'Currency', 'The currency of purchase of the product or service');
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1004, 100,  4, 101, 'Country of manufacture', 'Country where the product was manufactured');
	--INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1005, 100,  5, 102, '{breakdownTypeSingular}', 'The {breakdownTypeSingular} that purchased the product or service');
	--INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1006, 100,  6, 102, '{breakdownTypeSingular} country', 'The country of operation of the {breakdownTypeSingular} that purchased the product or service');
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1007, 100,  7, 103, 'Supplier Id', 'User reference id for the supplier');
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1008, 100,  8, 103, 'Supplier name', 'The name of the supplier of the product or service');
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1009, 100,  9, NULL, 'Supplier contact name', 'The name of the contact for the supplier');
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1010, 100, 10, NULL, 'Supplier contact email', 'The email address of the supplier contact');
	
END;
/

create or replace package chain.excel_pkg as
    procedure dummy;
end;
/
create or replace package body chain.excel_pkg as
    procedure dummy
    as
    begin
        null;
    end;
end;
/


GRANT EXECUTE ON CHAIN.EXCEL_PKG TO WEB_USER;

@..\excel_pkg
@..\excel_body
@..\chain\excel_pkg
@..\chain\excel_body
@..\chain\card_pkg
@..\chain\card_body
@..\ct\products_services_pkg
@..\ct\products_services_body

@update_tail
