-- Please update version.sql too -- this keeps clean builds in sync
define version=1730
@update_header

grant select, references on chain.company_type to ct;
grant execute on chain.setup_pkg to ct;
grant execute on chain.card_pkg to ct;
grant execute on chain.T_STRING_LIST to ct;
grant execute on chain.T_CARD_ACTION_LIST to ct;
grant execute on chain.T_CARD_ACTION_ROW to ct;
grant select, references, insert on csr.alert_frame to ct;
grant select, references, insert on csr.customer_alert_type to ct;
grant select on csr.default_alert_frame to ct;
grant select on csr.alert_frame_id_seq to ct;
grant select on csr.std_alert_type to ct;
grant select on csr.customer_alert_type_id_seq to ct;
grant execute on csr.alert_pkg to ct;
grant execute on chain.questionnaire_pkg to ct;
grant execute on chain.type_capability_pkg to ct;


ALTER TABLE CT.CUSTOMER_OPTIONS ADD (
    TOP_COMPANY_TYPE_ID NUMBER(10),
    SUPPLIER_COMPANY_TYPE_ID NUMBER(10)
);

ALTER TABLE CT.CUSTOMER_OPTIONS ADD CONSTRAINT FK_CT_CO_TOP_COMPANY_TYPE 
    FOREIGN KEY (APP_SID, TOP_COMPANY_TYPE_ID) REFERENCES CHAIN.COMPANY_TYPE (APP_SID,COMPANY_TYPE_ID);

ALTER TABLE CT.CUSTOMER_OPTIONS ADD CONSTRAINT CT_CO_SUP_COMPANY_TYPE 
    FOREIGN KEY (APP_SID, SUPPLIER_COMPANY_TYPE_ID) REFERENCES CHAIN.COMPANY_TYPE (APP_SID,COMPANY_TYPE_ID);

BEGIN
	UPDATE chain.customer_options 
	   SET use_type_capabilities = 1 
	 WHERE app_sid IN (SELECT app_sid FROM chain.v$chain_host WHERE name = 'CT');

	UPDATE chain.company_type
	   SET lookup_key = 'SUPPLIER',
	       singular = 'Supplier',
	       plural = 'Suppliers',
	       position = 1
	 WHERE app_sid IN (SELECT app_sid FROM chain.v$chain_host WHERE name = 'CT');

	INSERT INTO chain.company_type
	(app_sid, company_type_id, lookup_key, singular, plural, allow_lower_case, is_top_company, position)
	SELECT app_sid, chain.company_type_id_seq.nextval, 'TOP', 'Company', 'Companies', 1, 1, 0
	  FROM chain.v$chain_host 
	 WHERE name = 'CT';

	UPDATE chain.company c
	   SET company_type_id = (
	   		SELECT company_type_id 
	   		  FROM chain.company_type ct 
	   		 WHERE ct.app_sid = c.app_sid
	   		   AND ct.is_top_company = 1
	   		)
	 WHERE (c.app_sid, c.company_sid) IN (
	 		SELECT co.app_sid, co.top_company_sid 
	 		  FROM chain.v$chain_host c, chain.customer_options co
	 		 WHERE c.name = 'CT'
	 		   AND c.app_sid = co.app_sid);

	UPDATE ct.customer_options co
	   SET top_company_type_id = (
	   		SELECT company_type_id
	   		  FROM chain.company_type ct
	   		 WHERE ct.app_sid = co.app_sid
	   		   AND ct.is_top_company = 1
	   );
	   
	UPDATE ct.customer_options co
	   SET supplier_company_type_id = (
	   		SELECT company_type_id
	   		  FROM chain.company_type ct
	   		 WHERE ct.app_sid = co.app_sid
	   		   AND ct.is_default = 1
	   );
	
END;
/

ALTER TABLE CT.CUSTOMER_OPTIONS MODIFY TOP_COMPANY_TYPE_ID NOT NULL;
ALTER TABLE CT.CUSTOMER_OPTIONS MODIFY SUPPLIER_COMPANY_TYPE_ID NOT NULL;

CREATE OR REPLACE FORCE VIEW ct.v$ps_item (
    app_sid, company_sid, supplier_id, breakdown_id, region_id, item_id, description,
	spend, currency_id, purchase_date, created_by_sid, created_dtm, modified_by_sid,
	last_modified_dtm, row_number, worksheet_id, 
	auto_eio_id, auto_eio_id_score, auto_eio_id_two, auto_eio_id_score_two, match_auto_accepted, kg_co2,
	spend_in_company_currency, spend_in_dollars, company_currency_id
)
AS
SELECT
    i.app_sid, 
	i.company_sid, 
	i.supplier_id, 
	i.breakdown_id, 
	i.region_id, 
	i.item_id, 
	i.description,
	i.spend, 
	i.currency_id, 
	i.purchase_date, 
	i.created_by_sid, 
	i.created_dtm, 
	i.modified_by_sid,
	i.last_modified_dtm, 
	row_number, 
	i.worksheet_id,
	i.auto_eio_id, i.auto_eio_id_score, i.auto_eio_id_two, i.auto_eio_id_score_two, i.match_auto_accepted,
	i.kg_co2,
	ROUND(i.spend * util_pkg.GetConversionToDollar(i.currency_id, i.purchase_date) * util_pkg.GetConversionFromDollar(c.currency_id, i.purchase_date),2) spend_in_company_currency,
	ROUND(i.spend * util_pkg.GetConversionToDollar(i.currency_id, i.purchase_date), 2) spend_in_dollars,
	c.currency_id company_currency_id
 FROM ct.ps_item i, company c
WHERE i.app_sid = c.app_sid
  AND c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
  AND c.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
  
@..\ct\setup_pkg
@..\ct\util_pkg  
@..\ct\util_body
@..\ct\link_body
@..\ct\setup_body
@..\ct\supplier_body
  
  
@update_tail
