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
				local.dc = listLast(variables.apiKey, "-");
				variables.apiHost = replace(variables.apiHost, "us1", local.dc);
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

		local.httpService = new http(url=local.url, method="get", password=variables.apiKey, username="");
		local.httpContent = httpService.send().getPrefix().fileContent;
		local.responseJson = deserializeJSON(local.httpContent);

		return local.responseJson;
	}

	private function put (
		required string endpoint,
				 struct data,
				 struct params = {}
	) {
		local.url = variables.apiHost & arguments.endpoint & structToQueryString(arguments.params);

		writeOutput("HTTP PUT: " & local.url & "<br>");
		writeDump(serializeJson(arguments.data));

		local.httpService = new http(url=local.url, method="put", password=variables.apiKey, username="");

		local.httpService.addParam(type="body", value=serializeJson(arguments.data));

		local.httpService = local.httpService.send();

		writeDump(local.httpService);

		local.httpContent = httpService.getPrefix().fileContent;

		local.responseJson = deserializeJSON(local.httpContent);

		return local.responseJson;
	}

	private string function structToQueryString (
		required struct params
	) {
		response = "";

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