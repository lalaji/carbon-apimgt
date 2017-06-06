/*
 *
 *   Copyright (c) 2016, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *   WSO2 Inc. licenses this file to you under the Apache License,
 *   Version 2.0 (the "License"); you may not use this file except
 *   in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 */
package org.wso2.carbon.apimgt.core.impl;

import org.wso2.carbon.apimgt.core.api.APIGateway;
import org.wso2.carbon.apimgt.core.api.APILifecycleManager;
import org.wso2.carbon.apimgt.core.api.GatewaySourceGenerator;
import org.wso2.carbon.apimgt.core.api.IdentityProvider;
import org.wso2.carbon.apimgt.core.dao.APISubscriptionDAO;
import org.wso2.carbon.apimgt.core.dao.ApiDAO;
import org.wso2.carbon.apimgt.core.dao.ApplicationDAO;
import org.wso2.carbon.apimgt.core.dao.LabelDAO;
import org.wso2.carbon.apimgt.core.dao.PolicyDAO;
import org.wso2.carbon.apimgt.core.dao.TagDAO;
import org.wso2.carbon.apimgt.core.dao.WorkflowDAO;

/**
 * This class used to check the permissions for users
 */
class UserAwareAPIPublisher extends APIPublisherImpl {

    public UserAwareAPIPublisher(String username, IdentityProvider idp, ApiDAO apiDAO, ApplicationDAO applicationDAO,
                                 APISubscriptionDAO apiSubscriptionDAO, PolicyDAO policyDAO, APILifecycleManager
                                         apiLifecycleManager, LabelDAO labelDAO,
                                 WorkflowDAO workflowDAO, TagDAO tagDAO, GatewaySourceGenerator gatewaySourceGenerator,
                                 APIGateway apiGatewayPublisher) {
        super(username, idp, apiDAO, applicationDAO, apiSubscriptionDAO, policyDAO, new APILifeCycleManagerImpl(),
                labelDAO, workflowDAO, tagDAO, gatewaySourceGenerator, apiGatewayPublisher);
    }
}
