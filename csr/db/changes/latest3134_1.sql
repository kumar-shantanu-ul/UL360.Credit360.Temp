-- Please update version.sql too -- this keeps clean builds in sync
define version=3134
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_root_product_type_id			NUMBER(10, 0);
BEGIN
	FOR r IN (
		SELECT c.host, c.app_sid
		  FROM csr.customer c
		  JOIN chain.product_metric pm ON pm.app_sid = c.app_sid
		 GROUP BY c.host, c.app_sid
	) LOOP
		security.user_pkg.logonadmin(r.host);

		BEGIN
			SELECT product_type_id
			  INTO v_root_product_type_id
			  FROM chain.product_type
			 WHERE parent_product_type_id IS NULL
			   AND app_sid = r.app_sid;

		EXCEPTION
			WHEN no_data_found THEN
				CONTINUE;
			WHEN too_many_rows THEN
				CONTINUE;
		END;

		INSERT INTO chain.product_metric_product_type (app_sid, ind_sid, product_type_id)
		SELECT r.app_sid, pm.ind_sid, v_root_product_type_id
		  FROM chain.product_metric pm
		  LEFT JOIN chain.product_metric_product_type pmpt ON pmpt.app_sid = pm.app_sid AND pmpt.ind_sid = pm.ind_sid
		 WHERE pmpt.product_type_id IS NULL;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/product_metric_pkg
@../chain/product_metric_body

@update_tail
