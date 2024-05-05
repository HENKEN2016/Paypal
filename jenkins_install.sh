#!/bin/bash

# Variables
JENKINS_URL="<https://pkg.jenkins.io>"
JENKINS_REPO=""
JENKINS_PACKAGE="jenkins"
JAVA_VERSION="1.8.0"
JENKINS_ADMIN_USERNAME="admin"
ADMIN_EMAIL="admin@example.com"

if [[ "$(id -u)" != "0" ]]; then
    echo "This script must be executed as root."
    exit 1
fi

# Detect distribution
if grep -Eqi "ubuntu|debian" /etc/*release; then
    PACKAGE_MANAGER="apt-get"
    if ! which curl &> /dev/null; then
        apt-get -y install curl
    fi
elif grep -Eqi "centos|redhat|fedora" /etc/*release; then
    PACKAGE_MANAGER="yum"
else
    echo "Unsupported operating system detected. Aborting..."
    exit 1
fi

# Install prerequisites
case "${PACKAGE_MANAGER}" in
    "apt-get")
        ${PACKAGE_MANAGER} update
        ${PACKAGE_MANAGER} install -y openjdk-${JAVA_VERSION}-jdk git curl
        ;;
    "yum")
        ${PACKAGE_MANAGER} update -y
        ${PACKAGE_MANAGER} install -y java-1.8.0-openjdk-devel git curl
        ;;
esac

# Import Jenkins GPG Key
curl --silent --fail "${JENKINS_URL}/$(${PACKAGE_MANAGER} info $JENKINS_PACKAGE | grep '^Version:' | awk '{print $2}' | cut -c 1-5)/jenkins.io.key" | gpg --dearmor | sudo tee /usr/share/keyrings/jenkins-archive-keyring.asc > /dev/null

# Prepare repository configuration
if [ "$(grep -ci "jenkins.io/" /etc/apt/sources.list*)" == "0" ]; then
    case "${PACKAGE_MANAGER}" in
        "apt-get")
            echo "deb [signed-by=/usr/share/keyrings/jenkins-archive-keyring.asc] ${JENKINS_URL}/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
            ;;
        "yum")
            JENKINS_REPO="/etc/yum.repos.d/jenkins.repo"
            sudo touch $JENKINS_REPO
            echo "[jenkins]" | sudo tee $JENKINS_REPO > /dev/null
            echo "name=Jenkins" | sudo tee -a $JENKINS_REPO > /dev/null
            echo "baseurl=${JENKINS_URL}/redhat-stable" | sudo tee -a $JENKINS_REPO > /dev/null
            echo "gpgcheck=1" | sudo tee -a $JENKINS_REPO > /dev/null
            echo "enabled=1" | sudo tee -a $JENKINS_REPO > /dev/null
            ;;
    esac
fi

# Install Jenkins
${PACKAGE_MANAGER} install -y $JENKINS_PACKAGE

# Configure firewall rules
systemctl status ufw &>/dev/null && {
    ufw allow ssh
    ufw allow 8080
    ufw reload
} || :

# Set SElinux policies
setsebool -P httpd_can_network_connect true

# Start Jenkins
systemctl restart $JENKINS_PACKAGE

# Wait until Jenkins starts successfully
until $(curl --output /dev/null --silent --head --fail <http://localhost:8080>); do
    sleep 5
done

# Get Initial Admin Password
INITIAL_PASSWORD=$(sudo cat /var/lib/${JENKINS_PACKAGE}/secrets/initialAdminPassword)

# Display login information
clear
cat << EOF
===============================
Welcome to Jenkins Setup Wizard!
===============================

To access the Jenkins Dashboard, please visit:

    <http://$>(hostname):8080

Use the following credentials to log in:

Username: ${JENKINS_ADMIN_USERNAME}
Password: ${INITIAL_PASSWORD}

After logging in, follow the instructions provided within the UI to continue setting up Jenkins.

EOF
