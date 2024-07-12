CREATE OR REPLACE TRIGGER csr.UTILIY_CONTRACT_BD_TRIGGER
BEFORE DELETE
    ON csr.UTILITY_CONTRACT
    FOR EACH ROW
DECLARE
BEGIN
    DELETE FROM meter_utility_contract
     WHERE utility_contract_id = :OLD.utility_contract_id;
END;
/

CREATE OR REPLACE TRIGGER csr.UTILIY_INVOICE_BD_TRIGGER
BEFORE DELETE
    ON csr.UTILITY_INVOICE
    FOR EACH ROW
DECLARE
BEGIN
    UPDATE meter_reading
       SET created_invoice_id = NULL
     WHERE created_invoice_id = :OLD.utility_invoice_id;
END;
/
