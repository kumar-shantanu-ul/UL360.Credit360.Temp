CREATE OR REPLACE PACKAGE CHAIN.component_pkg
IS

/**********************************************************************************
	GLOBAL MANAGEMENT
	
	These methods act on data across all applications
**********************************************************************************/

/**
 * Create or update a component type
 *
 * @param in_type_id			The type of component to create
 * @param in_handler_class		The C# class that handles data management of this type
 * @param in_handler_pkg		The package that provides GetComponent(id) and GetComponents(top_id, type) functions
 * @param in_node_js_path		The path of the JS Component Node handler class
 * @param in_description		The translatable description of this type
 *
 * NOTE: Component types registered using this method cannot be editted in the UI. See next overload for more info.
 */
PROCEDURE CreateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_handler_class		IN  all_component_type.handler_class%TYPE,
	in_handler_pkg			IN  all_component_type.handler_pkg%TYPE,
	in_node_js_path			IN  all_component_type.node_js_path%TYPE,
	in_description			IN  all_component_type.description%TYPE
);

/**
 * Create or update a component type
 *
 * @param in_type_id			The type of component to create
 * @param in_handler_class		The C# class that handles data management of this type
 * @param in_handler_pkg		The package that provides GetComponent(id) and GetComponents(top_id, type) functions
 * @param in_node_js_path		The path of the JS Component Node handler class
 * @param in_description		The translatable description of this type
 * @param in_editor_card_group_id	The card group that handles editting of this type
 */
PROCEDURE CreateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_handler_class		IN  all_component_type.handler_class%TYPE,
	in_handler_pkg			IN  all_component_type.handler_pkg%TYPE,
	in_node_js_path			IN  all_component_type.node_js_path%TYPE,
	in_description			IN  all_component_type.description%TYPE,
	in_editor_card_group_id	IN  all_component_type.editor_card_group_id%TYPE
);

/**********************************************************************************
	APP MANAGEMENT
**********************************************************************************/
/**
 * Activates this type for the session application
 *
 * @param in_type_id			The type of component to activate
 */
PROCEDURE ActivateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE
);

/**********************************************************************************/
/* Component sources are application level UI configurations that allow us to set */
/* specific text and help data in a ComponentSource card. 						  */
/*                                                       . 						  */

/**
 * Clears component source data
 */
PROCEDURE ClearSources;

/**
 * Adds component source data
 *
 * @param in_type_id			The type of component to activate
 * @param in_action				The card action to invoke when this option is selected
 * @param in_text				A short text block that describes the intent of the source 
 * @param in_description		A longer xml helper description explaining in what circumstances we'd choose this option
 *
 * NOTE: Component source data added using this method will be used for all card groups.
 * NOTE: This method will ensure that ActivateType is called for the type.
 */
PROCEDURE AddSource (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE
);

/**
 * Adds component source data
 *
 * @param in_type_id			The type of component to activate
 * @param in_action				The card action to invoke when this option is selected
 * @param in_text				A short text block that describes the intent of the source 
 * @param in_description		A longer xml helper description explaining in what circumstances we'd choose this option
 * @param in_card_group_id		The card group to include this source data for
 *
 * NOTE: This method will ensure that ActivateType is called for the type.
 */
PROCEDURE AddSource (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE,
	in_card_group_id		IN  component_source.card_group_id%TYPE
);

/**
 * Gets component sources for a specific card manager
 *
 * @param in_card_group_id			The id of the card group to collect that sources for
 * @returns							The source data cursor
 */
PROCEDURE GetSources (
	in_card_group_id		IN  component_source.card_group_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**********************************************************************************/
/* Component type containment acts as both a UI helper and database ri for which  */
/* types of components can house other types.									  */
/* This is set at application level.				 . 						      */
/*                                                       . 						  */

/**
 * Clears component type containment for this application
 */
PROCEDURE ClearTypeContainment;

/**
 * Sets component type containment with UI helper flags for a single container/child pair
 *
 * @param in_container_type_id		The container component type
 * @param in_child_type_id			The child component type
 * @param in_allow_flags			See chain_pkg for valid allow flags
 *
 * NOTE: This method will ensure that ActivateType is called for both 
 *		 the container and child types.
 */
PROCEDURE SetTypeContainment (
	in_container_type_id	IN chain_pkg.T_COMPONENT_TYPE,
	in_child_type_id		IN chain_pkg.T_COMPONENT_TYPE,
	in_allow_flags			IN chain_pkg.T_FLAG
);

/**
 * Gets type containment data for output to the ui
 *
 * @returns							The containment data cursor
 */
PROCEDURE GetTypeContainment (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateComponentAmountUnit (
	in_amount_unit_id		IN amount_unit.amount_unit_id%TYPE,
	in_description			IN amount_unit.description%TYPE,
	in_unit_type			IN amount_unit.unit_type%TYPE, 	
	in_conversion			IN amount_unit.conversion_to_base%TYPE
);

/**********************************************************************************
	UTILITY
**********************************************************************************/
/**
 * Checks if a component is of a specific type
 *
 * @param in_component_id			The id of the component to check
 * @param in_type_id				The presumed type
 * @returns							TRUE if the type matches, FALSE if not
 */
FUNCTION IsType (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE
) RETURN BOOLEAN;

/**
 * Gets the owner company sid for given component id
 *
 * @param in_component_id			The id of the component
 * @returns							The company sid that owns the component
 */
FUNCTION GetCompanySid (
	in_component_id			IN component.component_id%TYPE
) RETURN security_pkg.T_SID_ID;

/**
 * Checks to see if a component is deleted
 *
 * @param in_component_id			The id of the component to check
 */
FUNCTION IsDeleted (
	in_component_id			IN component.component_id%TYPE
) RETURN BOOLEAN;

/**
 * Records the component tree data into TT_COMPONENT_TREE
 *
 * @param in_top_component_id		The top id of the component in the tree
 */
PROCEDURE RecordTreeSnapshot (
	in_top_component_id		IN  component.component_id%TYPE
);

/**
 * Records the component tree data into TT_COMPONENT_TREE
 *
 * @param in_top_component_ids		The top ids of the components in the trees
 */
PROCEDURE RecordTreeSnapshot (
	in_top_component_ids	IN  T_NUMERIC_TABLE
);

-- this is used to override the capability checks in a few key place as it doesn't really fit in the normal capability structure (or it would be messy)
FUNCTION CanSeeComponentAsChainTrnsprnt (
	in_component_id			IN  component.component_id%TYPE
) RETURN BOOLEAN;

/**********************************************************************************
	COMPONENT TYPE CALLS
**********************************************************************************/
/**
 * Gets the components types that are active in this application
 *
 * @returns							A cursor of (as above)
 */
PROCEDURE GetTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Gets the specific component type requested
 *
 * @param in_type_id				The specific component type to get
 * @returns							A cursor of (as above)
 */
PROCEDURE GetType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION EmptyArray_
RETURN security_pkg.T_SID_IDS;

/**********************************************************************************
	COMPONENT CALLS
**********************************************************************************/
/**
 * Saves a component. If in_component_id <= 0, a new component is created.
 * If in_component_id > 0, the component is updated, provided that the type
 * passed in matches the expected type.
 *
 * @param in_component_id			The id (actual for existing, < 0 for new)
 * @param in_type_id				The type 
 * @param in_description			The description
 * @param in_component_code			The component code
 * @param in_component_notes		A field with notes about the component
 * @param in_tag_sids				An array of tag sids associated with this component
 * @param in_user_sid				The user creating the component
 * @param in_company_sid			
 * @returns							The actual id of the component
 */
FUNCTION SaveComponent (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	in_component_notes		IN  component.component_notes%TYPE DEFAULT NULL,
	in_tag_sids				IN  security_pkg.T_SID_IDS DEFAULT EmptyArray_,
	in_user_sid				IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_company_sid			IN	component.company_sid%TYPE	DEFAULT NULL
) RETURN component.component_id%TYPE;

/**
 * Saves an amount and unit againt a component child / containser relationship. 
 *
 * @param in_parent_component_id		The id of the parent component
 * @param in_component_id				The id of the component
 * @param in_amount_child_per_parent	How much of the child is there in the parent (mass, %, etc...) 
 * @param in_amount_unit_id				The unit describing the amount
 */
PROCEDURE StoreComponentAmount (
	in_parent_component_id		IN component.component_id%TYPE,
	in_component_id		   		IN component.component_id%TYPE,
	in_amount_child_per_parent	IN component.amount_child_per_parent%TYPE,
	in_amount_unit_id			IN component.amount_unit_id%TYPE
);

/**
 * Marks a component as deleted
 *
 * @param in_component_id			The id of the component to delete
 */
PROCEDURE DeleteComponent (
	in_component_id			IN component.component_id%TYPE
);

/**
 * Gets basic component data by component id
 *
 * @param in_component_id			The id of the component to get
 * @returns							A cursor containing the basic component data
 */
PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

/**
 * Gets child component data of a specific type for a top_component
 *
 * @param in_top_component_id		The top component of the tree to get
 * @param in_type_id				The type of component that we're looking for
 * @returns							A cursor containing the component data
 *
 * NOTE: The type is passed in because we allow a single method to collect data
 * for more than one type of component. You must ensure that you only return
 * components of the requested type, as this method may be called again
 * using an alternate type
 */
PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Gets default (min at the moment) component amount unit for an app
 *
 * @param in_type_id				(not used atm) The type of component 
 * @returns							A cursor containing the component data
 */
PROCEDURE GetDefaultAmountUnit (
	out_amount_unit_id	OUT amount_unit.amount_unit_id%TYPE,
	out_amount_unit		OUT amount_unit.description%TYPE
);

-- copied from rfa.product_answers_pkg.GetAllUnits because that was referenced in core chain code
PROCEDURE GetAllUnits (
	out_cur						OUT security_pkg.T_OUTPUT_CUR	
);

/**
 * Searchs all components that are valid for the specified container type
 *
 * @param in_page					The page number to get
 * @param in_page_size				The size of a page
 * @param in_container_type_id		The type of container that we're searching for
 * @param in_search_term			The search term
 * @returns out_count_cur			The search statistics
 * @returns out_result_cur			The page limited search results
 */
PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_container_type_id	IN  chain_pkg.T_COMPONENT_TYPE,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

/**
 * Searchs all components of a specific type that are valid for the specified container type
 *
 * @param in_page					The page number to get
 * @param in_page_size				The size of a page
 * @param in_container_type_id		The type of container that we're searching for
 * @param in_search_term			The search term
 * @param in_of_type				The specific type to search for
 * @returns out_count_cur			The search statistics
 * @returns out_result_cur			The page limited search results
 */
PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_container_type_id	IN  chain_pkg.T_COMPONENT_TYPE,
	in_search_term  		IN  varchar2,
	in_of_type				IN  chain_pkg.T_COMPONENT_TYPE,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SearchComponentsPurchased (
	in_search					IN  VARCHAR2,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_show_unit_mismatch_only	IN  NUMBER,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_component_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DownloadComponentsPurchased (
	out_component_cur			OUT security_pkg.T_OUTPUT_CUR
);

/**********************************************************************************
	COMPONENT HEIRARCHY CALLS
**********************************************************************************/

/**
 * Attaches one component to another component
 *
 * @param in_container_id			The container component id
 * @param in_child_id				The child component id
 */
PROCEDURE AttachComponent (
	in_container_id			IN component.component_id%TYPE,
	in_child_id				IN component.component_id%TYPE	
);

/**
 * Fully detaches a component from all container and child components
 *
 * @param in_component_id		The component id to detach
 */
PROCEDURE DetachComponent (
	in_component_id				IN component.component_id%TYPE	
);

/**
 * Detaches all child components from this component
 *
 * @param in_container_id			The component id to detach children from
 */
PROCEDURE DetachChildComponents (
	in_container_id			IN component.component_id%TYPE	
);

/**
 * Detaches a specific container / child component pair
 *
 * @param in_container_id			The container component id
 * @param in_child_id				The child component id
 */
PROCEDURE DetachComponent (
	in_container_id			IN component.component_id%TYPE,
	in_child_id				IN component.component_id%TYPE	
);

/**
 * Gets a table of all component ids that are children of the top component id
 *
 * @param in_top_component_id		The top component in the branch
 * @returns A numeric table of component ids in this branch
 *
FUNCTION GetComponentTreeIds (
	in_top_component_id		IN component.component_id%TYPE
) RETURN T_NUMERIC_TABLE;

/**
 * Gets a table of all component ids that are children of the top component ids
 *
 * @param in_top_component_ids		An array of all top component ids to include
 * @returns A numeric table of component ids in this branch
 *
FUNCTION GetComponentTreeIds (
	in_top_component_ids	IN T_NUMERIC_TABLE
) RETURN T_NUMERIC_TABLE;


/**
 * Gets a heirarchy cursor of all parent id / component id relationships 
 * starting with the top component id
 *
 * @param in_top_component_id		The top component in the branch
 * @returns out_cur					The cursor (as above)
 */
PROCEDURE GetComponentTreeHeirarchy (
	in_top_component_id		IN component.component_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);
/**********************************************************************************
	GENERIC COMPONENT DOCUMENT UPLOAD SUPPORT
**********************************************************************************/

PROCEDURE GetComponentUploads(
	in_component_id					IN  component.component_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AttachFileToComponent(
	in_component_id					IN	component_document.component_id%TYPE,
	in_file_upload_sid				IN	security_pkg.T_SID_ID,
	in_key							IN 	component_document.key%TYPE
);

PROCEDURE DettachFileFromComponent(
	in_component_id					IN	component_document.component_id%TYPE,
	in_file_upload_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE DoUploaderComponentFiles (
	in_component_id					IN	component_document.component_id%TYPE,
	in_added_cache_keys				IN  chain_pkg.T_STRINGS,
	in_deleted_file_sids			IN  chain_pkg.T_NUMBERS,
	in_key							IN  chain.component_document.key%TYPE, 
	in_download_permission_id		IN  chain.file_upload.download_permission_id%TYPE 
);

/**********************************************************************************
	SPECIFIC COMPONENT TYPE CALLS
**********************************************************************************/

/**
 * Changes a not sure component type into another component type
 *
 * @param in_component_id			The id of the not sure component to change
 * @param in_to_type_id				The type to change the component to
 * @returns out_cur					A cursor the basic component data
 */
PROCEDURE ChangeNotSureType (
	in_component_id			IN  component.component_id%TYPE,
	in_to_type_id			IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTags(
	in_component_id			IN  component.component_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetActiveTags(
	in_component_id			IN  component.component_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetActiveTags(
	in_component_id			IN  component.component_id%TYPE,
	in_tag_sids					IN  security_pkg.T_SID_IDS	
);


FUNCTION GetComponentDescription ( 
	in_component_id			IN  component.component_id%TYPE	
) RETURN component.description%TYPE;	

END component_pkg;
/
