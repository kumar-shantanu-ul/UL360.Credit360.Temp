-- Please update version.sql too -- this keeps clean builds in sync
define version=76
@update_header

ALTER TABLE CUSTOMER_OPTIONS ADD (
	REGION_LEVEL                     NUMBER(10, 0)     NULL,
    COUNTRY_LEVEL                    NUMBER(10, 0)     NULL,
    PROPERTY_LEVEL                   NUMBER(10, 0)     NULL
);

-- Set defaults for all customers
UPDATE customer_options
   SET region_level = 2,
   	   country_level = 3,
   	   property_level = 3
;

ALTER TABLE CUSTOMER_OPTIONS MODIFY (
	REGION_LEVEL                     NUMBER(10, 0)     NOT NULL,
    COUNTRY_LEVEL                    NUMBER(10, 0)     NOT NULL,
    PROPERTY_LEVEL                   NUMBER(10, 0)     NOT NULL
);

@../initiative_body

@update_tail
