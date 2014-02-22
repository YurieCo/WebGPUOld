
OAuth = (require 'oauth').OAuth

coursera_oauth_consumer_key = ''
coursera_oauth_consumer_secret = ''
coursera_provider_url = 'https://authentication.coursera.org/auth/oauth/api/'

coursera_request_token_address = 'https://authentication.coursera.org/auth/oauth/api/request_token'
coursera_access_token_address = 'https://authentication.coursera.org/auth/oauth/api/access_token'
coursera_get_identity_address = 'https://authentication.coursera.org/auth/oauth/api/get_identity'

call_back_address = undefined
oa = undefined

setup = (address) ->
    call_back_address = "http://" + address.address
    if address.port != 80
        call_back_address += ":" + address.port
    call_back_address += "/login/callback"

    oa = new OAuth(
        coursera_request_token_address,
        coursera_access_token_address,
        coursera_oauth_consumer_key,
        coursera_oauth_consumer_secret,
        "1.0",
        call_back_address,
        "HMAC-SHA1"
    )


login = (req, res) ->
    oa.getOAuthRequestToken (err, oauth_token, oauth_token_secret, data) ->
        if err
            res.send 404, 'was not able to login'
        else
            req.session.oauth = oa
            req.session.oauth.token = oauth_token
            req.session.oauth.token_secret = data.oauth_secret
            res.redirect data.authentication_url + "?oauth_token=" + oauth_token

login_callback = (req, res, redirect) ->
    if req.session.oauth
        req.session.oauth.verifier = req.query.oauth_verifier
        oauth = req.session.oauth

        oa.getOAuthAccessToken oauth.token,
                               oauth.token_secret,
                               oauth.verifier,
                               (err, oauth_access_token, oauth_access_token_secret, results) ->
                                    if err
                                        res.send 404, 'Was not able to perform oauth login.'
                                    else
                                        req.session.oauth.access_token = oauth_access_token
                                        req.session.oauth.access_token_secret = oauth_access_token_secret
                                        get_login_credentials req, res, redirect
    else
        res.send 404, 'Was not able to perform oauth login'

get_login_credentials = (req, res, redirect) ->
    if req.session.oauth
        oauth = req.session.oauth
        oa.getProtectedResource coursera_get_identity_address,
                                "GET",
                                oauth.access_token,
                                oauth.access_token_secret,
                                (err, data, response) ->
                                    if err
                                        res.send 404, "Unable to get login credentials"
                                    else
                                        req.session.user_data = data
                                        req.session.user_id = data.id
                                        res.redirect redirect
    else
        res.send 404, 'Was not able to get login credentials'

exports.setup = setup
exports.login = login
exports.login_callback = login_callback

