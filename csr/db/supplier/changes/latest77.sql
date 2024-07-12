-- Please update version.sql too -- this keeps clean builds in sync
define version=77
@update_header


ALTER TABLE supplier.CONTACT_SHORTLIST ADD (
    CURRENCY_CODE             VARCHAR2(4)
);

UPDATE CONTACT_SHORTLIST SET CURRENCY_CODE = (
	SELECT UPPER(ABBREVIATION) 
  	  FROM CURRENCY C 
 	 WHERE C.CURRENCY_ID = CONTACT_SHORTLIST.CURRENCY_ID
);

-- if currency is nullable, so should annual spend be
ALTER TABLE supplier.CONTACT_SHORTLIST MODIFY ESTIMATED_ANNUAL_SPEND   NULL;

ALTER TABLE supplier.CONTACT_SHORTLIST DROP CONSTRAINT RefCURRENCY522;


DROP TABLE supplier.CURRENCY PURGE;

CREATE TABLE supplier.CURRENCY(
    CURRENCY_CODE    VARCHAR2(4)     NOT NULL,
    LABEL          VARCHAR2(64)    NOT NULL,
    CONSTRAINT PK172 PRIMARY KEY (CURRENCY_CODE)
)
;

BEGIN
    INSERT INTO supplier.currency (currency_code, label) VALUES ('USD', 'US Dollars');
    INSERT INTO supplier.currency (currency_code, label) VALUES ('EUR', 'Euros');
    INSERT INTO supplier.currency (currency_code, label) VALUES ('GBP', 'Pounds Sterling');
END;
/

ALTER TABLE supplier.CONTACT_SHORTLIST ADD CONSTRAINT RefCURRENCY522 
    FOREIGN KEY (CURRENCY_CODE)
    REFERENCES supplier.CURRENCY(CURRENCY_CODE)
;

-- drop old column
ALTER TABLE supplier.CONTACT_SHORTLIST DROP COLUMN CURRENCY_ID;


@update_tail
