/*
 * **************************************************
 *  Copyright (C) 2019 Ping Identity Corporation
 *  All rights reserved.
 *
 *  The contents of this file are subject to the terms of the
 *  Ping Identity Corporation SDK Developer Guide.
 *
 *  Ping Identity Corporation
 *  1001 17th St Suite 100
 *  Denver, CO 80202
 *  303.468.2900
 *  http://www.pingidentity.com
 * ****************************************************
 */

package com.pingidentity.adapter.idp;

import com.pingidentity.sdk.AuthnAdapterResponse;
import com.pingidentity.sdk.AuthnAdapterResponse.AUTHN_STATUS;
import com.pingidentity.sdk.IdpAuthenticationAdapterV2;
import com.pingidentity.sdk.locale.LanguagePackMessages;
import com.pingidentity.sdk.locale.LocaleUtil;
import com.pingidentity.sdk.oauth20.Scope;
import com.pingidentity.sdk.template.TemplateRendererUtil;
import com.pingidentity.sdk.template.TemplateRendererUtilException;
import org.sourceid.common.IDGenerator;
import org.sourceid.oauth20.protocol.Parameters;
import org.sourceid.saml20.adapter.AuthnAdapterException;
import org.sourceid.saml20.adapter.attribute.AttributeValue;
import org.sourceid.saml20.adapter.conf.Configuration;
import org.sourceid.saml20.adapter.gui.AdapterConfigurationGuiDescriptor;
import org.sourceid.saml20.adapter.idp.authn.AuthnPolicy;
import org.sourceid.saml20.adapter.idp.authn.IdpAuthenticationAdapter;
import org.sourceid.saml20.adapter.idp.authn.IdpAuthnAdapterDescriptor;
import org.sourceid.saml20.adapter.state.SessionStateSupport;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import static org.sourceid.oauth20.model.UserKeyAttributes.USER_KEY_ATTR_NAME;
import static org.sourceid.oauth20.model.UserKeyAttributes.USER_NAME_ATTR_NAME;

/**
 *
 * This class is an example of an IdP adapter that demonstrates the use of an external consent page scenario to approve user scopes
 *
 * This system can return any approved scopes in form of space separated string, array of string, a collection of strings and an AttributeValue
 *
 * It is also possible to return different scopes than what was originally requested. In that case, those approved scopes (which may not even exist in PingFederate)
 * will be added to Access Token and saved in the persistent grant.
 *
 */
public class ExternalConsentPageAdapter implements IdpAuthenticationAdapterV2
{

    private static final String SCOPES = "scopes";
    private static final String CSRF_TOKEN_NAME = "cSRFToken";

    private IdpAuthnAdapterDescriptor descriptor;
    private final SessionStateSupport state = new SessionStateSupport();

    private static Map<String, Object> idpAdapterInfo;

    static
    {
        idpAdapterInfo = new HashMap<>();
        idpAdapterInfo.put(ADAPTER_INFO_EXTERNAL_CONSENT_ADAPTER, Boolean.TRUE);
    }


    /**
     * Constructor for the Sample External Consent System Adapter. Initializes the adapter descriptor so PingFederate can
     * generate the proper configuration GUI
     *
     * We have chosen the name of the core attribute to be 'scopes' by default where this adapter will send back the list of approved scopes
     * This is the same name that must be selected under Authorization Server Settings.
     */
    public ExternalConsentPageAdapter()
    {
        // Create an adapter GUI descriptor
        AdapterConfigurationGuiDescriptor configurationGuiDescriptor = new AdapterConfigurationGuiDescriptor("External Consent Page Adapter");

        // Create an Idp adapter descriptor 
        Set<String> attributeContract = new HashSet<>();
        attributeContract.add(SCOPES);
        this.descriptor = new IdpAuthnAdapterDescriptor(this, "External Consent Page Adapter", attributeContract, true, configurationGuiDescriptor, false);
    }

    /**
     * This method is called by the PingFederate server to push configuration values entered by the administrator via
     * the dynamically rendered GUI configuration screen in the PingFederate administration console. Your implementation
     * should use the {@link Configuration} parameter to configure its own internal state as needed. The tables and
     * fields available in the Configuration object will correspond to the tables and fields defined on the
     * {@link org.sourceid.saml20.adapter.gui.AdapterConfigurationGuiDescriptor} on the AuthnAdapterDescriptor returned
     * by the {@link #getAdapterDescriptor()} method of this class. <br/>
     * <br/>
     * Each time the PingFederate server creates a new instance of your adapter implementation this method will be
     * invoked with the proper configuration. All concurrency issues are handled in the server so you don't need to
     * worry about them here. The server doesn't allow access to your adapter implementation instance until after
     * creation and configuration is completed.
     *
     * @param config
     *            the Configuration object constructed from the values entered by the user via the GUI.
     */
    @Override
    public void configure(Configuration config)
    {
    }

    /**
     * The PingFederate server will invoke this method on your adapter implementation to discover metadata about the
     * implementation. This included the adapter's attribute contract and a description of what configuration fields to
     * render in the GUI. <br/>
     * <br/>
     *
     * @return an IdpAuthnAdapterDescriptor object that describes this IdP adapter implementation.
     */
    @Override
    public IdpAuthnAdapterDescriptor getAdapterDescriptor()
    {
        return this.descriptor;
    }

     /**
     * This is an extended method that the PingFederate server will invoke during processing of a single sign-on
     * transaction to lookup information about an authenticated security context or session for a user at the external
     * application or authentication provider service.
     * <p>
     * In this example, the user will be shown an OAuth scopes approval page for consent.
      * The page is rendered using a velocity template populated by OAuth authorization request information which include client and scope details.
     * </p>
     *
     * @param req
     *            the HttpServletRequest can be used to read cookies, parameters, headers, etc. It can also be used to
     *            find out more about the request like the full URL the request was made to. Accessing the HttpSession
     *            from the request is not recommended and doing so is deprecated. Use
     *            {@link org.sourceid.saml20.adapter.state.SessionStateSupport} as an alternative.
     * @param resp
     *            the HttpServletResponse. The response can be used to facilitate an asynchronous interaction. Sending a
     *            client side redirect or writing (and flushing) custom content to the response are two ways that an
     *            invocation of this method allows for the adapter to take control of the user agent. Note that if
     *            control of the user agent is taken in this way, then the agent must eventually be returned to the
     *            <code>resumePath</code> endpoint at the PingFederate server to complete the protocol transaction.
     * @param inParameters
     *            A map that contains a set of input parameters. The input parameters provided are detailed in
     *            {@link IdpAuthenticationAdapterV2}, prefixed with <code>IN_PARAMETER_NAME_*</code> i.e.
     *            {@link IdpAuthenticationAdapterV2#IN_PARAMETER_NAME_RESUME_PATH}.
     * @return {@link AuthnAdapterResponse} The return value should not be null.
     *           SUCCESS result means the user has approved some scopes
     *           FAILURE result means the user has denied the scopes
     * @throws AuthnAdapterException
     *             for any unexpected runtime problem that the implementation cannot handle.
     * @throws IOException
     *             for any problem with I/O (typically any operation that writes to the HttpServletResponse).
     */
    @Override
    public AuthnAdapterResponse lookupAuthN(HttpServletRequest req, HttpServletResponse resp, Map<String, Object> inParameters) throws AuthnAdapterException, IOException
    {
        AuthnAdapterResponse authnAdapterResponse = new AuthnAdapterResponse();
        String action = (String)inParameters.get(IN_PARAMETER_NAME_ADAPTER_ACTION);
        if (!IdpAuthenticationAdapterV2.ADAPTER_ACTION_EXTERNAL_CONSENT.equals(action))
        {
            authnAdapterResponse.setErrorMessage("This adapter may only be used for user consent.");
            authnAdapterResponse.setAuthnStatus(AUTHN_STATUS.FAILURE);
            return authnAdapterResponse;
        }
        // Handle Submit if clicked
        if (req.getParameter("approved") != null)
        {
            // do CSRF check
            if (!isCSRFTokenValid(req, resp))
            {
                authnAdapterResponse.setErrorMessage("Invalid CSRF Token");
                authnAdapterResponse.setAuthnStatus(AUTHN_STATUS.FAILURE);
                return authnAdapterResponse;
            }

            if("deny".equals(req.getParameter("approved")))
            {
                authnAdapterResponse.setErrorMessage("User clicked Deny");
                authnAdapterResponse.setAuthnStatus(AUTHN_STATUS.FAILURE);
                return authnAdapterResponse;
            }
            else if (("allow".equals(req.getParameter("approved"))))    //consent approval result processing
            {
                Map<String, Object> attributeMap = new HashMap<>();
                if (req.getParameterValues(SCOPES) != null) //don't send null scopes back
                {
                    String[] approvedScopes = req.getParameterValues(SCOPES);
                    Scope requestedScope = new Scope((String)inParameters.get(IN_PARAMETER_NAME_OAUTH_SCOPE));
                    Scope approvedScope = new Scope(approvedScopes);
                    // validated the approved scopes
                    if (!approvedScope.isEqualOrLesserThan(requestedScope))
                    {
                        authnAdapterResponse.setErrorMessage("Approved scope cannot exceed the requested scope");
                        authnAdapterResponse.setAuthnStatus(AUTHN_STATUS.FAILURE);
                        return authnAdapterResponse;
                    }
                    /*
                     * PingFederate will also accept the approved scopes if they're sent back in the following formats
                     *
                     * //return scopes as space delimited string
                     * attributeMap.put(SCOPES, String.join(" ", approvedScopes));
                     *
                     * //return scopes as an array or a collection
                     * attributeMap.put(SCOPES, approvedScopes);
                     */
                    attributeMap.put(SCOPES, new AttributeValue(Arrays.asList(approvedScopes)));
                }

                authnAdapterResponse.setAttributeMap(attributeMap);
                authnAdapterResponse.setAuthnStatus(AUTHN_STATUS.SUCCESS);
                return authnAdapterResponse;
            }
        }

        // Render form
        renderForm(req, resp, inParameters);
        authnAdapterResponse.setAuthnStatus(AUTHN_STATUS.IN_PROGRESS);
        return authnAdapterResponse;
    }

    /**
     *
     * This is a helper method that renders the template form via {@link TemplateRendererUtil} class.
     *
     *@param req
     *            the HttpServletRequest can be used to read cookies, parameters, headers, etc. It can also be used to
     *            find out more about the request like the full URL the request was made to. Accessing the HttpSession
     *            from the request is not recommended and doing so is deprecated. Use
     *            {@link org.sourceid.saml20.adapter.state.SessionStateSupport} as an alternative.
     * @param resp
     *            the HttpServletResponse. The response can be used to facilitate an asynchronous interaction. Sending a
     *            client side redirect or writing (and flushing) custom content to the response are two ways that an
     *            invocation of this method allows for the adapter to take control of the user agent. Note that if
     *            control of the user agent is taken in this way, then the agent must eventually be returned to the
     *            <code>resumePath</code> endpoint at the PingFederate server to complete the protocol transaction.
     * @param inParameters
     *            A map that contains a set of input parameters. The input parameters provided are detailed in
     *            {@link IdpAuthenticationAdapterV2}, prefixed with <code>IN_PARAMETER_NAME_*</code> i.e.
     *            {@link IdpAuthenticationAdapterV2#IN_PARAMETER_NAME_RESUME_PATH}.
     * @throws AuthnAdapterException
     *             for any unexpected runtime problem that the implementation cannot handle.
     */
    @SuppressWarnings("unchecked")
    private void renderForm(HttpServletRequest req, HttpServletResponse resp,  Map<String, Object> inParameters) throws AuthnAdapterException
    {
        Map<String, Object> params = new HashMap<>(inParameters);

        //save CSRF token
        String cSRFToken = IDGenerator.rndAlphaNumeric(20);
        state.setAttribute(CSRF_TOKEN_NAME, cSRFToken, req, resp, false);

        params.put(CSRF_TOKEN_NAME, cSRFToken);
        Map<String, AttributeValue> chainedAttributes = (Map<String, AttributeValue>) inParameters.get(IN_PARAMETER_NAME_CHAINED_ATTRIBUTES);
        if (chainedAttributes != null)
        {
            params.put("userKey", chainedAttributes.get(USER_KEY_ATTR_NAME));
            params.put("userName", chainedAttributes.get(USER_NAME_ATTR_NAME));
        }
        Scope requestedScope = new Scope((String)inParameters.get(IN_PARAMETER_NAME_OAUTH_SCOPE));
        params.put("requestedScopes", requestedScope.getScopeStr());
        Map<String, String> scopeDescriptions = (Map<String, String>)inParameters.get(IN_PARAMETER_NAME_OAUTH_SCOPE_DESCRIPTIONS);
        params.put("scopeDescriptions", scopeDescriptions);
        params.put("defaultScopeDescription", inParameters.get(IN_PARAMETER_NAME_DEFAULT_SCOPE));
        params.put("action", inParameters.get(IN_PARAMETER_NAME_RESUME_PATH));
        params.put(Parameters.CLIENT_ID, inParameters.get(IN_PARAMETER_NAME_OAUTH_CLIENT_ID));

        // Load external-consent-page.properties file and store it in the map.
        // Note on internationalization, if a language properties file like external-consent-page_fr.properties
        // is created then a corresponding PingFederate properties needs to also be created (i.e. pingfederate-messages_fr.properties).
        Locale userLocale = LocaleUtil.getUserLocale(req);
        LanguagePackMessages lpm = new LanguagePackMessages("external-consent-page", userLocale);
        params.put("pluginTemplateMessages", lpm);

        try
        {
            TemplateRendererUtil.render(req, resp, "external.consent.page.html", params);
        }
        catch (TemplateRendererUtilException e)
        {
            throw new AuthnAdapterException(e);
        }
    }

    /**
     * This is the method that the PingFederate server will invoke during processing of a single logout to terminate a
     * security context for a user at the external application or authentication provider service.
     *
     * <p>
     * In this example, no extra action is needed to logout so simply return true.
     * </p>
     *
     * @param authnIdentifiers
     *            the map of authentication identifiers originally returned to the PingFederate server by the
     *            {@link #lookupAuthN} method. This enables the adapter to associate a security context or session
     *            returned by lookupAuthN with the invocation of this logout method.
     * @param req
     *            the HttpServletRequest can be used to read cookies, parameters, headers, etc. It can also be used to
     *            find out more about the request like the full URL the request was made to.
     * @param resp
     *            the HttpServletResponse. The response can be used to facilitate an asynchronous interaction. Sending a
     *            client side redirect or writing (and flushing) custom content to the response are two ways that an
     *            invocation of this method allows for the adapter to take control of the user agent. Note that if
     *            control of the user agent is taken in this way, then the agent must eventually be returned to the
     *            <code>resumePath</code> endpoint at the PingFederate server to complete the protocol transaction.
     * @param resumePath
     *            the relative URL that the user agent needs to return to, if the implementation of this method
     *            invocation needs to operate asynchronously. If this method operates synchronously, this parameter can
     *            be ignored. The resumePath is the full path portion of the URL - everything after hostname and port.
     *            If the hostname, port, or protocol are needed, they can be derived using the HttpServletRequest.
     * @return a boolean indicating if the logout was successful.
     * @throws AuthnAdapterException
     *             for any unexpected runtime problem that the implementation cannot handle.
     * @throws IOException
     *             for any problem with I/O (typically any operation that writes to the HttpServletResponse will throw
     *             an IOException.
     *
     * @see IdpAuthenticationAdapter#logoutAuthN(Map, HttpServletRequest, HttpServletResponse, String)
     */
    @Override
    public boolean logoutAuthN(Map authnIdentifiers, HttpServletRequest req, HttpServletResponse resp, String resumePath) throws AuthnAdapterException, IOException
    {
        throw new AuthnAdapterException("This adapter does not support logout action");
    }

    /**
     * The map returned in this example includes an entry for ADAPTER_INFO_EXTERNAL_CONSENT_ADAPTER set to true
     * to indicate that this adapter supports externalized OAuth consent
     *
     * @return a map
     */
    @Override
    public Map<String, Object> getAdapterInfo()
    {
        return idpAdapterInfo;
    }

    /**
     * This method is deprecated. It is not called when IdpAuthenticationAdapterV2 is implemented. It is replaced by
     * {@link #lookupAuthN(HttpServletRequest, HttpServletResponse, Map)}
     *
     */
    @Override
    @Deprecated
    public Map lookupAuthN(HttpServletRequest req, HttpServletResponse resp, String partnerSpEntityId, AuthnPolicy authnPolicy, String resumePath) throws AuthnAdapterException, IOException
    {
        throw new UnsupportedOperationException();
    }

    /**
     * A simple CSRF validator method.
     *
     * @param req
     *         the HttpServletRequest can be used to read cookies, parameters,
     *         headers, etc. It can also be used to find out more about the request
     *         like the full URL the request was made to.
     * @param resp
     *         the HttpServletResponse. The response can be used to facilitate
     *         an asynchronous interaction. Sending a client side redirect or writing
     *         (and flushing) custom content to the response are two ways that an
     *         invocation of this method allows for the adapter to take control of the
     *         user agent. Note that if control of the user agent is taken in this way,
     *         then the agent must eventually be returned to the <code>resumePath</code>
     *         endpoint at the PingFederate server to complete the protocol transaction.
     * @return true if CSRF token in the request matches with the one present in the
     *         state,
     */
    private boolean isCSRFTokenValid(HttpServletRequest req, HttpServletResponse resp)
    {
        String requestCSRFToken = req.getParameter(CSRF_TOKEN_NAME);
        if (requestCSRFToken == null)
        {
            return false;
        }

        String stateCSRFToken = (String) state.getAttribute(CSRF_TOKEN_NAME, req, resp);
        return requestCSRFToken.equals(stateCSRFToken);
    }

}
