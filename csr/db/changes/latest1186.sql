-- Please update version.sql too -- this keeps clean builds in sync
define version=1186
@update_header

-- currency base data
ALTER TABLE CT.CURRENCY_PERIOD
ADD (CONVERSION_TO_DOLLAR NUMBER(20,10));

UPDATE ct.currency_period SET conversion_to_dollar = 1 WHERE period_id = 11 AND currency_id = 1;
UPDATE ct.currency_period SET conversion_to_dollar = 1 WHERE period_id = 10 AND currency_id = 1;
UPDATE ct.currency_period SET conversion_to_dollar = 1 WHERE period_id = 9 AND currency_id = 1;
UPDATE ct.currency_period SET conversion_to_dollar = 1 WHERE period_id = 8 AND currency_id = 1;
UPDATE ct.currency_period SET conversion_to_dollar = 1 WHERE period_id = 7 AND currency_id = 1;
UPDATE ct.currency_period SET conversion_to_dollar = 1 WHERE period_id = 6 AND currency_id = 1;
UPDATE ct.currency_period SET conversion_to_dollar = 1 WHERE period_id = 5 AND currency_id = 1;
UPDATE ct.currency_period SET conversion_to_dollar = 1 WHERE period_id = 4 AND currency_id = 1;
UPDATE ct.currency_period SET conversion_to_dollar = 1 WHERE period_id = 3 AND currency_id = 1;
UPDATE ct.currency_period SET conversion_to_dollar = 1 WHERE period_id = 2 AND currency_id = 1;
UPDATE ct.currency_period SET conversion_to_dollar = 1 WHERE period_id = 1 AND currency_id = 1;


UPDATE ct.currency_period SET conversion_to_dollar = 0.634098360655739 WHERE period_id = 11 AND currency_id = 2;
UPDATE ct.currency_period SET conversion_to_dollar = 0.6236 WHERE period_id = 10 AND currency_id = 2;
UPDATE ct.currency_period SET conversion_to_dollar = 0.647569721115538 WHERE period_id = 9 AND currency_id = 2;
UPDATE ct.currency_period SET conversion_to_dollar = 0.641513944223107 WHERE period_id = 8 AND currency_id = 2;
UPDATE ct.currency_period SET conversion_to_dollar = 0.544563492063493 WHERE period_id = 7 AND currency_id = 2;
UPDATE ct.currency_period SET conversion_to_dollar = 0.499840637450201 WHERE period_id = 6 AND currency_id = 2;
UPDATE ct.currency_period SET conversion_to_dollar = 0.543359999999999 WHERE period_id = 5 AND currency_id = 2;
UPDATE ct.currency_period SET conversion_to_dollar = 0.549359999999999 WHERE period_id = 4 AND currency_id = 2;
UPDATE ct.currency_period SET conversion_to_dollar = 0.545952380952382 WHERE period_id = 3 AND currency_id = 2;
UPDATE ct.currency_period SET conversion_to_dollar = 0.612390438247013 WHERE period_id = 2 AND currency_id = 2;
UPDATE ct.currency_period SET conversion_to_dollar = 0.666972111553784 WHERE period_id = 1 AND currency_id = 2;

UPDATE ct.currency_period SET conversion_to_dollar = 0.77016393442623 WHERE period_id = 11 AND currency_id = 3;
UPDATE ct.currency_period SET conversion_to_dollar = 0.718879999999999 WHERE period_id = 10 AND currency_id = 3;
UPDATE ct.currency_period SET conversion_to_dollar = 0.755776892430279 WHERE period_id = 9 AND currency_id = 3;
UPDATE ct.currency_period SET conversion_to_dollar = 0.719641434262948 WHERE period_id = 8 AND currency_id = 3;
UPDATE ct.currency_period SET conversion_to_dollar = 0.683333333333333 WHERE period_id = 7 AND currency_id = 3;
UPDATE ct.currency_period SET conversion_to_dollar = 0.730478087649402 WHERE period_id = 6 AND currency_id = 3;
UPDATE ct.currency_period SET conversion_to_dollar = 0.797120000000002 WHERE period_id = 5 AND currency_id = 3;
UPDATE ct.currency_period SET conversion_to_dollar = 0.80468 WHERE period_id = 4 AND currency_id = 3;
UPDATE ct.currency_period SET conversion_to_dollar = 0.804801587301587 WHERE period_id = 3 AND currency_id = 3;
UPDATE ct.currency_period SET conversion_to_dollar = 0.885458167330677 WHERE period_id = 2 AND currency_id = 3;
UPDATE ct.currency_period SET conversion_to_dollar = 1.00859375 WHERE period_id = 1 AND currency_id = 3;


UPDATE ct.currency_period SET conversion_to_dollar = 6.31967213114753 WHERE period_id = 11 AND currency_id = 4;
UPDATE ct.currency_period SET conversion_to_dollar = 6.46435999999999 WHERE period_id = 10 AND currency_id = 4;
UPDATE ct.currency_period SET conversion_to_dollar = 6.76964143426292 WHERE period_id = 9 AND currency_id = 4;
UPDATE ct.currency_period SET conversion_to_dollar = 6.83163346613544 WHERE period_id = 8 AND currency_id = 4;
UPDATE ct.currency_period SET conversion_to_dollar = 6.95063492063493 WHERE period_id = 7 AND currency_id = 4;
UPDATE ct.currency_period SET conversion_to_dollar = 7.6083266932271 WHERE period_id = 6 AND currency_id = 4;
UPDATE ct.currency_period SET conversion_to_dollar = 7.97359999999999 WHERE period_id = 5 AND currency_id = 4;
UPDATE ct.currency_period SET conversion_to_dollar = 8.19111999999999 WHERE period_id = 4 AND currency_id = 4;
UPDATE ct.currency_period SET conversion_to_dollar = 8.27809523809522 WHERE period_id = 3 AND currency_id = 4;
UPDATE ct.currency_period SET conversion_to_dollar = 8.27904382470117 WHERE period_id = 2 AND currency_id = 4;
UPDATE ct.currency_period SET conversion_to_dollar = 8.27929687499998 WHERE period_id = 1 AND currency_id = 4;

UPDATE ct.currency_period SET conversion_to_dollar = 0.967704918032787 WHERE period_id = 11 AND currency_id = 5;
UPDATE ct.currency_period SET conversion_to_dollar = 0.96972 WHERE period_id = 10 AND currency_id = 5;
UPDATE ct.currency_period SET conversion_to_dollar = 1.08980079681275 WHERE period_id = 9 AND currency_id = 5;
UPDATE ct.currency_period SET conversion_to_dollar = 1.28187250996016 WHERE period_id = 8 AND currency_id = 5;
UPDATE ct.currency_period SET conversion_to_dollar = 1.19515873015873 WHERE period_id = 7 AND currency_id = 5;
UPDATE ct.currency_period SET conversion_to_dollar = 1.19569721115538 WHERE period_id = 6 AND currency_id = 5;
UPDATE ct.currency_period SET conversion_to_dollar = 1.32848 WHERE period_id = 5 AND currency_id = 5;
UPDATE ct.currency_period SET conversion_to_dollar = 1.3118 WHERE period_id = 4 AND currency_id = 5;
UPDATE ct.currency_period SET conversion_to_dollar = 1.35964285714286 WHERE period_id = 3 AND currency_id = 5;
UPDATE ct.currency_period SET conversion_to_dollar = 1.54139442231076 WHERE period_id = 2 AND currency_id = 5;
UPDATE ct.currency_period SET conversion_to_dollar = 1.8096875 WHERE period_id = 1 AND currency_id = 5;

UPDATE ct.currency_period SET conversion_to_dollar = 79.7140983606557 WHERE period_id = 11 AND currency_id =6;
UPDATE ct.currency_period SET conversion_to_dollar = 79.71612 WHERE period_id = 10 AND currency_id =6;
UPDATE ct.currency_period SET conversion_to_dollar = 87.7762549800797 WHERE period_id = 9 AND currency_id =6;
UPDATE ct.currency_period SET conversion_to_dollar = 93.6050199203187 WHERE period_id = 8 AND currency_id =6;
UPDATE ct.currency_period SET conversion_to_dollar = 103.449603174603 WHERE period_id = 7 AND currency_id =6;
UPDATE ct.currency_period SET conversion_to_dollar = 117.808007968128 WHERE period_id = 6 AND currency_id =6;
UPDATE ct.currency_period SET conversion_to_dollar = 116.30224 WHERE period_id = 5 AND currency_id =6;
UPDATE ct.currency_period SET conversion_to_dollar = 110.1134 WHERE period_id = 4 AND currency_id =6;
UPDATE ct.currency_period SET conversion_to_dollar = 108.138968253968 WHERE period_id = 3 AND currency_id =6;
UPDATE ct.currency_period SET conversion_to_dollar = 115.929083665339 WHERE period_id = 2 AND currency_id =6;
UPDATE ct.currency_period SET conversion_to_dollar = 120.867734375 WHERE period_id = 1 AND currency_id =6;

ALTER TABLE CT.CURRENCY_PERIOD
	MODIFY(CONVERSION_TO_DOLLAR  NOT NULL);

ALTER TABLE CT.CURRENCY_PERIOD ADD CONSTRAINT CC_CP_CONVERSION_TO_DOLLAR 
    CHECK (CONVERSION_TO_DOLLAR > 0);
	
@..\ct\admin_pkg
@..\ct\admin_body
	
@update_tail
