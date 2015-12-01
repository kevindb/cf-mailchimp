component displayname="MailChimp" output=true {
	variables.apiHost = "https://us1.api.mailchimp.com/3.0/";
	variables.apiKey = "";

	public mailchimp function init (
		required string apiKey,
				 string apiHost = ""
	) {
		if (len(arguments.apiKey) > 0) {
			variables.apiKey = arguments.apiKey;

			if (len(arguments.apiHost) > 0) {
				variables.apiHost = arguments.apiHost;
			} else {
				dc = listLast(variables.apiKey, "-");
				variables.apiHost = replace(variables.apiHost, "us1", dc);
			}
		}

		return this;
	}

	public function getListMembers(
		required string listId
	) {
		return get("lists/" & arguments.listId & "/members");
	}

	public function getListMember(
		required string listId,
		required string email
	) {
		memberId = getMemberIdFromEmail(arguments.email);

		return get("lists/" & arguments.listId & "/members/" & memberId);
	}

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

	public string function getMemberIdFromEmail(
		required string email
	) {
		return lcase(hash(lcase(trim(arguments.email)), "MD5"));
	}

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

	private string function structToQueryString (
		required struct params
	) {
		response = "";

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

	private string function getErrorFromHttp (
		required struct http
	) {
		return {
			"statusCode" = arguments.http.statusCode,
			"errorDetail" = arguments.http.errorDetail
		};
	}
}