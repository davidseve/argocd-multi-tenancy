export HTPASSWD_FILE=/tmp/htpasswd

htpasswd -c -B -b $HTPASSWD_FILE userA userA
htpasswd -b $HTPASSWD_FILE userB userB

##
# Creating htpasswd file in Openshift
##
oc delete secret lab-users -n openshift-config
oc create secret generic lab-users --from-file=htpasswd=/tmp/htpasswd -n openshift-config

##
# Configuring OAuth to authenticate users via htpasswd
##
oc apply -f ./scripts/oauth.yaml

