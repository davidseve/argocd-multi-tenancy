export HTPASSWD_FILE=/tmp/htpasswd

htpasswd -c -B -b $HTPASSWD_FILE userA userA
htpasswd -b $HTPASSWD_FILE userB userB


oc get secrets htpass-secret -n openshift-config -ojsonpath='{.data.htpasswd}' | base64 -d >> $HTPASSWD_FILE  

oc create secret generic htpass-secret --from-file=$HTPASSWD_FILE -n openshift-config --dry-run=client -o yaml > /tmp/htpass-secret.yaml
oc replace -f /tmp/htpass-secret.yaml
