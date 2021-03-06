# vim: ts=2 sw=2 et

# This file contains the user-data script that gets run on newly-created 
# bootstrap systems.  It has been moved to a separate file to keep things 
# looking cleaner.  It also makes modifications much easier to notice!

data "template_file" "bootstrap_user_data" {
  vars {
    admin_email   = "${var.admin_email}"
    home_bucket   = "${aws_s3_bucket.puppet_config_home.bucket}"
    remote_bucket = "${var.remote_region == "none" ? "none" : "${var.bucket_prefix}-config-remote"}"
    dns_name      = "${var.domain}"
    dns_id        = "${aws_route53_zone.puppet_zone.id}"
    efs_id        = "${aws_efs_file_system.bootstrap.id}"
    bootstrap_arn = "${aws_sqs_queue.bootstrap.arn}"
    bootstrap_url = "${aws_sqs_queue.bootstrap.id}"
    builder_arn   = "${aws_sqs_queue.builder.arn}"
    builder_url   = "${aws_sqs_queue.builder.id}"
    gpg_key_id    = "${var.gpg_key}"
    bootstrap_git = "${var.bootstrap_repo}"
    bootstrap_tag = "${var.bootstrap_tag}"
  }

  template = <<ENDUSERDATA
#!/bin/bash

# Send stdout and stderr to a local file
exec 1>/var/log/user-data.log 2>&1

# Create files with info on our config
echo "Writing out config files"
cat - <<EOF > /etc/kathputli-bootstrap.json
{
  "admin_email": "$${admin_email}",
  "home_bucket": "$${home_bucket}",
  "remote_bucket": "$${remote_bucket}",
  "dns_zone": {
    "id": "$${dns_id}",
    "name": "$${dns_name}"
  },
  "efs_id": "$${efs_id}",
  "bootstrap_queue": {
    "arn": "$${bootstrap_arn}",
    "url": "$${bootstrap_url}"
  },
  "builder_queue": {
    "arn": "$${builder_arn}",
    "url": "$${builder_url}"
  },
  "gpg_key_id": "$${gpg_key_id}",
  "git_sources": {
    "bootstrap": {
      "url": "$${bootstrap_git}",
      "tag": "$${bootstrap_tag}"
    }
  }
}
EOF
cat - <<EOF > /etc/kathputli-bootstrap.sh
ADMIN_EMAIL="$${admin_email}"
HOME_BUCKET="$${home_bucket}"
REMOTE_BUCKET="$${remote_bucket}"
DNS_ZONE_ID="$${dns_id}"
DNS_ZONE_NAME="$${dns_name}"
EFS_ID="$${efs_id}"
BOOTSTRAP_ARN="$${bootstrap_arn}"
BOOTSTRAP_URL="$${bootstrap_url}"
BUILDER_ARN="$${builder_arn}"
BUILDER_URL="$${builder_url}"
GPG_KEY_ID="$${gpg_key_id}"
BOOTSTRAP_REPO="$${bootstrap_git}"
BOOTSTRAP_TAG="$${bootstrap_tag}"
EOF

# Uppgrade existing packages, and install Git & GPG
echo ; echo "Updating package list"
apt-get update
echo ; echo "Upgrading installed packages"
DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
echo ; echo "Installing packages needed for bootstrap"
DEBIAN_FRONTEND=noninteractive apt-get install -y git gnupg gnupg-curl

# Fetch the bootstrap signing key
echo ; echo "Fetching and trusting signing key ($${gpg_key_id})"
gpg --keyserver keys.gnupg.net --recv-keys $${gpg_key_id}
echo 'trusted-key $${gpg_key_id}' >> ~/.gnupg/gpg.conf
gpg --update-trustdb

# Fetch, verify, and run the bootstrap
echo ; echo "Fetching bootstrap code from $${bootstrap_git}:$${bootstrap_tag}"
git clone $${bootstrap_git} kathputli-bootstrap
cd kathputli-bootstrap
git tag -v $${bootstrap_tag} >> /var/log/bootstrap_tag.txt || exit 1
git checkout production
echo ; echo "Running bootstrap!"
exec ./bootstrap.sh
ENDUSERDATA
}
