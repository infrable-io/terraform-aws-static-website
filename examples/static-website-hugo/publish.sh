#!/usr/bin/env bash
#
# Publish content to static-website.com.
#
# usage: publish.sh

# set S3 bucket
S3_BUCKET_ROOT=$(terraform output s3_root_id)

# set CloudFront distribution ID
CF_DISTRIBUTION_ID=$(terraform output cf_distribution_id)

# change directory to Hugo site
cd $PWD/site

# remove static files
rm -rf $PWD/public

# build static files
hugo

# remove files from S3
aws s3 rm s3://$S3_BUCKET_ROOT --recursive

# sync files with S3
aws s3 sync --acl "public-read" public/ s3://$S3_BUCKET_ROOT

# invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id $CF_DISTRIBUTION_ID --paths "/*"
