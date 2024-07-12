-- Please update version.sql too -- this keeps clean builds in sync
define version=54
@update_header

ALTER TABLE CUSTOMER_OPTIONS ADD (
	REGION_PICKER_CONFIG       VARCHAR2(2048)
);

ALTER TABLE TAG_GROUP ADD (
	LABEL             			VARCHAR2(1024)
);

UPDATE customer_options SET
	region_picker_config = 
		 '[{' ||
            'level: 3,' ||
            'width: 200,' ||
            'search: false' ||
        '}, {' ||
            'level: 4,' ||
            'width: 200,' ||
            'search: false,' ||
            'button: {' ||
                'id: "pickerAddCountryButton",' ||
                'text: "Add country",' ||
                'iconCls: "tbNew",' ||
                'handler: null' ||
           '}' ||
        '}, {' ||
            'level: -1,' ||
            'width: 400,' ||
            'search: true,' ||
            'button: {' ||
                'id: "pickerAddRegionButton",' ||
                'text: "Add property",' ||
                'iconCls: "tbNew",' ||
                'handler: null' ||
           '}' ||
        '}]'
 WHERE app_sid = (
	SELECT app_sid
	  FROM csr.customer
	 WHERE host = 'rbsenv.credit360.com'
 );

-- Update label for rbsenv initiative sub-type
UPDATE tag_group
   SET label = 'What type of initiative is it? (Please select from the list below)'
 WHERE name = 'initiative_sub_type'
   AND app_sid = (
	SELECT app_sid
	  FROM csr.customer
	 WHERE host = 'rbsenv.credit360.com'
 );

COMMIT;

@update_tail
