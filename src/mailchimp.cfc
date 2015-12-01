component displayname="MailChimp" output=true {
	variables.apiHost = "https://us1.api.mailchimp.com/3.0/";
	variables.apiKey = "";

	public mailchimp function init (
		required string apiKey,
				 string apiHost = ""
	) {
		if (len(arguments.apiKey) > 0) {
			variables.apiKey = arguments.apiKey;

			// Allow apiHost to be set manually
			if (len(arguments.apiHost) > 0) {
				variables.apiHost = arguments.apiHost;

			// Get datacenter from API key
			} else {
				dc = listLast(variables.apiKey, "-");
				variables.apiHost = replace(variables.apiHost, "us1", dc);
			}
		}

		return this;
	}

	// MailChimp List calls
	// http://developer.mailchimp.com/documentation/mailchimp/reference/lists/
	public function getLists() {
		return get("lists");
	}

	public function getList(
		required string listId
	) {
		return get("lists/" & arguments.listId);
	}


	// MailChimp Member calls
	// http://developer.mailchimp.com/documentation/mailchimp/reference/lists/members/

	// Retrieves a list of all members of the specified list
	public function getListMembers(
		required string listId
	) {
		return get("lists/" & arguments.listId & "/members");
	}

	// Retrieves details on a single member of the specified list
	public function getListMember(
		required string listId,
		required string email
	) {
		memberId = getMemberIdFromEmail(arguments.email);

		return get("lists/" & arguments.listId & "/members/" & memberId);
	}

	// Uses a batch operation to add or update multiple members of the specified list
	public function putListMembers(
		required string listId,
		required array members
	) {
		response = {};
		operations = [];

		try {
			for (data in arguments.members) {
				memberId = getMemberIdFromEmail(data.email_address);

				operations.append({
					method = "PUT",
					path = "/lists/" & arguments.listId & "/members/" & memberId,
					body = serializeJson(data)
				});
			}

			response = batch(operations);

		} catch(any error) {
			writeDump(error);
		}

		return response;
	}

	// Adds or updates a single member to the specified list
	public function putListMember(
		required string listId,
		required struct data
	) {
		response = {};

		try {
			memberId = getMemberIdFromEmail(arguments.data.email_address);
			response = put("lists/" & arguments.listId & "/members/" & memberId, arguments.data);

		} catch(any error) {
			writeDump(error);
		}

		return response;
	}

	// Generates the member ID, the MD5 hash of the email address
	// http://developer.mailchimp.com/documentation/mailchimp/guides/manage-subscribers-with-the-mailchimp-api/
	public string function getMemberIdFromEmail(
		required string email
	) {
		return lcase(hash(lcase(trim(arguments.email)), "MD5"));
	}

	// Performs a generic HTTP GET operation
	private struct function get (
		required string endpoint,
				 struct params = {}
	) {
		local.url = variables.apiHost & arguments.endpoint & structToQueryString(arguments.params);

		writeOutput("HTTP GET: " & local.url & "<br>");

		httpService = new http(url=local.url, method="get", password=variables.apiKey, username="");
		httpContent = httpService.send().getPrefix().fileContent;
		responseJson = deserializeJSON(httpContent);

		return responseJson;
	}

	// Performs a generic HTTP PUT operation
	private function put (
		required string endpoint,
				 struct data,
				 struct params = {}
	) {
		local.url = variables.apiHost & arguments.endpoint & structToQueryString(arguments.params);

		writeOutput("HTTP PUT: " & local.url & "<br>");
		writeDump(serializeJson(arguments.data));

		httpService = new http(url=local.url, method="put", password=variables.apiKey, username="");

		httpService.addParam(type="body", value=serializeJson(arguments.data));

		httpService = httpService.send();

		writeDump(httpService);

		httpContent = httpService.getPrefix().fileContent;

		responseJson = deserializeJSON(httpContent);

		return responseJson;
	}

	// Performs a MailChimp's HTTP POST batch operation
	private function batch (
		required array operations
	) {
		local.url = variables.apiHost & "batches";
		data = { operations = arguments.operations };

		writeOutput("HTTP POST: " & local.url & "<br>");
		writeDump(serializeJson(data));

		httpService = new http(url=local.url, method="post", password=variables.apiKey, username="");

		httpService.addParam(type="body", value=serializeJson(data));

		httpService = httpService.send();

		writeDump(httpService);

		httpContent = httpService.getPrefix().fileContent;

		responseJson = deserializeJSON(httpContent);

		return responseJson;
	}

	// Converts a struct into a URL query string
	private string function structToQueryString (
		required struct params
	) {
		response = "";

		// Adds default exclude_fields=_links. This drastically reduces the response size from MailChimp
		if (!(structKeyExists(arguments.params, "exclude_fields") || structKeyExists(arguments.params, "fields"))) {
			arguments.params.exclude_fields = "_links";
		}

		for (key in arguments.params) {
			response = listAppend(response, key & "=" & urlEncodedFormat(arguments.params[key]), "&");
		}

		if (len(response) > 0) {
			response = "?" & response;
		}

		return response;
	}

	// In the event of an HTTP error status, parses the detail out of the CF HTTP object
	private string function getErrorFromHttp (
		required struct http
	) {
		return {
			"statusCode" = arguments.http.statusCode,
			"errorDetail" = arguments.http.errorDetail
		};
	}
}