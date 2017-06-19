### Proposed changes in this pull request

[List all changes you want to add here. If you fixed an issue, please
add a reference to that issue as well.]

-

### When should this PR be merged

[Please describe any preconditions that need to be addressed before we
can merge this pull request.]


### Follow up actions

[List any possible follow-up actions here; for instance, testing data
migrations, software that we need to install on staging and production
environments.]

-


### Checklist (for reviewing)

#### General

- [ ] **Is this PR explained thoroughly?** All code changes must be accounted for in the PR description.
- [ ] **Is the PR labeled correctly?**

#### Functionality

- [ ] **Are all requirements met?** Compare implemented functionality with the requirements specification.
- [ ] **Does the UI work as expected?** There should be no Javascript errors in the console; all resources should load. There should be no unexpected errors. Deliberately try to break the feature to find out if there are corner cases that are not handled.

#### Code

- [ ] **Do you fully understand the introduced changes to the code?** If not ask for clarification, it might uncover ways to solve a problem in a more elegant and efficient way.
- [ ] **Does the PR introduce any inefficient database requests?** Use the debug server to check for duplicate requests.
- [ ] **Are all necessary strings marked for translation?** All strings that are exposed to users via the UI must be [marked for translation](https://docs.djangoproject.com/en/1.10/topics/i18n/translation/).

#### Tests

- [ ] **Are there sufficient test cases?** Ensure that all components are tested individually; models, forms, and serializers should be tested in isolation even if a test for a view covers these components.
- [ ] **If this is a bug fix, are tests for the issue in place?**  There must be a test case for the bug to ensure the issue won’t regress. Make sure that the tests break without the new code to fix the issue.
- [ ] **If this is a new feature or a significant change to an existing feature?** has the manual testing spreadsheet been updated with instructions for manual testing?

#### Security

- [ ] **Confirm this PR doesn't commit any keys, passwords, tokens, usernames, or other secrets.**
- [ ] **Are all UI and API inputs run through forms or serializers?**
- [ ] **Are all external inputs validated and sanitized appropriately?**
- [ ] **Does all branching logic have a default case?**
- [ ] **Does this solution handle outliers and edge cases gracefully?**
- [ ] **Are all external communications secured and restricted to SSL?**

#### Documentation

- [ ] **Are changes to the UI documented in the platform docs?** If this PR introduces new platform site functionality or changes existing ones, the changes should be documented.
- [ ] **Are changes to the API documented in the API docs?** If this PR introduces new API functionality or changes existing ones, the changes must be documented.
- [ ] **Are reusable components documented?** If this PR introduces components that are relevant to other developers (for instance a mixin for a view or a generic form) they should be documented in the Wiki.

#### For REST API Changes [Store,publisher,core]

##### Adhere to proper naming conventions
- [ ] Do the names of **atomic resources**[A data-model exchange as a whole in an API] defined in your API are set as **nouns**?
- [ ] Do the names of **collection resources**[A group of same data type of atomic resource which exchange in an API] defined in your API are set as **nouns**?
- [ ] Do the names of **composite resources**[A group of different entity types manipulated in an API call] defined in your API are set as **nouns**?
- [ ] Do the names of **controller resources**[used when to manipulate multiple resources in a single API call with data consistency] defined in your API are set as **actions**?
- [ ] Do the names of **processing functional resources**[used to provide access to functions which process a resource eg:update a status of a resource] defined in your API are set as **actions**?
- [ ] **Do not** name the controller resources/processing functional resources by means of URI-template
- [ ] Do use **lower case** for **resource naming**
- [ ] Do the **multi word named resources** define by separating with a ** dash ("-")**?
- [ ] **Do not** use **undersocres("_") or camelcase words** for multi word resource naming
- [ ] Do use **singular nouns** for the names of **atomic resources**
- [ ] Do use **plural nouns** for the **collection resources**
- [ ] Use **forward slashes ("/")** to specify hierarchical relations between resources

##### Correctly use the HTTP methods
- [ ] Does your newly added API method uses appropriate HTTP verb to match with below use-cases.<br />
**GET** -used when to retrieve a (subset of) resources of a certain type.A safe and idempotent request method<br />
**POST**-used to create new resources.NOT a safe or idempotent request method<br />
**PUT**-used when to substitutes an existing complete resource.NOT a safe request method,but an idempotent request method<br />
**PATCH**-used when to update an existing resource partially.NOT a safe request method or idempotent request method<br />
**DELETE**- used when to delete an existing resource.Once a DELETE request returned successfully with a "200 OK" response, following DELETE requests on the same URI will result in a "404 Not Found" response because there is no resource available with the URI of the deleted resource.NOT a safe or idempotent request method.

##### Use pagination support for resource retrieval<br />
- [ ] If you have defined a GET method to retrieve collection of data,do you have defined the "offset" field[the position number of a resource where the retrieval should start] and "limit" field [maximum number of resources to retrieve] in request query string to support pagination?

##### Use ETags support for handling client side caching[for GET requests] & concurrency control[for PUT/DELETE requests]<br />
- [ ] **For GET requests**,have you considered to include request headers If-None-Match[value of the ETag header of the resource as retrieved last time]?<br />
- [ ] **For GET requests**,have you considered to compare the incoming header If-None-Match with server side stored value and if no change in the value,return the response code as "304 Not Modified" without returning the resource?<br />
- [ ] **For PUT/DELETE requests**,have you considered to include request header If-Match[value of the ETag header of the resource as retrieved last time ]?<br />
- [ ] **For PUT/DELETE requests**,have you considered to compare the request header If-Match with server side stored value and if the value has changed,response with the code "412 Precondition Failed"?<br />
- [ ] **Do not** handle etags scenario for GET requests which retrieve collection resources.[As yet APIM don't support it.]<br />

##### Use proper response status codes
- [ ] Do you have verify the response status codes defined for your new API method by referring below use-cases.<br />
- **200 OK** -The request has been performed successfully. If the request was a GET, the requested resource is returned in the message body. If the request was a POST,the result of the requested action is described by the message body, or it is contained in the message body.<br />
-**201 Created** -The request has been performed successfully. The URL of the newly created entity is contained in the Location header of the response.An ETag header should be returned with the current entity tag of the resource just created.<br />
-**202 Accepted** -The processing of the request has started but will take some time. The success of the processing is not guaranteed and should be checked by the client.The body of the response message should provide information about the current state of the processing, as well as information about where the client can request updated status information at a later point in time;typically, the Content-Location header of the response contains a URL where this status information can be retrieved via GET.<br />
-**303 See Other**-The response of the request is availablle as value of the Location header of the response message.<br />
  Typically, this status code is returned after the processing of a long running request is completed and the client retrieves the status of the long running request.<br />
**304 Not Modified**-The requesting client has already received the latest version of the requested resource, thus, the body of the response message must be empty.<br />
**400 Bad Request**-The request is invalid.[eg: syntax errors in expressions passed with the request are found, values are out of range, required data is missing etc].<br />
**401 Unauhtorized**-The request requires client authorization or the passed credentials are not accepted.<br />
**403 Forbidden**-The server understood the request but refused to perform it. For example, the request must be conditional but no condition has been specified.<br />
**404 Not Found**-The requested resource doesn't exist.<br />
**406 Not Acceptable**-The requested media type is not supported.<br />
**412 Precondition Failed**-The request has not been performed because one of the preconditions is not met.<br />
**415 Unsupported Media Type**-The entity of the request was in a not supported format.<br />
**5xx status codes**- denote severe errors at the server side or the network, or denote not implemented functions, etc.There is no need to document them explicitly for an API.

