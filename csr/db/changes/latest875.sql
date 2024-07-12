-- Please update version.sql too -- this keeps clean builds in sync
define version=875
@update_header

ALTER TABLE ACTIONS.IND_TEMPLATE ADD (
	CALC_PERIOD_DURATION		NUMBER(10,0)
);

DECLARE
	v_ivalid	BOOLEAN;
	v_rtvalid	BOOLEAN;
	v_calc_xml	VARCHAR2(1024);
BEGIN
	FOR r IN (
		SELECT ind_template_id, npv_net_name, npv_net_key, npv_rate_name, npv_rate_key
		  FROM actions.ind_template
		 WHERE is_npv = 1
	) LOOP
		v_ivalid := FALSE;
		v_rtvalid := FALSE;
		
		v_calc_xml := '<npv><i><path ';
		
		IF r.npv_rate_name IS NOT NULL THEN
			v_calc_xml := v_calc_xml || 'template="'||r.npv_rate_name||'"';
			v_ivalid := TRUE;
		ELSIF r.npv_rate_key IS NOT NULL THEN
			v_calc_xml := v_calc_xml || 'lookup="'||r.npv_rate_key||'"';
			v_ivalid := TRUE;
		END IF;
		
		v_calc_xml := v_calc_xml || '/></i><rt><path ';
		
		IF r.npv_rate_name IS NOT NULL THEN
			v_calc_xml := v_calc_xml || 'template="'||r.npv_net_name||'"';
			v_rtvalid := TRUE;
		ELSIF r.npv_rate_key IS NOT NULL THEN
			v_calc_xml := v_calc_xml || 'lookup="'||r.npv_net_key||'"';
			v_rtvalid := TRUE;
		END IF;
		
		v_calc_xml := v_calc_xml || '/></rt></npv>';
		
		IF v_ivalid AND v_rtvalid THEN
			UPDATE actions.ind_template
			   SET calculation = v_calc_xml,
			   	   is_stored_calc = 1,
			   	   calc_period_duration = 12
			 WHERE ind_template_id = r.ind_template_id;
		END IF;
	END LOOP;	
END;
/

ALTER TABLE ACTIONS.IND_TEMPLATE DROP CONSTRAINT CHK_NPV_INPUT;
ALTER TABLE ACTIONS.IND_TEMPLATE DROP (
	NPV_NET_NAME,
	NPV_NET_KEY,
	NPV_RATE_NAME,
	NPV_RATE_KEY
);

ALTER TABLE ACTIONS.IND_TEMPLATE ADD CONSTRAINT CHK_NPV_STORED_NODIV 
	CHECK (IS_NPV = 0 OR (IS_STORED_CALC = 1 AND DIVISIBLE = 0));


grant select, update, references on csr.ind to actions;

@../actions/initiative_pkg
@../actions/ind_template_pkg

@../actions/task_body
@../actions/initiative_body
@../actions/ind_template_body


@update_tail
