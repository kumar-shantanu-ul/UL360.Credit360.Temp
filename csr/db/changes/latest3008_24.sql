-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=24
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE chain.business_rel_period_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

CREATE TABLE chain.business_relationship_period (
    app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	business_rel_period_id			NUMBER(10,0) NOT NULL,
	business_relationship_id		NUMBER(10,0) NOT NULL,
	start_dtm						DATE NOT NULL,
	end_dtm							DATE,
    CONSTRAINT PK_BUSINESS_REL_PERIOD PRIMARY KEY (app_sid, business_rel_period_id),
	CONSTRAINT FK_BUS_REL_PERIOD_BUS_REL FOREIGN KEY (app_sid, business_relationship_id) REFERENCES chain.business_relationship (app_sid, business_relationship_id),
	CONSTRAINT CK_BUS_REL_PERIOD_END_DTM CHECK (end_dtm IS NULL OR end_dtm >= start_dtm)
);

create index chain.ix_bus_rel_period_bus_rel on chain.business_relationship_period (app_sid, business_relationship_id);

INSERT INTO chain.business_relationship_period (app_sid, business_rel_period_id, business_relationship_id, start_dtm, end_dtm)
	 SELECT app_sid, chain.business_rel_period_id_seq.NEXTVAL, business_relationship_id,
			CASE WHEN end_dtm IS NOT NULL AND end_dtm < start_dtm THEN end_dtm ELSE start_dtm END start_dtm, 
			end_dtm
	   FROM chain.business_relationship;

CREATE TABLE csrimp.chain_busin_relat_period (
	csrimp_session_id NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	business_rel_period_id			NUMBER(10,0) NOT NULL,
	business_relationship_id		NUMBER(10,0) NOT NULL,
	start_dtm						DATE NOT NULL,
	end_dtm							DATE,
	CONSTRAINT pk_chain_busin_relat_period PRIMARY KEY (csrimp_session_id, business_rel_period_id),
	CONSTRAINT fk_chain_busin_relat_period_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE csrimp.map_chain_bus_rel_period (
	csrimp_session_id NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_business_rel_period_id NUMBER(10) NOT NULL,
	new_business_rel_period_id NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_chain_bus_rel_period PRIMARY KEY (csrimp_session_id, old_business_rel_period_id) USING INDEX,
	CONSTRAINT uk_map_chain_bus_rel_period UNIQUE (csrimp_session_id, new_business_rel_period_id) USING INDEX,
	CONSTRAINT fk_map_chain_bus_rel_period_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE chain.business_relationship ADD (
	signature						VARCHAR2(255) 
);

ALTER TABLE chain.business_relationship RENAME COLUMN start_dtm TO xxx_start_dtm;
ALTER TABLE chain.business_relationship RENAME COLUMN end_dtm TO xxx_end_dtm;
ALTER TABLE chain.business_relationship RENAME COLUMN end_reason TO xxx_end_reason;

ALTER TABLE csrimp.chain_business_relations DROP COLUMN start_dtm;
ALTER TABLE csrimp.chain_business_relations DROP COLUMN end_dtm;
ALTER TABLE csrimp.chain_business_relations DROP COLUMN end_reason;

-- the schema on my laptop didn't match the one on live, so do this conditionally
DECLARE
	v_nullable VARCHAR2(1);
BEGIN
	SELECT nullable
	  INTO v_nullable
	  FROM all_tab_columns
	 WHERE owner = 'CHAIN'
	   AND table_name = 'BUSINESS_RELATIONSHIP'
	   AND column_name = 'XXX_START_DTM';

	IF v_nullable = 'N' THEN
		EXECUTE IMMEDIATE 'ALTER TABLE chain.business_relationship MODIFY ( xxx_start_dtm NULL )';
	END IF;
END;
/

-- *** Grants ***
GRANT SELECT ON chain.business_rel_period_id_seq TO csrimp;
GRANT SELECT, INSERT, UPDATE ON chain.business_relationship_period TO csrimp;

GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.chain_busin_relat_period TO tool_user;

GRANT SELECT ON chain.business_relationship_period TO csr;


-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	UPDATE chain.capability 
	   SET capability_name = 'Update company business relationship periods'
	 WHERE capability_name = 'Terminate company business relationships';

	UPDATE chain.capability
	   SET capability_name = 'Update company business relationship periods (supplier => purchaser)'
	 WHERE capability_name = 'Terminate company business relationships (supplier => purchaser)';

	COMMIT;
END;
/

-- It would be OK for this to run after the release if needed
BEGIN
	FOR r IN (
		SELECT br.business_relationship_id, br.business_relationship_type_id || ':' || listagg(brc.company_sid, ',') WITHIN GROUP (order by brt.tier) signature
		  FROM chain.business_relationship br
		  JOIN chain.business_relationship_company brc ON brc.business_relationship_id = br.business_relationship_id AND brc.app_sid = br.app_sid
		  JOIN chain.business_relationship_tier brt ON brt.business_relationship_tier_id = brc.business_relationship_tier_id AND brt.app_sid = brc.app_sid
		 GROUP BY br.business_relationship_id, br.business_relationship_type_id
	) LOOP
		UPDATE chain.business_relationship
		   SET signature = r.signature
		 WHERE business_relationship_id = r.business_relationship_id;
	END LOOP;

	COMMIT;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/business_relationship_pkg
@../chain/chain_pkg
@../chain/chain_link_pkg
@../schema_pkg
@../csrimp/imp_pkg

@../chain/business_relationship_body
@../chain/chain_body
@../chain/chain_link_body
@../schema_body
@../csrimp/imp_body

@update_tail
