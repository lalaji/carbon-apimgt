package org.wso2.carbon.apimgt.gateway;

import ballerina.net.http;
import ballerina.lang.messages;
import ballerina.lang.system;
import ballerina.lang.errors;

import org.wso2.carbon.apimgt.gateway.holders as throttle;
import org.wso2.carbon.apimgt.gateway.utils as gatewayUtil;
import org.wso2.carbon.apimgt.gateway.constants as constants;
import org.wso2.carbon.apimgt.gateway.event.publisher;
import org.wso2.carbon.apimgt.gateway.dto;
import org.wso2.carbon.apimgt.ballerina.util;

function isrequestThrottled( message msg) (boolean){
    // will return true if the request is throttled

    //Throttle Keys
    //applicationLevelThrottleKey = {applicationId}:{authorizedUser}
    string applicationLevelThrottleKey;

    //subscriptionLevelThrottleKey = {applicationId}:{apiContext}:{apiVersion}
    string subscriptionLevelThrottleKey;

    // resourceLevelThrottleKey = {apiContext}/{apiVersion}{resourceUri}:{httpMethod}
    // if policy is user level then authorized user will append at end
    string resourceLevelThrottleKey;

    //apiLevelThrottleKey key = {apiContext}:{apiVersion}
    string apiLevelThrottleKey;

    string authorizedUser;

    //Throttle decisions
    boolean isApplicationLevelThrottled = false;
    boolean isSubscriptionLevelThrottled =false;
    boolean isApiLevelThrottled = false;
    boolean apiLevelThrottlingTriggered = false;

    string ipLevelBlockingKey = "";
    string appLevelBlockingKey = "";
    string apiLevelBlockingKey = "";
    string userLevelBlockingKey = "";

    dto:KeyValidationDto keyValidationDto = (dto:KeyValidationDto)util:getProperty(msg, "KEY_VALIDATION_INFO");

    authorizedUser = keyValidationDto.username;
    //Throttle Policies
    string applicationLevelPolicy = keyValidationDto.applicationPolicy;
    string subscriptionLevelPolicy = keyValidationDto.subscriptionPolicy;
    string apiLevelPolicy = keyValidationDto.apiLevelPolicy;

    string apiContext = keyValidationDto.apiContext;
    string apiVersion = keyValidationDto.apiVersion;
    string applicationId = keyValidationDto.applicationId;

    if (authorizedUser == ""){
        http:setStatusCode( msg, constants:HTTP_UNAUTHORIZED);
        messages:setProperty(msg, constants:THROTTLED_ERROR_CODE, constants:BLOCKED_ERROR_CODE);
        messages:setProperty(msg, constants:THROTTLED_OUT_REASON, constants:THROTTLE_OUT_REASON_REQUEST_BLOCKED);
        setThrottledResponse(msg);
        return true;
    }

    //todo get the correct key value
    ipLevelBlockingKey = gatewayUtil:getStringProperty(msg, "CLIENT_IP_ADDRESS");
    apiLevelThrottleKey = apiContext + ":" + apiVersion;
    subscriptionLevelThrottleKey = applicationId + ":" + apiContext + ":" + apiVersion;

    // Blocking Condition
    boolean isBlocked = throttle:isRequestBlocked(apiLevelThrottleKey,subscriptionLevelThrottleKey,authorizedUser,ipLevelBlockingKey);

    if (isBlocked) {
        http:setStatusCode( msg, constants:HTTP_FORBIDDEN);
        messages:setProperty(msg, constants:THROTTLED_ERROR_CODE, constants:BLOCKED_ERROR_CODE);
        messages:setProperty(msg, constants:THROTTLED_OUT_REASON, constants:THROTTLE_OUT_REASON_REQUEST_BLOCKED);
        setThrottledResponse(msg);
        return true;
    }

    string httpMethod = keyValidationDto.verb;
    string resourceLevelPolicy = keyValidationDto.resourceLevelPolicy;
    string resourceUri = keyValidationDto.resourcePath;
    resourceLevelThrottleKey = apiContext + "/" + apiVersion + resourceUri + ":" + httpMethod;

    //Check API Level is Applied
    if (apiLevelPolicy != "" && apiLevelPolicy != constants:UNLIMITED_TIER){
        apiLevelThrottlingTriggered = true;
        resourceLevelThrottleKey = apiLevelThrottleKey ;
    }

    //Check if verb dto is present
    //If verbInfo is present then only we will do resource level throttling
    if( httpMethod == ""){
        system:println("Error while getting throttling information for resource and http verb");
        return false;
    }


    if ( resourceLevelPolicy == constants:UNLIMITED_TIER && !apiLevelThrottlingTriggered) {
        //If unlimited Policy throttling will not apply at resource level and pass it
        system:println("Resource level throttling set as unlimited and request will pass resource level");
    }else{

        // todo check for conditions
        // resource level + API level condition checking
        if (throttle:isThrottled(resourceLevelThrottleKey)) {

            if(apiLevelThrottlingTriggered){
                messages:setProperty(msg, constants:THROTTLED_ERROR_CODE, constants:API_THROTTLE_OUT_ERROR_CODE);
                messages:setProperty(msg, constants:THROTTLED_OUT_REASON, constants:THROTTLE_OUT_REASON_API_LIMIT_EXCEEDED);
            }else{
                messages:setProperty(msg, constants:THROTTLED_ERROR_CODE, constants:RESOURCE_THROTTLE_OUT_ERROR_CODE);
                messages:setProperty(msg, constants:THROTTLED_OUT_REASON, constants:THROTTLE_OUT_REASON_RESOURCE_LIMIT_EXCEEDED);
            }

            http:setStatusCode( msg, constants:HTTP_TOO_MANY_REQUESTS);
            setThrottledResponse(msg);

            return true;
        }
    }

    // Subscription Level throttling
    isSubscriptionLevelThrottled = throttle:isThrottled(subscriptionLevelThrottleKey);
    string stopOnQuotaReach = gatewayUtil:getStringProperty(msg, constants:STOP_ON_QUOTA_REACH);

    if(isSubscriptionLevelThrottled){

        if(stopOnQuotaReach == "true"){
            http:setStatusCode( msg, constants:HTTP_TOO_MANY_REQUESTS );
            messages:setProperty(msg, constants:THROTTLED_ERROR_CODE, constants:SUBSCRIPTION_THROTTLE_OUT_ERROR_CODE);
            messages:setProperty(msg, constants:THROTTLED_OUT_REASON, constants:THROTTLE_OUT_REASON_SUBSCRIPTION_LIMIT_EXCEEDED);
            setThrottledResponse(msg);
            return true;
        }

        system:println("Request throttled at subscription level for throttle key" + subscriptionLevelThrottleKey + ". But subscription policy "
                       + subscriptionLevelPolicy + " allows to continue to serve requests");
    }

    //TODO Spike Arrest

    // Application Level Throttling
    applicationLevelThrottleKey = applicationId + ":" + authorizedUser;
    isApplicationLevelThrottled = throttle:isThrottled(applicationLevelThrottleKey);

    if(isApplicationLevelThrottled){
        http:setStatusCode( msg, constants:HTTP_TOO_MANY_REQUESTS );
        messages:setProperty(msg, constants:THROTTLED_ERROR_CODE, constants:APPLICATION_THROTTLE_OUT_ERROR_CODE);
        messages:setProperty(msg, constants:THROTTLED_OUT_REASON, constants:THROTTLE_OUT_REASON_APPLICATION_LIMIT_EXCEEDED);
        setThrottledResponse(msg);
        return true;
    }

    // Data publishing to Traffic Manger

    try{
        publishEvent(msg, authorizedUser, applicationId, apiContext, apiVersion, apiLevelPolicy, applicationLevelPolicy, subscriptionLevelPolicy,
                     resourceLevelThrottleKey, resourceLevelPolicy, ipLevelBlockingKey);
    }catch(errors:Error e){
        system:println("Error occured while data publsihing " + e.msg);
    }

    return false;
}

function setThrottledResponse(message msg){
    json jsonPayload = {};
    jsonPayload.Error_Code =(string)messages:getProperty(msg, constants:THROTTLED_ERROR_CODE);
    jsonPayload.Error_Message = (string)messages:getProperty(msg, constants:THROTTLED_OUT_REASON);
    messages:setJsonPayload(msg, jsonPayload);
}

function setInvalidUser(message msg){
    messages:setStringPayload(msg, "API is Throttled Out");
}


function publishEvent(message m, string userId, string applicationId, string apiContext, string apiVersion,string apiTier,
                      string applicationTier, string subscriptionTier, string resourceLevelThrottleKey, string resourceTier,string ip) {

    string messageID = "messageID";
    string appKey = applicationId+ ":" + userId;
    string subscriptionKey = applicationId + ":" + apiContext + ":" + apiVersion;
    string apiKey = apiContext + ":" + apiVersion;

    string appTenant = "carbon.super";
    string apiTenant = "carbon.super";
    string apiName = "test";
    string properties = "some_properties";

    dto:ThrottleEventHolderDTO throttleEventHolderDTO = {};
    dto:ThrottleEventDTO throttleEventDTO = {};

    throttleEventHolderDTO.streamName = "PreRequestStream";
    throttleEventHolderDTO.executionPlanName = "requestPreProcessorExecutionPlan";
    throttleEventHolderDTO.timestamp = system:currentTimeMillis();

    throttleEventDTO.messageID = messageID;
    throttleEventDTO.appKey = appKey;
    throttleEventDTO.applicationTier = applicationTier;
    throttleEventDTO.apiKey = apiKey;
    throttleEventDTO.apiTier = apiTier;
    throttleEventDTO.subscriptionKey = subscriptionKey;
    throttleEventDTO.subscriptionTier = subscriptionTier;
    throttleEventDTO.resourceLevelThrottleKey = resourceLevelThrottleKey;
    throttleEventDTO.resourceTier = resourceTier;
    throttleEventDTO.userId = userId;
    throttleEventDTO.apiContext = apiContext;
    throttleEventDTO.apiVersion = apiVersion;
    throttleEventDTO.appTenant = appTenant;
    throttleEventDTO.apiTenant = apiTenant;
    throttleEventDTO.applicationId = applicationId;
    throttleEventDTO.apiName = apiName;
    throttleEventDTO.properties = properties;

    throttleEventHolderDTO.throttleEventDTO = throttleEventDTO;

    publisher:publishThrottleEvent(throttleEventHolderDTO);
}

