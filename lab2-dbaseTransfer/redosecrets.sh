oc delete secret custom-credentials-webengine-dbdomain-secret;
oc delete secret custom-credentials-webengine-dbtype-secret;
oc create secret generic custom-credentials-webengine-dbtype-secret --from-file=dx_dbtype.properties ;
oc create secret generic custom-credentials-webengine-dbdomain-secret --from-file=dx_dbdomain.properties
