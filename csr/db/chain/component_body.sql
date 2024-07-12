CREATE OR REPLACE PACKAGE BODY CHAIN.component_pkg
IS

/**********************************************************************************
	PRIVATE
**********************************************************************************/
PROCEDURE FillTypeContainment
AS
BEGIN
	DELETE FROM tt_component_type_containment;
	
	INSERT INTO tt_component_type_containment
	(container_component_type_id, child_component_type_id, allow_add_existing, allow_add_new)
	SELECT container_component_type_id, child_component_type_id, allow_add_existing, allow_add_new
	  FROM component_type_containment
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	chain_link_pkg.FilterComponentTypeContainment;
END;

FUNCTION CheckCapability (
	in_component_id			IN  component.component_id%TYPE,
	in_permission_set		IN  security_pkg.T_PERMISSION
) RETURN BOOLEAN
AS
	v_company_sid			security_pkg.T_SID_ID DEFAULT NVL(GetCompanySid(in_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
BEGIN
	RETURN capability_pkg.CheckCapability(v_company_sid, chain_pkg.COMPONENTS, in_permission_set);
END;

PROCEDURE CheckCapability (
	in_component_id			IN  component.component_id%TYPE,
	in_permission_set		IN  security_pkg.T_PERMISSION
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT CheckCapability(in_component_id, in_permission_set)  THEN
		
		v_company_sid := NVL(GetCompanySid(in_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
		
		IF in_permission_set = security_pkg.PERMISSION_WRITE THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to components for company with sid '||v_company_sid);
		
		ELSIF in_permission_set = security_pkg.PERMISSION_READ THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to components for company with sid '||v_company_sid);
		
		ELSIF in_permission_set = security_pkg.PERMISSION_DELETE THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied to components for company with sid '||v_company_sid);
		
		ELSE
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied (perm_set:'||in_permission_set||') to components for company with sid '||v_company_sid);
		
		END IF;
	END IF;
END;

FUNCTION GetTypeId (
	in_component_id			IN component.component_id%TYPE
) RETURN chain_pkg.T_COMPONENT_TYPE
AS
	v_type_id 				chain_pkg.T_COMPONENT_TYPE;
BEGIN
	SELECT component_type_id
	  INTO v_type_id
	  FROM component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id;
	
	RETURN v_type_id;
END;

FUNCTION GetHandlerPkg (
	in_type_id				chain_pkg.T_COMPONENT_TYPE
) RETURN all_component_type.handler_pkg%TYPE
AS
	v_hp					all_component_type.handler_pkg%TYPE;
BEGIN
	SELECT handler_pkg
	  INTO v_hp
	  FROM v$component_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_type_id = in_type_id;
	
	RETURN v_hp;
END;

-- downstream means "up the supply chain" for us - e.g. Staples would be "upstream" of Bobs Paper Mills
FUNCTION IsInDownstreamCmpntSuppChain (
	in_component_id			IN  component.component_id%TYPE
) RETURN BOOLEAN
AS
	v_company_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_in_chain				NUMBER;
BEGIN
	
	WITH component_product_rel AS (
		SELECT 
				app_sid, 
				parent_component_id container_component_id, 
				parent_component_type_id container_component_type_id, 
				component_id child_component_id, 
				component_type_id child_component_type_id, 
				company_sid,
				amount_child_per_parent, 
				amount_unit_id
		  FROM component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND parent_component_id IS NOT NULL
		UNION ALL
		SELECT 
				pc.app_sid, 
				pc.component_id container_component_id,
				3 container_component_type_id, -- chain.chain_pkg.PURCHASED_COMPONENT
				p.supplier_root_component_id child_component_id, 
				1 child_component_type_id,  -- chain.chain_pkg.PRODUCT_COMPONENT
				pc.company_sid, 
				100 amount_child_per_parent, 
				1 amount_unit_id -- chain.chain_pkg.AU_PERCENTAGE unit ID for %
		  FROM purchased_component pc
		  LEFT JOIN v$product_last_revision p ON pc.app_sid = p.app_sid AND pc.supplier_product_id = p.product_id
		 WHERE pc.supplier_product_id IS NOT NULL
		   AND pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		UNION ALL
		SELECT 
				pc.app_sid, 
				pc.component_id container_component_id,
				3 container_component_type_id, -- chain.chain_pkg.PURCHASED_COMPONENT
				p.validated_root_component_id child_component_id, 
				1 child_component_type_id,  -- chain.chain_pkg.PRODUCT_COMPONENT
				pc.company_sid, 
				100 amount_child_per_parent, 
				1 amount_unit_id -- chain.chain_pkg.AU_PERCENTAGE unit ID for %
		  FROM purchased_component pc
		  JOIN v$product_last_revision p ON pc.app_sid = p.app_sid AND pc.supplier_product_id = p.product_id AND p.validated_root_component_id IS NOT NULL
		 WHERE pc.supplier_product_id IS NOT NULL
		   AND pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	)
	SELECT COUNT(*)  
	  INTO v_in_chain 
      FROM dual 
     WHERE v_company_sid IN (
        SELECT company_sid 
          FROM component_product_rel
         START WITH child_component_id = in_component_id
	   CONNECT BY PRIOR container_component_id = child_component_id
	 );

	RETURN v_in_chain>0;
END;

/**********************************************************************************
	MANAGEMENT
**********************************************************************************/
PROCEDURE ActivateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ActivateType can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO component_type
		(component_type_id)
		VALUES
		(in_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE CreateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_handler_class		IN  all_component_type.handler_class%TYPE,
	in_handler_pkg			IN  all_component_type.handler_pkg%TYPE,
	in_node_js_path			IN  all_component_type.node_js_path%TYPE,
	in_description			IN  all_component_type.description%TYPE
)
AS
BEGIN
	CreateType(in_type_id, in_handler_class, in_handler_pkg, in_node_js_path, in_description, NULL); 
END;

PROCEDURE CreateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_handler_class		IN  all_component_type.handler_class%TYPE,
	in_handler_pkg			IN  all_component_type.handler_pkg%TYPE,
	in_node_js_path			IN  all_component_type.node_js_path%TYPE,
	in_description			IN  all_component_type.description%TYPE,
	in_editor_card_group_id	IN  all_component_type.editor_card_group_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateType can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO all_component_type
		(component_type_id, handler_class, handler_pkg, node_js_path, description, editor_card_group_id)
		VALUES
		(in_type_id, in_handler_class, in_handler_pkg, in_node_js_path, in_description, in_editor_card_group_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE all_component_type
			   SET handler_class = in_handler_class,
			   	   handler_pkg = in_handler_pkg,
			   	   node_js_path = in_node_js_path,
			   	   description = in_description,
			   	   editor_card_group_id = in_editor_card_group_id
			 WHERE component_type_id = in_type_id;
	END;
END;

PROCEDURE ClearSources
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ClearSources can only be run as BuiltIn/Administrator');
	END IF;
	
	DELETE FROM component_source
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE AddSource (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE
)
AS
BEGIN
	AddSource(in_type_id, in_action, in_text, in_description, null);
END;


PROCEDURE AddSource (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE,
	in_card_group_id		IN  component_source.card_group_id%TYPE
)
AS
	v_max_pos				component_source.position%TYPE;
BEGIN
	
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'AddSource can only be run as BuiltIn/Administrator');
	END IF;
	
	IF in_action <> LOWER(TRIM(in_action)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Actions must be formatted as trimmed and lower case');
	END IF;
	
	ActivateType(in_type_id);
	
	SELECT MAX(position)
	  INTO v_max_pos
	  FROM component_source
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO component_source
	(component_type_id, card_text, progression_action, description_xml, card_group_id, position)
	VALUES
	(in_type_id, in_text, in_action, in_description, in_card_group_id, NVL(v_max_pos, 0) + 1);
	
	-- I don't think there's anything wrong with adding the actions to both cards, but feel free to correct this...
	card_pkg.AddProgressionAction('Chain.Cards.ComponentSource', in_action);
	card_pkg.AddProgressionAction('Chain.Cards.ComponentBuilder.ComponentSource', in_action);
END;

PROCEDURE GetSources (
	in_card_group_id		IN  component_source.card_group_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT component_type_id, progression_action, card_text, description_xml
		  FROM component_source
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND NVL(card_group_id, in_card_group_id) = in_card_group_id
		 ORDER BY position;
END;

PROCEDURE ClearTypeContainment
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ClearTypeContainment can only be run as BuiltIn/Administrator');
	END IF;

	DELETE FROM component_type_containment
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;


PROCEDURE SetTypeContainment (
	in_container_type_id				IN chain_pkg.T_COMPONENT_TYPE,
	in_child_type_id					IN chain_pkg.T_COMPONENT_TYPE,
	in_allow_flags						IN chain_pkg.T_FLAG
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetTypeContainment can only be run as BuiltIn/Administrator');
	END IF;
	
	ActivateType(in_container_type_id);
	ActivateType(in_child_type_id);
	
	BEGIN
		INSERT INTO component_type_containment
		(container_component_type_id, child_component_type_id)
		VALUES
		(in_container_type_id, in_child_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
		
	UPDATE component_type_containment
	   SET allow_add_existing = helper_pkg.Flag(in_allow_flags, chain_pkg.ALLOW_ADD_EXISTING),
	       allow_add_new = helper_pkg.Flag(in_allow_flags, chain_pkg.ALLOW_ADD_NEW)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_component_type_id = in_container_type_id
	   AND child_component_type_id = in_child_type_id;

END;

PROCEDURE GetTypeContainment (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	FillTypeContainment;

	OPEN out_cur FOR
		SELECT container_component_type_id, child_component_type_id, allow_add_existing, allow_add_new
		  FROM tt_component_type_containment;
END;

PROCEDURE CreateComponentAmountUnit (
	in_amount_unit_id		IN amount_unit.amount_unit_id%TYPE,
	in_description			IN amount_unit.description%TYPE,
	in_unit_type			IN amount_unit.unit_type%TYPE, 	
	in_conversion			IN amount_unit.conversion_to_base%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateComponentAmountUnit can only be run as BuiltIn/Administrator');
	END IF;
	
	-- conversion_to_base is what you multiply the metric value to get the base value
	BEGIN
		INSERT INTO amount_unit
		(amount_unit_id, description, unit_type, conversion_to_base)
		VALUES
		(in_amount_unit_id, in_description, in_unit_type, in_conversion);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE amount_unit
			   SET description = in_description, 
				   unit_type = in_unit_type,
				   conversion_to_base = in_conversion
			 WHERE amount_unit_id = in_amount_unit_id;
	END;
END;

/**********************************************************************************
	UTILITY
**********************************************************************************/
FUNCTION IsType (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE
) RETURN BOOLEAN
AS
	v_type_id		chain_pkg.T_COMPONENT_TYPE;
BEGIN
	BEGIN
		SELECT component_type_id
		  INTO v_type_id
		  FROM component
		 WHERE app_sid = security_pkg.GetApp
		   AND component_id = in_component_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN FALSE;
	END;
	
	RETURN NVL(v_type_id = in_type_id, FALSE);
END;

FUNCTION GetCompanySid (
	in_component_id		   IN component.component_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_company_sid 			company.company_sid%TYPE;
BEGIN
	BEGIN
		SELECT company_sid
		  INTO v_company_sid
		  FROM component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN NULL;
	END;
		
	RETURN v_company_sid;
END;

FUNCTION IsDeleted (
	in_component_id			IN component.component_id%TYPE
) RETURN BOOLEAN
AS
	v_deleted				component.deleted%TYPE;
BEGIN
	-- don't worry about sec as there's not much we can do with a bool flag...

	SELECT deleted
	  INTO v_deleted
	  FROM component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND component_id = in_component_id;
	
	RETURN v_deleted = chain_pkg.DELETED;
END;

PROCEDURE RecordTreeSnapshot (
	in_top_component_id		IN  component.component_id%TYPE
)
AS
	v_top_component_ids		T_NUMERIC_TABLE;
	v_count					NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM TT_COMPONENT_TREE
	 WHERE top_component_id = in_top_component_id;
	
	-- if we've already got entries, get out
	IF v_count > 0 THEN
		RETURN;
	END IF;
	
	SELECT T_NUMERIC_ROW(in_top_component_id, NULL)
	  BULK COLLECT INTO v_top_component_ids
	  FROM DUAL;
	
	RecordTreeSnapshot(v_top_component_ids);
END;

PROCEDURE RecordTreeSnapshot (
	in_top_component_ids	IN  T_NUMERIC_TABLE
)
AS
	v_unrecorded_ids		T_NUMERIC_TABLE;
	v_count					NUMBER(10);
BEGIN
	SELECT T_NUMERIC_ROW(item, NULL)
	  BULK COLLECT INTO v_unrecorded_ids
	  FROM TABLE(in_top_component_ids)
	 WHERE item NOT IN (SELECT top_component_id FROM TT_COMPONENT_TREE);
	 
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_unrecorded_ids);
	
	-- if there's nothing here, then they've all been collected
	IF v_count = 0 THEN
		RETURN;
	END IF;
	
	-- insert the top components
	INSERT INTO TT_COMPONENT_TREE
	(top_component_id, container_component_id, child_component_id, position)
	SELECT item, null, item, 0
	  FROM TABLE(v_unrecorded_ids);
	
	-- insert the tree
	INSERT INTO TT_COMPONENT_TREE
	(top_component_id, container_component_id, child_component_id, amount_child_per_parent, amount_unit_id, position)
	SELECT top_component_id, container_component_id, child_component_id, amount_child_per_parent, amount_unit_id, rownum
	  FROM (
			SELECT CONNECT_BY_ROOT parent_component_id top_component_id, parent_component_id container_component_id, component_id child_component_id, amount_child_per_parent, amount_unit_id, position
			  FROM component
			 START WITH parent_component_id IN (SELECT item FROM TABLE(v_unrecorded_ids))
			CONNECT BY NOCYCLE PRIOR component_id = parent_component_id
			 ORDER SIBLINGS BY position
		);
END;



-- this is used to override the capability checks in a few key place as it doesn't really fit in the normal capability structure (or it would be messy)
FUNCTION CanSeeComponentAsChainTrnsprnt (
	in_component_id			IN  component.component_id%TYPE
) RETURN BOOLEAN
AS
BEGIN
	-- currently a company can see any product below it if 
	-- they are somewhere (at any level) in an active supply chain for that product 
	-- the settings mean that the supply chain is transparnet for thier company (this means a top company and with the appropriate customer option at the moment)
	RETURN (IsInDownstreamCmpntSuppChain(in_component_id) AND helper_pkg.IsChainTrnsprntForMyCmpny);
	-- downstream means "up the supply chain" for us - e.g. Staples would be "upstream" of Bobs Paper Mills
END;

/**********************************************************************************
	COMPONENT TYPE CALLS
**********************************************************************************/
PROCEDURE GetTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetType(NULL, out_cur);	
END;

PROCEDURE GetType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT component_type_id, handler_class, handler_pkg, node_js_path, description, editor_card_group_id		
		  FROM v$component_type
		 WHERE app_sid = security_pkg.GetApp
		   AND component_type_id = NVL(in_type_id, component_type_id);
END;

FUNCTION EmptyArray_
RETURN security_pkg.T_SID_IDS
AS
	v_empty_array	security_pkg.T_SID_IDS;
BEGIN
	RETURN v_empty_array;
END;

/**********************************************************************************
	COMPONENT CALLS
**********************************************************************************/
FUNCTION SaveComponent (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	in_component_notes		IN  component.component_notes%TYPE DEFAULT NULL,
	in_tag_sids				IN  security_pkg.T_SID_IDS DEFAULT EmptyArray_,
	in_user_sid				IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_company_sid			IN	component.company_sid%TYPE	DEFAULT NULL
) RETURN component.component_id%TYPE
AS
	v_component_id			component.component_id%TYPE;
	v_user_sid				security_pkg.T_SID_ID DEFAULT NVL(in_user_sid, SYS_CONTEXT('SECURITY', 'SID'));
	v_tag_ids				security.T_SID_TABLE := security_pkg.SidArrayToTable(in_tag_sids);
	v_company_sid			chain.component.company_sid%TYPE	DEFAULT CASE WHEN NVL(in_company_sid, 0) > 0 THEN in_company_sid ELSE SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') END;
BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);
	
	IF v_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		v_user_sid := securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Users/UserCreatorDaemon');
	END IF;
	
	IF NVL(in_component_id, 0) < 1 THEN

		INSERT INTO component
		(component_id,  description, component_code, component_notes, created_by_sid, component_type_id, company_sid)
		VALUES
		(component_id_seq.nextval, in_description, in_component_code, in_component_notes, v_user_sid, in_type_id, v_company_sid)
		RETURNING component_id INTO v_component_id;
		
	ELSE

		IF NOT IsType(in_component_id, in_type_id) THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cannot save component with id '||in_component_id||' because it is not of type '||in_type_id);
		END IF;
		
		v_component_id := in_component_id;
		
		UPDATE component
		   SET description = in_description,
			   component_code = in_component_code,
			   component_notes = in_component_notes
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;

	END IF;
	
	DELETE FROM component_tag
	 WHERE component_id = v_component_id
	   AND tag_id NOT IN (
			SELECT column_value FROM TABLE(v_tag_ids)
		)
	   AND tag_id IN (
			SELECT tgm.tag_id
			  FROM csr.tag_group_member tgm
			  JOIN company_tag_group tg ON tgm.tag_group_id = tg.tag_group_id
			 WHERE tg.applies_to_component = 1
		);

	INSERT INTO component_tag (component_id, tag_id)
	SELECT v_component_id, column_value
	  FROM TABLE(v_tag_ids)
	 WHERE column_value NOT IN (
		SELECT tag_id
		  FROM component_tag
		 WHERE component_id = v_component_id
	);
	
	RETURN v_component_id;
END;


PROCEDURE StoreComponentAmount (
	in_parent_component_id		IN component.component_id%TYPE,
	in_component_id		   		IN component.component_id%TYPE,
	in_amount_child_per_parent	IN component.amount_child_per_parent%TYPE,
	in_amount_unit_id			IN component.amount_unit_id%TYPE
)
AS
BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);

	UPDATE component
	   SET 	amount_child_per_parent = in_amount_child_per_parent,
			amount_unit_id = in_amount_unit_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND component_id = in_component_id
	   AND parent_component_id = in_parent_component_id; 
END;

PROCEDURE DeleteComponent (
	in_component_id		   	IN component.component_id%TYPE
)
AS
BEGIN
	IF IsDeleted(in_component_id) THEN
	   	RETURN;
    END IF;
	
	-- TODO: shouldn't DeleteComponent be checking the delete permission?
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);
		
	UPDATE component 
	   SET deleted = chain_pkg.DELETED
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND component_id = in_component_id; 

	-- call the handler
	EXECUTE IMMEDIATE 'begin '||GetHandlerPkg(GetTypeId(in_component_id))||'.DeleteComponent('||in_component_id||'); end;';
	
	-- detach the component from everything
	DetachComponent(in_component_id);
END;

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_READ);
	
	OPEN out_cur FOR
		SELECT component_id, component_type_id, company_sid, created_by_sid, created_dtm, description, component_code, component_notes
		  FROM component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id
		   AND deleted = chain_pkg.NOT_DELETED;
END;

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	RecordTreeSnapshot(in_top_component_id);
	
	OPEN out_cur FOR
		SELECT c.component_id, c.component_type_id, c.description, c.component_code, c.component_notes, c.deleted, c.company_sid, 
			   c.created_by_sid, c.created_dtm, ct.amount_child_per_parent, ct.amount_unit_id
		  FROM component c, TT_COMPONENT_TREE ct
		 WHERE c.app_sid = security_pkg.GetApp
		   AND c.component_id = ct.child_component_id
		   AND ct.top_component_id = in_top_component_id
		   AND c.component_type_id = in_type_id
		   AND c.deleted = chain_pkg.NOT_DELETED
		 ORDER BY ct.position;
END;

PROCEDURE GetDefaultAmountUnit (
	out_amount_unit_id	OUT amount_unit.amount_unit_id%TYPE,
	out_amount_unit		OUT amount_unit.description%TYPE
)
AS
	-- tried using cursor here but got funny results
	v_amount_unit_id	amount_unit.amount_unit_id%TYPE;
	v_amount_unit		amount_unit.description%TYPE;
BEGIN
	-- Default is just min for now
	SELECT amount_unit_id, description 
	  INTO v_amount_unit_id, v_amount_unit
		 FROM (
		SELECT amount_unit_id, MIN(amount_unit_id) OVER (PARTITION BY app_sid) min_amount_unit_id, description
		  FROM amount_unit
		 WHERE app_sid = security_pkg.GetApp
	) 
	WHERE amount_unit_id = min_amount_unit_id;
	
	out_amount_unit_id := v_amount_unit_id;
	out_amount_unit := v_amount_unit;
END;

-- copied from rfa.product_answers_pkg.GetAllUnits because that was referenced in core chain code
PROCEDURE GetAllUnits (
	out_cur						OUT security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	-- Want "units" at the top and mass / volume grouped together
	OPEN out_cur FOR
		SELECT amount_unit_id id, description, unit_type 
		  FROM chain.amount_unit
		 WHERE unit_type = 'unit'
		UNION ALL
		SELECT amount_unit_id id, description, unit_type 
		  FROM chain.amount_unit
		 WHERE unit_type = 'mass'
		UNION ALL
		SELECT amount_unit_id id, description, unit_type 
		  FROM chain.amount_unit
		 WHERE unit_type = 'volume';
	
END;

PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_container_type_id	IN  chain_pkg.T_COMPONENT_TYPE,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	SearchComponents(in_page, in_page_size, in_container_type_id, in_search_term, NULL, out_count_cur, out_result_cur);
END;

PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_container_type_id	IN  chain_pkg.T_COMPONENT_TYPE,
	in_search_term  		IN  varchar2,
	in_of_type				IN  chain_pkg.T_COMPONENT_TYPE,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	
	IF NOT capability_pkg.CheckCapability(chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to components for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	FillTypeContainment;
	
	-- bulk collect component id's that match our search result
	SELECT component_id
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT c.component_id
		  FROM component c, tt_component_type_containment ctc
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND c.component_type_id = NVL(in_of_type, component_type_id)
		   AND c.component_type_id = ctc.child_component_type_id
		   AND ctc.container_component_type_id = in_container_type_id
		   AND c.deleted = chain_pkg.NOT_DELETED
		   AND (   LOWER(description) LIKE v_search
				OR LOWER(component_code) LIKE v_search)
	  );
	
	OPEN out_count_cur FOR
		SELECT COUNT(*) total_count,
		   CASE WHEN in_page_size = 0 THEN 1 
				ELSE CEIL(COUNT(*) / in_page_size) END total_pages 
		  FROM TABLE(v_results);
			
	-- if page_size is 0, return all results
	IF in_page_size = 0 THEN	
		 OPEN out_result_cur FOR 
			SELECT c.app_sid, c.component_id, c.created_by_sid, c.created_dtm, c.description, c.component_code, c.deleted,
			       c.component_notes, c.component_type_id, c.company_sid, c.parent_component_id, c.parent_component_type_id, c.position,
			       c.amount_child_per_parent, c.amount_unit_id, T.column_value
			  FROM component c, TABLE(v_results) T
			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND c.component_id = T.column_value
			   AND c.deleted = chain_pkg.NOT_DELETED
			 ORDER BY LOWER(c.description), LOWER(c.component_code);
	-- if page_size is specified, return the paged results
	ELSE		
		OPEN out_result_cur FOR 
			SELECT *
			  FROM (
				SELECT A.*, ROWNUM r 
				  FROM (
						SELECT c.app_sid, c.component_id, c.created_by_sid, c.created_dtm, c.description, c.component_code, c.deleted,
						       c.component_notes, c.component_type_id, c.company_sid, c.parent_component_id, c.parent_component_type_id, c.position,
						       c.amount_child_per_parent, c.amount_unit_id
						  FROM component c, TABLE(v_results) T
						 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND c.component_id = T.column_value
						   AND c.deleted = chain_pkg.NOT_DELETED
						 ORDER BY LOWER(c.description), LOWER(c.component_code)
					   ) A 
				 WHERE ROWNUM < (in_page * in_page_size) + 1
			) WHERE r >= ((in_page - 1) * in_page_size) + 1;
	END IF;
END;

-- Note: These are actually components belonging to the company but conceptually they are "stuff they buy"
PROCEDURE SearchComponentsPurchased (
	in_search					IN  VARCHAR2,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_show_unit_mismatch_only	IN  NUMBER,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_component_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_component_ids				T_NUMERIC_TABLE;
	v_purch_mismatch_ids		T_NUMERIC_TABLE;
	v_search					VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_total_count				NUMBER(10);
	v_show_all_components		NUMBER(1, 0) DEFAULT CASE WHEN helper_pkg.ShowAllComponents = 1 OR company_user_pkg.IsCompanyAdmin = 1 OR helper_pkg.IsChainAdmin THEN 1 ELSE 0 END;
	v_collected_component_ids 	security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN

	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;	
		
	
	---------------------------------------------------------------------------------------
	-- COLLECT PRODUCT IDS BASED ON INPUT
	v_purch_mismatch_ids := chain_link_pkg.FindProdWithUnitMismatch;
	
	FOR r IN (
		SELECT pc.component_id, q.questionnaire_id
		  FROM v$purchased_component pc
		  LEFT JOIN questionnaire q ON pc.supplier_product_id = q.component_id
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND 	((in_supplier_company_sid = -1) OR 
				((in_supplier_company_sid = -2) AND ((supplier_company_sid IN (SELECT DISTINCT supplier_company_sid FROM supplier_follower sf WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID'))) OR 
					(uninvited_supplier_sid IN (SELECT DISTINCT uninvited_supplier_sid FROM v$purchased_component WHERE created_by_sid = SYS_CONTEXT('SECURITY', 'SID') AND uninvited_supplier_sid IS NOT NULL)))) OR
				(supplier_company_sid = in_supplier_company_sid) OR 
				(uninvited_supplier_sid = in_supplier_company_sid))
		   AND ((LOWER(pc.description) LIKE v_search) OR (LOWER(pc.component_code) LIKE v_search))
		   AND ((in_show_unit_mismatch_only = 0) OR (pc.component_id IN (SELECT item FROM TABLE(v_purch_mismatch_ids))))
		   AND deleted=chain_pkg.NOT_DELETED
		   AND (q.questionnaire_id IS NOT NULL OR v_show_all_components = 1 OR pc.created_by_sid = security_pkg.GetSid) 
		 ORDER BY LOWER(supplier_name) ASC, pc.description
	)
	LOOP
		--show_all_components controls visibility of components without a questionnaire. For a component with a questionnaire the user needs to have read access
		IF r.questionnaire_id IS NULL OR questionnaire_security_pkg.CheckPermission(r.questionnaire_id, chain_pkg.QUESTIONNAIRE_VIEW) THEN
			v_collected_component_ids.EXTEND;
			v_collected_component_ids(v_collected_component_ids.COUNT) := r.component_id;
		END IF;
	END LOOP; 
	
	-- first we'll add all product that match our search and product flags
	DELETE FROM TT_ID;
	INSERT INTO TT_ID
	(id, position)
	SELECT column_value, rownum 
	  FROM TABLE(v_collected_component_ids); 
	
	---------------------------------------------------------------------------------------
	-- APPLY PAGING
	SELECT COUNT(*)
	  INTO v_total_count
	  FROM TT_ID;

	DELETE FROM TT_ID
	 WHERE position <= NVL(in_start, 0)
	    OR position > NVL2(in_page_size, in_start + in_page_size, v_total_count);
	
	---------------------------------------------------------------------------------------
	-- COLLECT SEARCH RESULTS
	OPEN out_count_cur FOR
		SELECT v_total_count total_count
		  FROM DUAL;
		 
	SELECT T_NUMERIC_ROW(id, position)
	  BULK COLLECT INTO v_component_ids
	  FROM TT_ID;
	
	OPEN out_component_cur FOR
		SELECT cp.component_id, cp.description, 
			   component_code, component_notes, deleted, cp.company_sid, 
			   cp.created_by_sid, cp.created_dtm, component_supplier_type_id, 
			   acceptance_status_id, supplier_company_sid, supplier_name, supplier_country_code, supplier_country_name, 
			   purchaser_company_sid, purchaser_name, uninvited_supplier_sid, 
			   mapped, mapped_by_user_sid, mapped_dtm, uninvited_name, 
			   supplier_product_id, supplier_product_description, supplier_product_code1, supplier_product_code2, supplier_product_code3, 
			   supplier_product_published, supplier_product_published_dtm, cp.purchases_locked, NVL2(mm.item, 1, 0) purchase_unit_mismatch,
			   cp.supplier_root_component_id,
			   CASE 
					WHEN iqtc.component_id IS NOT NULL THEN 
						CASE WHEN q.component_id IS NOT NULL THEN 1 /* Created*/ ELSE 0 /* Not created*/ END
					ELSE -1 /* N/A */
			   END product_questionnaire_status,
			   CASE 
					WHEN q.component_id IS NOT NULL THEN 
						qs.share_status_id /* returns chain_pkg.T_SHARE_STATUS*/
					ELSE
						0 /* Undefined */
				END product_qnr_share_status
		  FROM v$purchased_component cp, TABLE(v_component_ids) i, TABLE(v_purch_mismatch_ids) mm, invitation_qnr_type_component iqtc, questionnaire q, v$questionnaire_share qs
		 WHERE cp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cp.component_id = i.item
		   AND cp.component_id = mm.item(+)
		   AND cp.supplier_product_id = iqtc.component_id(+)
		   AND cp.supplier_product_id = q.component_id(+)
		   AND q.questionnaire_id = qs.questionnaire_id(+)
		 ORDER BY i.pos;
	
END;

-- Made this separate for control over columns - but shouldn't these both be in purchased_component_pkg?
PROCEDURE DownloadComponentsPurchased (
	out_component_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	OPEN out_component_cur FOR
		SELECT pc.component_id as product_id, pc.description, 
			   pc.component_code as product_code, pc.component_notes as notes,
			   pc.created_dtm as created_date, NVL(pc.supplier_company_sid, pc.uninvited_supplier_sid) as supplier_id,
			   NVL(pc.supplier_name, pc.uninvited_name) as supplier_name, pc.supplier_country_code, pc.supplier_country_name, 
			   pc.validation_status_id, pc.validation_status_description
		  FROM v$purchased_component pc
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND pc.deleted = chain_pkg.NOT_DELETED
		   AND pc.component_code IS NOT NULL
		 ORDER BY LOWER(pc.description);
END;


/**********************************************************************************
	COMPONENT HEIRARCHY CALLS
**********************************************************************************/

PROCEDURE AttachComponent (
	in_container_id			IN component.component_id%TYPE,
	in_child_id				IN component.component_id%TYPE	
)
AS
	v_position				component.position%TYPE;
	v_container_type_id		chain_pkg.T_COMPONENT_TYPE;
	v_child_type_id			chain_pkg.T_COMPONENT_TYPE;
BEGIN
	CheckCapability(in_container_id, security_pkg.PERMISSION_WRITE);
	
	IF GetCompanySid(in_container_id) <> GetCompanySid(in_child_id) THEN
		RAISE_APPLICATION_ERROR(-20001, 'You cannot attach components which are owned by different companies');
	END IF;
	
	SELECT NVL(MAX(position), 0) + 1
	  INTO v_position
	  FROM component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND parent_component_id = in_container_id;
	
	SELECT component_type_id
	  INTO v_container_type_id
	  FROM component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_container_id
	   AND deleted = chain_pkg.NOT_DELETED;
	
	SELECT component_type_id
	  INTO v_child_type_id
	  FROM component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_child_id
	   AND deleted = chain_pkg.NOT_DELETED;
	

	UPDATE component
	   SET parent_component_id = in_container_id,
		   parent_component_type_id = v_container_type_id,
		   position = v_position
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_child_id;
END;


PROCEDURE DetachComponent (
	in_component_id			IN component.component_id%TYPE
)
AS
	v_cnt	NUMBER;
BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM component
	 WHERE parent_component_id = in_component_id
	    OR (component_id = in_component_id
			AND parent_component_id IS NOT NULL);
	
	--If there's nothing for us to do, just return.
	IF v_cnt = 0 THEN
		RETURN;
	END IF;
	
	-- fully delete component relationship, no matter whether this component is the parent or the child
	UPDATE component
	   SET parent_component_id = NULL,
		   parent_component_type_id = NULL,
		   position = NULL,
		   amount_child_per_parent = NULL,
		   amount_unit_id = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (component_id = in_component_id OR parent_component_id = in_component_id);
	
	DeleteComponent(in_component_id);--DeleteComponent actually calls DetachComponent back, creating a circular reference. But the chain is broken because both procedures check to see if they have any work to do before actually doing it.
END;

PROCEDURE DetachChildComponents (
	in_container_id			IN component.component_id%TYPE	
)
AS
BEGIN
	CheckCapability(in_container_id, security_pkg.PERMISSION_WRITE);
	
	FOR r IN (
		SELECT component_id
		  FROM component
		 WHERE app_sid = security_pkg.GetApp
		   AND parent_component_id = in_container_id
	) LOOP
		NULL;
		--DeleteComponent(r.component_id);
	END LOOP;
	-- fully delete all child attachments
	UPDATE component
	   SET parent_component_id = NULL,
		   parent_component_type_id = NULL,
		   position = NULL,
		   amount_child_per_parent = NULL,
		   amount_unit_id = NULL
	 WHERE app_sid = security_pkg.GetApp
	   AND parent_component_id = in_container_id;
END;

PROCEDURE DetachComponent (
	in_container_id			IN component.component_id%TYPE,
	in_child_id				IN component.component_id%TYPE	
)
AS
	v_cnt	NUMBER;
BEGIN
	CheckCapability(in_container_id, security_pkg.PERMISSION_WRITE) ;

	SELECT COUNT(*)
	  INTO v_cnt
	  FROM component
	 WHERE parent_component_id = in_container_id
	   AND component_id = in_child_id;
	
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Component'||in_child_id||'is not a child of component'||in_container_id||'.');
	END IF;
	
	-- delete component relationship
	UPDATE component
	   SET parent_component_id = NULL,
		   parent_component_type_id = NULL,
		   position = NULL,
		   amount_child_per_parent = NULL,
		   amount_unit_id = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_child_id
	   AND parent_component_id = in_container_id;
	
	--The child can have only one parent, so delete it if it doesn't belong anywhere anymore.
	DeleteComponent(in_child_id);
END;

PROCEDURE GetComponentTreeHeirarchy (
	in_top_component_id		IN component.component_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	RecordTreeSnapshot(in_top_component_id);
	
	OPEN out_cur FOR
		SELECT child_component_id, container_component_id
		  FROM TT_COMPONENT_TREE
		 WHERE top_component_id = in_top_component_id
		 ORDER BY position;
END;

/**********************************************************************************
	GENERIC COMPONENT DOCUMENT UPLOAD SUPPORT
**********************************************************************************/

PROCEDURE GetComponentUploads(
	in_component_id					IN  component.component_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	-- if the supply chain is transparent for this company and the logged on company is in the supply chain for this product / component 
	IF NOT ((CanSeeComponentAsChainTrnsprnt(in_component_id)) OR (capability_pkg.CheckCapability(GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ))) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid ' || GetCompanySid(in_component_id));
	END IF;

	OPEN out_cur FOR
		SELECT key, cd.file_upload_sid, filename, mime_type, last_modified_dtm, NULL description, lang, download_permission_id,
			   NULL charset, last_modified_dtm creation_dtm, last_modified_dtm last_accessed_dtm, length(data) bytes
		  FROM chain.file_upload fu, chain.component_document cd
		 WHERE fu.app_sid = cd.app_sid
		   AND fu.file_upload_sid = cd.file_upload_sid
		   AND cd.app_sid = security_pkg.GetApp
		   AND cd.component_id = in_component_id;
END;

PROCEDURE AttachFileToComponent(
	in_component_id					IN	component_document.component_id%TYPE,
	in_file_upload_sid				IN	security_pkg.T_SID_ID,
	in_key							IN 	component_document.key%TYPE
)
AS 
BEGIN
	IF NOT capability_pkg.CheckCapability(GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid ' || GetCompanySid(in_component_id));
	END IF;

	INSERT INTO component_document (component_id, file_upload_sid, key)
		VALUES (in_component_id, in_file_upload_sid, in_key);
END;

PROCEDURE DettachFileFromComponent(
	in_component_id					IN	component_document.component_id%TYPE,
	in_file_upload_sid				IN	security_pkg.T_SID_ID
)
AS 
BEGIN
	IF NOT capability_pkg.CheckCapability(GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid ' || GetCompanySid(in_component_id));
	END IF;

	DELETE FROM component_document 
	 WHERE component_id = in_component_id
	   AND file_upload_sid = in_file_upload_sid;

END;

PROCEDURE DoUploaderComponentFiles (
	in_component_id					IN	component_document.component_id%TYPE,
	in_added_cache_keys				IN  chain_pkg.T_STRINGS,
	in_deleted_file_sids			IN  chain_pkg.T_NUMBERS,
	in_key							IN  chain.component_document.key%TYPE, 
	in_download_permission_id		IN  chain.file_upload.download_permission_id%TYPE 
)
AS
	v_file_sid security_pkg.T_SID_ID;
BEGIN
	IF NOT capability_pkg.CheckCapability(GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid ' || GetCompanySid(in_component_id));
	END IF;	

	-- add files
	IF NOT (in_added_cache_keys IS NULL) THEN
		IF NOT (in_added_cache_keys(1) IS NULL) THEN
			FOR i IN in_added_cache_keys.FIRST .. in_added_cache_keys.LAST
			LOOP
				v_file_sid := upload_pkg.SecureFile(in_added_cache_keys(i), in_download_permission_id);
				AttachFileToComponent(in_component_id, v_file_sid, in_key);		
			END LOOP;
		END IF;
	END IF;
	
	-- delete documents not used anymore
	IF NOT (in_deleted_file_sids IS NULL) THEN
		IF NOT (in_deleted_file_sids(1) IS NULL) THEN
			FOR i IN in_deleted_file_sids.FIRST .. in_deleted_file_sids.LAST
			LOOP
				component_pkg.DettachFileFromComponent(in_component_id, in_deleted_file_sids(i));	   
				upload_pkg.DeleteFile(in_deleted_file_sids(i));
			END LOOP;
		END IF;
	END IF;
END;

/**********************************************************************************
	SPECIFIC COMPONENT TYPE CALLS
**********************************************************************************/


PROCEDURE ChangeNotSureType (
	in_component_id			IN  component.component_id%TYPE,
	in_to_type_id			IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS

BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);
	
	IF NOT IsType(in_component_id, chain_pkg.NOTSURE_COMPONENT) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot change component type to '||in_to_type_id||'of component with id '||in_component_id||' because it is not a NOT SURE component');
	END IF;
	
	-- First update parent_component_type_id to NULL so we don't get any constraint error - we'll set it back afterwards
	UPDATE component
	   SET parent_component_type_id = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND parent_component_id = in_component_id;
	
	UPDATE component
	   SET component_type_id = in_to_type_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id;
	
	UPDATE component
	   SET parent_component_type_id = in_to_type_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND parent_component_id = in_component_id;
	
	GetType(in_to_type_id, out_cur); 
END;

PROCEDURE GetTags(
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid			security.security_pkg.T_SID_ID := GetCompanySid(in_component_id);
BEGIN
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to components of company with sid ' || v_company_sid);
	END IF;

	OPEN out_cur FOR		   
		   SELECT t.tag_id, t.tag, tgm.tag_group_id 
			 FROM csr.v$tag t
			 JOIN csr.tag_group_member tgm
			   ON t.tag_id = tgm.tag_id
			  AND t.app_sid = tgm.app_sid
			 JOIN chain.company_tag_group ctg
			   ON ctg.tag_group_id = tgm.tag_group_id
			  AND ctg.app_sid = tgm.app_sid
			WHERE ctg.company_sid = v_company_sid
			  AND ctg.applies_to_component = 1;
END;

PROCEDURE GetActiveTags(
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid			security.security_pkg.T_SID_ID := GetCompanySid(in_component_id);
BEGIN
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to components of company with sid ' || v_company_sid);
	END IF;
			   
	OPEN out_cur FOR		   
		   SELECT t.tag_id, t.tag, tgm.tag_group_id 
			 FROM csr.v$tag t
			 JOIN csr.tag_group_member tgm
			   ON t.tag_id = tgm.tag_id
			  AND t.app_sid = tgm.app_sid
			 JOIN company_tag_group ctg
			   ON ctg.tag_group_id = tgm.tag_group_id
			  AND ctg.app_sid = tgm.app_sid
			 JOIN component_tag ct
			   ON ct.tag_id = t.tag_id
			  AND ct.app_sid = t.app_sid
			WHERE ctg.company_sid = v_company_sid
			  AND ctg.applies_to_component = 1
			  AND ct.component_id = in_component_id;
END;

PROCEDURE SetActiveTags(
	in_component_id			IN  component.component_id%TYPE,
	in_tag_sids				IN  security_pkg.T_SID_IDS	
)
AS
	v_company_sid			security.security_pkg.T_SID_ID := GetCompanySid(in_component_id);
BEGIN
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to components of company with sid ' || v_company_sid);
	END IF;
	
	--delete any tag entries for this component
	DELETE FROM component_tag
	 WHERE component_id = in_component_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	--save new tag entries
		FOR i IN in_tag_sids.FIRST .. in_tag_sids.LAST
			LOOP
				INSERT INTO component_tag (app_sid, component_id, tag_id)
				VALUES(SYS_CONTEXT('SECURITY', 'APP'), in_component_id, in_tag_sids(i));
		END LOOP;
END;

FUNCTION GetComponentDescription ( 
	in_component_id			IN  component.component_id%TYPE	
) RETURN component.description%TYPE	
AS
	v_description 			component.description%TYPE;	
BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_READ);
	
	SELECT description
	  INTO v_description
	  FROM component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id;
	   
	 RETURN v_description;
	 
	   EXCEPTION
		WHEN NO_DATA_FOUND THEN
		 RAISE_APPLICATION_ERROR(-20001, 'Component with id ' || in_component_id || ' not found.');	
END;

END component_pkg;
/

