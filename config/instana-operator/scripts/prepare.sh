#/bin/bash

isocp=false
if kubectl api-resources | grep projectrequests > /dev/null ; then
  isocp=true
fi
echo "isocp: $isocp"

base=$baseDomain
if [ "$baseDomain" = "" ] ; then
  if [ "$isocp" = "true" ]; then
    base=`kubectl get ingresses.config/cluster -o jsonpath={.spec.domain}`
  else
   echo "env variable 'baseDomain' is not set yet, exit. " 
   exit 1
  fi
fi
echo "baseDomain: $base"

if [ "$portalPassword" = "" ] ; then
    portalPassword="passw0rd"
fi
echo "portalPassword: $portalPassword"

# create ns instana-operator to create other stuff: secret/kubeconfig
kubectl create ns instana-operator

# kubeconfig
if [ ! -f $HOME/.kube/config ]; then
	echo "file $HOME/.kube/config not found to continue, pls run oc login first. "
	exit 2
fi
kubectl create secret generic kubeconfig --from-file=credentials=$HOME/.kube/config -n instana-operator

# cert-manager
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.0/cert-manager.yaml

# --
export dist=$(cat /etc/os-release  | grep "^ID=" | cut -f2 -d= | tr -d '"')
which expect > /dev/null 2>&1
if [ $? -ne 0 ] ; then
    if [ "$dist" = "rhel" ] ; then
        yum install -y expect  > /dev/null 2>&1
    else
        if [ "$dist" = "ubuntu" ] ; then
            apt install -y expect  > /dev/null 2>&1
        else
            echo "no expected linux, exit"
            exit 1
        fi
    fi
fi

if [ ! -x /usr/local/bin/mycertpem.sh ] ; then
echo '#!/usr/bin/expect -f

set timeout -1
set mypassword [lindex $argv 0]
set base [lindex $argv 1]

#------- key.pem
spawn openssl genrsa -aes128 -out key.pem 2048

expect "Enter pass phrase for key.pem:"
send -- "$mypassword\r"

expect "Verifying - Enter pass phrase for key.pem:"
send -- "$mypassword\r"


#------- cert.pem from key.pem
puts "\r\r"
spawn openssl req -new -x509 -key key.pem -out cert.pem -days 365

expect "Enter pass phrase for key.pem"
send -- "$mypassword\r"

expect "Country Name (2 letter code)"
send -- "CN\r"

expect "State or Province Name (full name)"
send -- "BJ\r"

expect "Locality Name (eg, city) "
send -- "BJ\r"

expect "Organization Name (eg, company)"
send -- "IBM\r"

expect "Organizational Unit Name (eg, section)"
send -- "CDL\r"

expect "Common Name "
send -- "$base\r"

expect "Email Address"
send -- "\r"

expect eof
' > /usr/local/bin/mycertpem.sh

chmod +x /usr/local/bin/mycertpem.sh
else
    echo "mycertpem.sh exists." 
fi


if [ "$isocp" = "true" ]; then
  /usr/local/bin/mycertpem.sh $portalPassword  instana.$base
else
  /usr/local/bin/mycertpem.sh $portalPassword  $base
fi

cat key.pem cert.pem > sp.pem
kubectl create configmap instana-sppem -n default --from-file=sppem=sp.pem
if alias | grep "rm='rm -i'" > /dev/null ; then
  unalias rm
fi
rm key.pem cert.pem  sp.pem

