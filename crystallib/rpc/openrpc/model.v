module openrpc

import freeflowuniverse.crystallib.data.jsonschema { Reference, SchemaRef }

// This is the root object of the OpenRPC document.
// The contents of this object represent a whole OpenRPC document.
// How this object is constructed or stored is outside the scope of the OpenRPC Specification.
pub struct OpenRPC {
pub mut:
	openrpc       string = '1.0.0' // This string MUST be the semantic version number of the OpenRPC Specification version that the OpenRPC document uses.
	info          Info       // Provides metadata about the API.
	servers       []Server   // An array of Server Objects, which provide connectivity information to a target server.
	methods       []Method   // The available methods for the API.
	components    Components // An element to hold various schemas for the specification.
	external_docs []ExternalDocs @[json: externalDocs] // Additional external documentation.
}

// The object provides metadata about the API.
// The metadata MAY be used by the clients if needed, and MAY be presented in editing or documentation generation tools for convenience.
pub struct Info {
pub:
	title            string // The title of the application.
	description      string // A verbose description of the application.
	terms_of_service string  @[json: termsOfService] // A URL to the Terms of Service for the API. MUST be in the format of a URL.
	contact          Contact @[omitempty]            // The contact information for the exposed API.
	license          License @[omitempty]            // The license information for the exposed API.
	version          string  @[omitempty]            // The version of the OpenRPC document (which is distinct from the OpenRPC Specification version or the API implementation version).
}

// Contact information for the exposed API.
pub struct Contact {
	name  string @[omitempty] // The identifying name of the contact person/organization.
	email string @[omitempty] // The URL pointing to the contact information. MUST be in the format of a URL.
	url   string @[omitempty] // The email address of the contact person/organization. MUST be in the format of an email address.
}

// License information for the exposed API.
pub struct License {
	name string @[omitempty] // The license name used for the API.
	url  string @[omitempty] // A URL to the license used for the API. MUST be in the format of a URL.
}

// An object representing a Server.
// TODO: make variables field optional bug fixed: https://github.com/vlang/v/issues/18000
// TODO: server name is required but not for version 1.0.0
pub struct Server {
pub:
	name        string                    @[omitempty] // A name to be used as the cannonical name for the server.
	url         RuntimeExpression         @[omitempty] // A URL to the target host. This URL supports Server Variables and MAY be relative, to indicate that the host location is relative to the location where the OpenRPC document is being served. Server Variables are passed into the Runtime Expression to produce a server URL.
	summary     string                    @[omitempty] // A short summary of what the server is.
	description string                    @[omitempty] // An optional string describing the host designated by the URL.
	variables   map[string]ServerVariable @[omitempty] // A map between a variable name and its value. The value is passed into the Runtime Expression to produce a server URL.
}

// An object representing a Server Variable for server URL template substitution.
pub struct ServerVariable {
	enum_       []string @[json: 'enum']              // An enumeration of string values to be used if the substitution options are from a limited set.
	default_    string   @[json: 'default'; required] // The default value to use for substitution, which SHALL be sent if an alternate value is not supplied. Note this behavior is different than the Schema Object’s treatment of default values, because in those cases parameter values are optional.
	description string   @[omitempty]                 // An optional description for the server variable. GitHub Flavored Markdown syntax MAY be used for rich text representation.
}

// Describes the interface for the given method name. The method name is used as the method field of the JSON-RPC body. It therefore MUST be unique.
// TODO: make result optional once issue is solved: https://github.com/vlang/v/issues/18001
pub struct Method {
pub mut:
	name            string                 @[omitempty]                       // The cannonical name for the method. The name MUST be unique within the methods array.
	tags            []TagRef               @[omitempty]                       // A list of tags for API documentation control. Tags can be used for logical grouping of methods by resources or any other qualifier.
	summary         string                 @[omitempty]                       // A short summary of what the method does.
	description     string                 @[omitempty]                       // A verbose explanation of the method behavior.
	external_docs   ExternalDocs           @[json: externalDocs; omitempty]   // Additional external documentation for this method.
	params          []ContentDescriptorRef @[omitempty]                       // A list of parameters that are applicable for this method. The list MUST NOT include duplicated parameters and therefore require name to be unique. The list can use the Reference Object to link to parameters that are defined by the Content Descriptor Object. All optional params (content descriptor objects with “required”: false) MUST be positioned after all required params in the list.
	result          ContentDescriptorRef   @[omitempty]                       // The description of the result returned by the method. If defined, it MUST be a Content Descriptor or Reference Object. If undefined, the method MUST only be used as a notification.
	deprecated      bool                   @[omitempty]                       // Declares this method to be deprecated. Consumers SHOULD refrain from usage of the declared method. Default value is false.
	servers         []Server               @[omitempty]                       // An alternative servers array to service this method. If an alternative servers array is specified at the Root level, it will be overridden by this value.
	errors          []ErrorRef             @[omitempty]                       // A list of custom application defined errors that MAY be returned. The Errors MUST have unique error codes.
	links           []LinkRef              @[omitempty]                       // A list of possible links from this method call.
	param_structure ParamStructure         @[json: paramStructure; omitempty] // The expected format of the parameters. As per the JSON-RPC 2.0 specification, the params of a JSON-RPC request object may be an array, object, or either (represented as by-position, by-name, and either respectively). When a method has a paramStructure value of by-name, callers of the method MUST send a JSON-RPC request object whose params field is an object. Further, the key names of the params object MUST be the same as the contentDescriptor.names for the given method. Defaults to "either".
	examples        []ExamplePairing       @[omitempty]                       // Array of Example Pairing Object where each example includes a valid params-to-result Content Descriptor pairing.
}

enum ParamStructure {
	either
	by_name
	by_position
}

pub type ContentDescriptorRef = ContentDescriptor | Reference

// Content Descriptors are objects that do just as they suggest - describe content.
// They are reusable ways of describing either parameters or result.
// They MUST have a schema.
pub struct ContentDescriptor {
pub mut:
	name        string    @[omitempty] // Name of the content that is being described. If the content described is a method parameter assignable by-name, this field SHALL define the parameter’s key (ie name).
	summary     string    @[omitempty] // A short summary of the content that is being described.
	description string    @[omitempty] // A verbose explanation of the content descriptor behavior.
	required    bool      @[omitempty] // Determines if the content is a required field. Default value is false.
	schema      SchemaRef @[omitempty] // Schema that describes the content.
	deprecated  bool      @[omitempty] // Specifies that the content is deprecated and SHOULD be transitioned out of usage. Default value is false.
}

// The Example Pairing object consists of a set of example params and result.
// The result is what you can expect from the JSON-RPC service given the exact params.
pub struct ExamplePairing {
pub mut:
	name        string       @[omitempty] // Name for the example pairing.
	description string       @[omitempty] // A verbose explanation of the example pairing.
	summary     string       @[omitempty] // Short description for the example pairing.
	params      []ExampleRef @[omitempty] // Example parameters.
	result      ExampleRef   @[omitempty] // Example result. When undefined, the example pairing represents usage of the method as a notification.
}

type ExampleRef = Example | Reference

// The Example object is an object that defines an example that is intended to match the schema of a given Content Descriptor.
// Question: how to handle any type for value?
pub struct Example {
	name           string @[omitempty]                      // Cannonical name of the example.
	summary        string @[omitempty]                      // Short description for the example.
	description    string @[omitempty]                      // A verbose explanation of the example.
	value          string @[omitempty]                      // Embedded literal example. The value field and externalValue field are mutually exclusive. To represent examples of media types that cannot naturally represented in JSON, use a string value to contain the example, escaping where necessary.
	external_value string @[json: externalValue; omitempty] // A URL that points to the literal example. This provides the capability to reference examples that cannot easily be included in JSON documents. The value field and externalValue field are mutually exclusive.
}

type LinkRef = Link | Reference

// The Link object represents a possible design-time link for a result. The presence of a link does not guarantee the caller’s ability to successfully invoke it, rather it provides a known relationship and traversal mechanism between results and other methods.
// Unlike dynamic links (i.e. links provided in the result payload), the OpenRPC linking mechanism does not require link information in the runtime result.
// For computing links, and providing instructions to execute them, a runtime expression is used for accessing values in an method and using them as parameters while invoking the linked method.
// TODO: change params map's value type to LinkParam once issue is solved: https://github.com/vlang/v/issues/18002
pub struct Link {
	name        string            // Cannonical name of the link.
	description string            // A description of the link.
	summary     string            // Short description for the link.
	method      string            // The name of an existing, resolvable OpenRPC method, as defined with a unique method. This field MUST resolve to a unique Method Object. As opposed to Open Api, Relative method values ARE NOT permitted.
	params      map[string]string // A map representing parameters to pass to a method as specified with method. The key is the parameter name to be used, whereas the value can be a constant or a runtime expression to be evaluated and passed to the linked method.
	server      Server            // A server object to be used by the target method.
}

// // TODO: handle any, normally should be Any | RuntimeExpression not string
// type LinkParam = string | RuntimeExpression

// Runtime expressions allow the user to define an expression which will evaluate to a string once the desired value(s) are known. They are used when the desired value of a link or server can only be constructed at run time. This mechanism is used by Link Objects and Server Variables.
// The runtime expression makes use of JSON Template Language syntax.
// The table below provides examples of runtime expressions and examples of their use in a value:
// Runtime expressions preserve the type of the referenced value.
type RuntimeExpression = string

type ErrorRef = Error | Reference

// TODO: handle any type for data field
// Defines an application level error.
pub struct Error {
pub:
	code    int    // A Number that indicates the error type that occurred. This MUST be an integer. The error codes from and including -32768 to -32000 are reserved for pre-defined errors. These pre-defined errors SHOULD be assumed to be returned from any JSON-RPC api.
	message string // A String providing a short description of the error. The message SHOULD be limited to a concise single sentence.
	data    SchemaRef // A Primitive or Structured value that contains additional information about the error. This may be omitted. The value of this member is defined by the Server (e.g. detailed error information, nested errors etc.).
}

// TODO: enforce regex requirements
// Holds a set of reusable objects for different aspects of the OpenRPC.
// All objects defined within the components object will have no effect on the API unless they are explicitly referenced from properties outside the components object.
// All the fixed fields declared above are objects that MUST use keys that match the regular expression: ^[a-zA-Z0-9\.\-_]+$
pub struct Components {
pub mut:
	content_descriptors     map[string]ContentDescriptorRef @[json: contentDescriptors] // An object to hold reusable Content Descriptor Objects.
	schemas                 map[string]SchemaRef // An object to hold reusable Schema Objects.
	examples                map[string]Example   // An object to hold reusable Example Objects.
	links                   map[string]Link      // An object to hold reusable Link Objects.
	error                   map[string]Error     // An object to hold reusable Error Objects.
	example_pairing_objects map[string]ExamplePairing @[json: examplePairingObjects] // An object to hold reusable Example Pairing Objects.
	tags                    map[string]Tag // An object to hold reusable Tag Objects.
}

type TagRef = Reference | Tag

// Adds metadata to a single tag that is used by the Method Object.
// It is not mandatory to have a Tag Object per tag defined in the Method Object instances.
pub struct Tag {
	name          string // The name of the tag.
	summary       string // A short summary of the tag.
	description   string // A verbose explanation for the tag.
	external_docs ExternalDocs @[json: externalDocs] // Additional external documentation for this tag.
}

// Allows referencing an external resource for extended documentation.
pub struct ExternalDocs {
	description string // A verbose explanation of the target documentation.
	url         string // The URL for the target documentation. Value MUST be in the format of a URL.
}

pub struct Property {
pub:
	description       string @[omitempty]                         // A description of the property.
	typ               string @[json: 'type'; omitempty]           // The type of the property.
	exclusive_minimum int    @[json: exclusiveMinimum; omitempty] // If the value of the property is a number, this defines the minimum value allowed.
	min_items         int    @[json: minItems; omitempty]         // If the value of the property is an array, this defines the minimum items allowed.
	unique_items      bool   @[json: uniqueItems; omitempty]      // If the value of the property is an array, this determines if the values in the array MUST be unique.
}

// todo: implement specification extensions

// pub struct Property {
// 	description       string
// 	typ               string [json: 'type']
// 	exclusive_minimum int    [json: exclusiveMinimum]
// 	min_items         int    [json: minItems]
// 	unique_items      bool   [json: uniqueItems]
// }

// pub struct Value {
// 	versions []Version
// }

// pub struct Version {
// 	status  string
// 	updated time.Time
// 	id      string
// 	urls    []URL
// }

// pub struct URL {
// 	href string
// 	rel  string
// }
