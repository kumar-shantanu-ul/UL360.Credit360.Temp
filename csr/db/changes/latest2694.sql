-- Please update version.sql too -- this keeps clean builds in sync
define version=2694
@update_header

-- table renamed in 2684 
-- need to drop it as it causes integr constraint errors on deleting parent ref records
DECLARE
	v_count		NUMBER;
begin
	-- Check if UPD user exists (customer installs don't have it).
	SELECT COUNT(*)
	  INTO v_count
	  FROM dba_users
	 WHERE username = UPPER ('UPD');

	for r in (select 1 from all_tables where owner='CSR' and table_name='XX_FLOW_ITEM_ALERT') loop
		IF v_count = 1 THEN
			execute immediate 'CREATE TABLE upd.xx_flow_item_alert AS SELECT * FROM csr.xx_flow_item_alert';
		ELSE
			-- Create as logged in user if UPD doesn't exist.
			EXECUTE IMMEDIATE 'CREATE TABLE xx_flow_item_alert AS SELECT * FROM csr.xx_flow_item_alert';
		END IF;
		
		execute immediate 'DROP TABLE csr.xx_flow_item_alert CASCADE CONSTRAINTS';
	end loop;
end;
/

@update_tail
