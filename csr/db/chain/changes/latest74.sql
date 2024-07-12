define version=74
@update_header

-- update any companies that have a null country_code to match the country code of the top company for the application
UPDATE chain.company nc
   SET country_code = (
		SELECT c.country_code
		  FROM chain.company c, chain.customer_options co
		 WHERE c.app_sid = co.app_sid
		   AND c.company_sid = co.top_company_sid
		   AND c.app_sid = nc.app_sid
	)
 WHERE country_code IS NULL;

-- if we still have any companies with a null country code, set it to 'gb' for lack of a better option (this would happen if top_company_sid is null)
UPDATE chain.company 
   SET country_code = 'gb'
 WHERE country_code IS NULL;
 

ALTER TABLE chain.COMPANY MODIFY COUNTRY_CODE NOT NULL;

@update_tail