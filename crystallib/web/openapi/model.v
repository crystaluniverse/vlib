module openapi

import json
import x.json2 { Any }
import freeflowuniverse.crystallib.data.jsonschema {Schema, Reference, SchemaRef}

// todo: report bug: when comps is optional, doesnt work
pub struct OpenAPI {
pub mut:
	openapi             string                 @[required] // This string MUST be the version number of the OpenAPI Specification that the OpenAPI document uses. The openapi field SHOULD be used by tooling to interpret the OpenAPI document. This is not related to the API info.version string.
	info                Info                   @[required]   // Provides metadata about the API. The metadata MAY be used by tooling as required.
	json_schema_dialect string   // The default value for the $schema keyword within Schema Objects contained within this OAS document. This MUST be in the form of a URI.
	servers             []ServerSpec // An array of ServerSpec Objects, which provide connectivity information to a target server. If the servers property is not provided, or is an empty array, the default value would be a ServerSpec Object with a url value of /.
	paths               map[string]PathItem // The available paths and operations for the API.
	webhooks            map[string]PathRef // The incoming webhooks that MAY be received as part of this API and that the API consumer MAY choose to implement. Closely related to the callbacks feature, this section describes requests initiated other than by an API call, for example by an out of band registration. The key name is a unique string to refer to each webhook, while the (optionally referenced) Path Item Object describes a request that may be initiated by the API provider and the expected responses. An example is available.
	components          Components // An element to hold various schemas for the document.
	security            []SecurityRequirement // A declaration of which security mechanisms can be used across the API. The list of values includes alternative security requirement objects that can be used. Only one of the security requirement objects need to be satisfied to authorize a request. Individual operations can override this definition. To make security optional, an empty security requirement ({}) can be included in the array.
	tags                []Tag // A list of tags used by the document with additional metadata. The order of the tags can be used to reflect on their order by the parsing tools. Not all tags that are used by the Operation Object must be declared. The tags that are not declared MAY be organized randomly or based on the tools’ logic. Each tag name in the list MUST be unique.
	external_docs       ExternalDocumentation // Additional external documentation.
}

pub fn (spec OpenAPI) plain() string {
	return '${spec}'.split('\n').filter(!it.contains('Option(none)')).join('\n')
}

// ```
// {
//   "title": "Sample Pet Store App",
//   "summary": "A pet store manager.",
//   "description": "This is a sample server for a pet store.",
//   "termsOfService": "https://example.com/terms/",
//   "contact": {
//     "name": "API Support",
//     "url": "https://www.example.com/support",
//     "email": "support@example.com"
//   },
//   "license": {
//     "name": "Apache 2.0",
//     "url": "https://www.apache.org/licenses/LICENSE-2.0.html"
//   },
//   "version": "1.0.1"
// }
// ```
// The object provides metadata about the API. The metadata MAY be used by the clients if needed, and MAY be presented in editing or documentation generation tools for convenience.
pub struct Info {
pub mut:
	title            string  @[required] // The title of the API
	summary          string  // A short summary of the API.
	description      string  // A description of the API. CommonMark syntax MAY be used for rich text representation.
	terms_of_service string  // A URL to the Terms of Service for the API. This MUST be in the form of a URL.
	contact          Contact // The contact information for the exposed API.
	license          License // The license information for the exposed API.
	version          string  @[required] // The version of the OpenAPI document (which is distinct from the OpenAPI Specification version or the API implementation version).
}

// ```{
//   "name": "API Support",
//   "url": "https://www.example.com/support",
//   "email": "support@example.com"
// }```
// Contact information for the exposed API.
pub struct Contact {
pub:
	name  string // The identifying name of the contact person/organization.
	url   string // The URL pointing to the contact information. This MUST be in the form of a URL.
	email string // The email address of the contact person/organization. This MUST be in the form of an email address.
}

// ```{
//   "name": "Apache 2.0",
//   "identifier": "Apache-2.0"
// }```
// License information for the exposed API.
pub struct License {
pub:
	name       string // The license name used for the API.
	identifier string // An SPDX license expression for the API. The identifier field is mutually exclusive of the url field.
	url        string // A URL to the license used for the API. This MUST be in the form of a URL. The url field is mutually exclusive of the identifier field.
}


// ```{
//   "url": "https://development.gigantic-server.com/v1",
//   "description": "Development server"
// }```
pub struct ServerSpec {
pub:
	url         string                            @[required] // A URL to the target host. This URL supports ServerSpec Variables and MAY be relative, to indicate that the host location is relative to the location where the OpenAPI document is being served. Variable substitutions will be made when a variable is named in {brackets}.
	description string // An optional string describing the host designated by the URL. CommonMark syntax MAY be used for rich text representation.
	variables   map[string]ServerVariable // A map between a variable name and its value. The value is used for substitution in the server’s URL template.
}

// An object representing a ServerSpec Variable for server URL template substitution.
pub struct ServerVariable {
pub:
	enum_       []string @[json: 'enum']              // An enumeration of string values to be used if the substitution options are from a limited set.
	default_    string   @[json: 'default'; required] // The default value to use for substitution, which SHALL be sent if an alternate value is not supplied. Note this behavior is different than the Schema Object’s treatment of default values, because in those cases parameter values are optional.
	description string   @[omitempty]                 // An optional description for the server variable. GitHub Flavored Markdown syntax MAY be used for rich text representation.
}

pub struct Path {}

// pub struct Reference {
// 	ref         string @[json: 'ref'] // The reference identifier. This MUST be in the form of a URI.
// 	summary     string // A short summary which by default SHOULD override that of the referenced component. If the referenced object-type does not allow a summary field, then this field has no effect.
// 	description string // A description which by default SHOULD override that of the referenced component. CommonMark syntax MAY be used for rich text representation. If the referenced object-type does not allow a description field, then this field has no effect.
// }

type PathRef = Path | Reference

pub struct Components {
pub mut:
	schemas          map[string]SchemaRef         //	An object to hold reusable Schema Objects.
	responses        map[string]ResponseRef       //	An object to hold reusable ResponseSpec Objects.
	parameters       map[string]ParameterRef      // An object to hold reusable Parameter Objects.
	examples         map[string]ExampleRef        //	An object to hold reusable Example Objects.
	request_bodies   map[string]RequestBodyRef    // An object to hold reusable Request Body Objects.
	headers          map[string]HeaderRef         //	An object to hold reusable Header Objects.
	security_schemes map[string]SecuritySchemeRef // An object to hold reusable Security Scheme Objects.
	links            map[string]LinkRef     // An object to hold reusable Link Objects.
	callbacks        map[string]CallbackRef //	An object to hold reusable Callback Objects.
	path_items       map[string]PathItemRef // An object to hold reusable Path Item Object.
}


type Items = SchemaRef | []SchemaRef

// type Number = int

// pub struct Request {
// 	description string                  // A brief description of the request body. This could contain examples of use. CommonMark syntax MAY be used for rich text representation.
// 	content     map[string]MediaType     // The content of the request body. The key is a media type (e.g., `application/json`) and the value describes it.
// 	required    bool = false             // Determines if the request body is required in the request. Defaults to false.
// }

pub type ResponseRef = Reference | ResponseSpec
pub type ParameterRef = Parameter | Reference
pub type SecuritySchemeRef = Reference | SecurityScheme
pub type ExampleRef = Example | Reference
pub type RequestBodyRef = Reference | RequestBody
pub type HeaderRef = Header | Reference
pub type LinkRef = Link | Reference
pub type CallbackRef = Callback | Reference
pub type PathItemRef = PathItem | Reference
// type RequestRef = Reference | Request

pub struct PathItem {
pub mut:
	ref         string    @[omitempty]  // Allows for a referenced definition of this path item. The referenced structure MUST be in the form of a Path Item Object. In case a Path Item Object field appears both in the defined object and the referenced object, the behavior is undefined. See the rules for resolving Relative References.
	summary     string    @[omitempty]  // An optional, string summary, intended to apply to all operations in this path.
	description string    @[omitempty]  //	An optional, string description, intended to apply to all operations in this path. CommonMark syntax MAY be used for rich text representation.
	get         Operation @[omitempty]  // A definition of a GET operation on this path.
	put         Operation  @[omitempty] //	A definition of a PUT operation on this path.
	post        Operation @[omitempty]  // A definition of a POST operation on this path.
	delete      Operation @[omitempty]  // A definition of a DELETE operation on this path.
	options     Operation @[omitempty]  //	A definition of a OPTIONS operation on this path.
	head        Operation @[omitempty]  //	A definition of a HEAD operation on this path.
	patch       Operation @[omitempty]  //	A definition of a PATCH operation on this path.
	trace       Operation @[omitempty]  // A definition of a TRACE operation on this path.
	servers     []ServerSpec @[omitempty]   //	An alternative server array to service all operations in this path.
	parameters  []Parameter @[omitempty]//	A list of parameters that are applicable for all the operations described under this path. These parameters can be overridden at the operation level, but cannot be removed there. The list MUST NOT include duplicated parameters. A unique parameter is defined by a combination of a name and location. The list can use the Reference Object to link to parameters that are defined at the OpenAPI Object’s components/parameters.
}

pub struct Operation {
pub mut:
	tags          []string @[omitempty]//	A list of tags for API documentation control. Tags can be used for logical grouping of operations by resources or any other qualifier.
	summary       string   @[omitempty]//	A short summary of what the operation does.
	description   string  @[omitempty] // A verbose explanation of the operation behavior. CommonMark syntax MAY be used for rich text representation.
	external_docs ExternalDocumentation  @[json: 'externalDocs'; omitempty] // Additional external documentation for this operation.
	operation_id  string                 @[json: 'operationId'; omitempty] // Unique string used to identify the operation. The id MUST be unique among all operations described in the API. The operationId value is case-sensitive. Tools and libraries MAY use the operationId to uniquely identify an operation, therefore, it is RECOMMENDED to follow common programming naming conventions.
	parameters    []Parameter @[omitempty]// A list of parameters that are applicable for this operation. If a parameter is already defined at the Path Item, the new definition will override it but can never remove it. The list MUST NOT include duplicated parameters. A unique parameter is defined by a combination of a name and location. The list can use the Reference Object to link to parameters that are defined at the OpenAPI Object’s components/parameters.
	request_body  RequestBodyRef             @[json: 'requestBody'; omitempty] // The request body applicable for this operation. The requestBody is fully supported in HTTP methods where the HTTP 1.1 specification [RFC7231] has explicitly defined semantics for request bodies. In other cases where the HTTP spec is vague (such as GET, HEAD and DELETE), requestBody is permitted but does not have well-defined semantics and SHOULD be avoided if possible.
	responses     map[string]ResponseSpec @[omitempty]   // The list of possible responses as they are returned from executing this operation.
	callbacks     map[string]CallbackRef @[omitempty] // A map of possible out-of band callbacks related to the parent operation. The key is a unique identifier for the Callback Object. Each value in the map is a Callback Object that describes a request that may be initiated by the API provider and the expected responses.
	deprecated    bool @[omitempty]// Declares this operation to be deprecated. Consumers SHOULD refrain from usage of the declared operation. Default value is false.
	security      []SecurityRequirement @[omitempty] //	A declaration of which security mechanisms can be used for this operation. The list of values includes alternative security requirement objects that can be used. Only one of the security requirement objects need to be satisfied to authorize a request. To make security optional, an empty security requirement ({}) can be included in the array. This definition overrides any declared top-level security. To remove a top-level security declaration, an empty array can be used.
	servers       []ServerSpec @[omitempty]// An alternative server array to service this operation. If an alternative server object is specified at the Path Item Object or Root level, it will be overridden by this value.
}

// TODO: currently using map[string]ResponseSpec
pub struct Responses {
pub:
	default ResponseRef
}

pub struct Callback {
pub:
	callback string
}

pub struct Link {
pub:
	link string
}

pub struct Header {
pub:
	header string
}

pub struct ResponseSpec {
pub mut:
	description string                @[required] // A description of the response. CommonMark syntax MAY be used for rich text representation.
	headers     map[string]HeaderRef // Maps a header name to its definition. [RFC7230] states header names are case insensitive. If a response header is defined with the name "Content-Type", it SHALL be ignored.
	content     map[string]MediaType  // A map containing descriptions of potential response payloads. The key is a media type or media type range and the value describes it. For responses that match multiple keys, only the most specific key is applicable. e.g. text/plain overrides text/*
	links       map[string]LinkRef    // A map of operations links that can be followed from the response. The key of the map is a short name for the link, following the naming constraints of the names for Component Objects.
}

// TODO: media type example any field
pub struct MediaType {
pub mut:
	schema   SchemaRef // The schema defining the content of the request, response, or parameter.
	example  string // Example of the media type. The example object SHOULD be in the correct format as specified by the media type. The example field is mutually exclusive of the examples field. Furthermore, if referencing a schema which contains an example, the example value SHALL override the example provided by the schema.
	examples map[string]ExampleRef // Examples of the media type. Each example object SHOULD match the media type and specified schema if present. The examples field is mutually exclusive of the example field. Furthermore, if referencing a schema which contains an example, the examples value SHALL override the example provided by the schema.
	encoding map[string]Encoding   //	A map between a property name and its encoding information. The key, being the property name, MUST exist in the schema as a property. The encoding object SHALL only apply to requestBody objects when the media type is multipart or application/x-www-form-urlencoded.
}

pub struct Encoding {
pub:
	content_type   string               @[json: 'contentType'] //	The Content-Type for encoding a specific property. Default value depends on the property type: for object - application/json; for array – the default is defined based on the inner type; for all other cases the default is application/octet-stream. The value can be a specific media type (e.g. application/json), a wildcard media type (e.g. image/*), or a comma-separated list of the two types.
	headers        map[string]HeaderRef //	A map allowing additional information to be provided as headers, for example Content-Disposition. Content-Type is described separately and SHALL be ignored in this section. This property SHALL be ignored if the request body media type is not a multipart.
	style          string // Describes how a specific property value will be serialized depending on its type. See Parameter Object for details on the style property. The behavior follows the same values as query parameters, including default values. This property SHALL be ignored if the request body media type is not application/x-www-form-urlencoded or multipart/form-data. If a value is explicitly defined, then the value of contentType (implicit or explicit) SHALL be ignored.
	explode        bool   // When this is true, property values of type array or object generate separate parameters for each value of the array, or key-value-pair of the map. For other types of properties this property has no effect. When style is form, the default value is true. For all other styles, the default value is false. This property SHALL be ignored if the request body media type is not application/x-www-form-urlencoded or multipart/form-data. If a value is explicitly defined, then the value of contentType (implicit or explicit) SHALL be ignored.
	allow_reserved bool   //	Determines whether the parameter value SHOULD allow reserved characters, as defined by [RFC3986] :/?#[]@!$&'()*+,;= to be included without percent-encoding. The default value is false. This property SHALL be ignored if the request body media type is not application/x-www-form-urlencoded or multipart/form-data. If a value is explicitly defined, then the value of contentType (implicit or explicit) SHALL be ignored.
}

pub struct Parameter {
pub mut:
	name              string @[required] // The name of the parameter. Parameter names are case sensitive.
	in_               string @[json: 'in'; required] // The location of the parameter. Possible values are "query", "header", "path" or "cookie".
	description       string @[omitempty]// A brief description of the parameter. This could contain examples of use. CommonMark syntax MAY be used for rich text representation.
	required          bool   @[omitempty]// Determines whether this parameter is mandatory. If the parameter location is "path", this property is REQUIRED and its value MUST be true. Otherwise, the property MAY be included and its default value is false.
	deprecated        bool   @[omitempty]// Specifies that a parameter is deprecated and SHOULD be transitioned out of usage. Default value is false.
	allow_empty_value bool   @[json: 'allowEmptyValue'] //	Sets the ability to pass empty-valued parameters. This is valid only for query parameters and allows sending a parameter with an empty value. Default value is false. If style is used, and if behavior is n/a (cannot be serialized), the value of allowEmptyValue SHALL be ignored. Use of this property is NOT RECOMMENDED, as it is likely to be removed in a later revision.
	schema            SchemaRef // The schema defining the type used for the parameter.
}

pub struct Example {
	example string
}

pub struct SecurityScheme {}

pub struct RequestBody {
mut:
	description string                  // A brief description of the request body. This could contain examples of use. CommonMark syntax MAY be used for rich text representation.
	content     map[string]MediaType     // The content of the request body. The key is a media type (e.g., `application/json`) and the value describes it.
	required    bool            // Determines if the request body is required in the request. Defaults to false.
}

pub struct SecurityRequirement {}

pub struct Tag {}

pub struct ExternalDocumentation {
	external string
}
