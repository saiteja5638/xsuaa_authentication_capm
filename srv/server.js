var cds = require('@sap/cds')
const xsenv = require('@sap/xsenv');
const axios = require('axios');

// Adding the Dynamic Authentication For Application 


cds.on("bootstrap", (app) => {

    app.use(async (req, res, next) => {
        try {
            const authHeader = req.headers?.authorization;
            if (req.url == '/') {
                next()
            }
            if (req.url.includes('AdminConfigurations')) {

                if (!(authHeader.startsWith("Basic ")==undefined)) {
                    const base64Credentials = authHeader.split(" ")[1];
                    const decodedCredentials = Buffer.from(base64Credentials, "base64").toString("utf8");
                    const [username, password] = decodedCredentials.split(":");

                    if (username == 'vcpsteelcase' && password == 'sbpcorp') {
                        await authenticate(req, next)
                    } else {
                        let obj = {
                            status: 401,
                            Error: "Unauthorized: Please Check the Username and Password"
                        }

                        res.status(401).send(obj);
                    }
                } else {
                    next()
                }

            }
            else {
                next()
            }

        } catch (error) {
            console.log(error)
            next()
        }
    })

});


async function authenticate(req, next) {

    const xsuaaService = xsenv.getServices({
        uaa: {
            name: 'xsuaa_authentication_capm-auth'
        }
    });
    const clientId = xsuaaService.uaa.clientid;
    const clientSecret = xsuaaService.uaa.clientsecret;
    const tokenUrl = xsuaaService.uaa.url + '/oauth/token';

    const params = new URLSearchParams();
    params.append('grant_type', 'client_credentials');
    params.append('client_id', clientId);
    params.append('client_secret', clientSecret);

    await axios.post(tokenUrl, params)
        .then(response => {
            const accessToken = response.data.access_token;

            req.headers.authorization = "Bearer " +
                accessToken;
            next();
        }).catch(error => {
            console.log("Error obtaining access token:", error);
            next();
        });

}

module.exports = cds.server;