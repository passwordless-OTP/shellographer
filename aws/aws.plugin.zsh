# AWS CLI - Enhanced completions with profile and resource management
# Original aws.plugin.zsh content preserved + enhanced completions

# ============================================================
# ORIGINAL AWS PLUGIN FUNCTIONS (preserved)
# ============================================================

function agp() {
  echo $AWS_PROFILE
}

function agr() {
  echo $AWS_REGION
}

# Update state file if enabled
function _aws_update_state() {
  if [[ "$AWS_PROFILE_STATE_ENABLED" == true ]]; then
    test -d $(dirname ${AWS_STATE_FILE}) || exit 1
    echo "${AWS_PROFILE} ${AWS_REGION}" > "${AWS_STATE_FILE}"
  fi
}

function _aws_clear_state() {
  if [[ "$AWS_PROFILE_STATE_ENABLED" == true ]]; then
    test -d $(dirname ${AWS_STATE_FILE}) || exit 1
    echo -n > "${AWS_STATE_FILE}"
  fi
}

# AWS profile selection
function asp() {
  if [[ -z "$1" ]]; then
    unset AWS_DEFAULT_PROFILE AWS_PROFILE AWS_EB_PROFILE AWS_PROFILE_REGION
    _aws_clear_state
    echo AWS profile cleared.
    return
  fi

  local available_profiles=($(_aws_get_profiles))
  if [[ -z "${available_profiles[(r)$1]}" ]]; then
    echo "${fg[red]}Profile '$1' not found in '${AWS_CONFIG_FILE:-$HOME/.aws/config}'" >&2
    echo "Available profiles: ${(j:, :)available_profiles:-no profiles found}${reset_color}" >&2
    return 1
  fi

  export AWS_DEFAULT_PROFILE=$1
  export AWS_PROFILE=$1
  export AWS_EB_PROFILE=$1
  _aws_update_state
  echo "Switched to AWS Profile: $1"
}

function _aws_get_profiles() {
  local credentials="${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}"
  local config="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
  
  local profiles=()
  
  # Get profiles from credentials file
  if [[ -r "$credentials" ]]; then
    profiles+=(${(f)"$(grep -E '^\[.*\]$' "$credentials" 2>/dev/null | sed 's/\[//; s/\]//' | grep -v '^default$')"})
  fi
  
  # Get profiles from config file
  if [[ -r "$config" ]]; then
    profiles+=(${(f)"$(grep -E '^\[profile' "$config" 2>/dev/null | sed 's/\[profile //; s/\]//')"})
  fi
  
  # Add default if it exists
  if grep -q '^\[default\]' "$credentials" 2>/dev/null || grep -q '^\[default\]' "$config" 2>/dev/null; then
    profiles=("default" ${profiles[@]})
  fi
  
  echo "${(u)profiles[@]}"
}

# AWS region selection
function asr() {
  if [[ -z "$1" ]]; then
    unset AWS_REGION AWS_DEFAULT_REGION
    echo "AWS region cleared."
  else
    export AWS_REGION=$1
    export AWS_DEFAULT_REGION=$1
    _aws_update_state
    echo "AWS region set to: $1"
  fi
}

# Get AWS regions
function _aws_get_regions() {
  local regions=(
    'us-east-1:US East (N. Virginia)'
    'us-east-2:US East (Ohio)'
    'us-west-1:US West (N. California)'
    'us-west-2:US West (Oregon)'
    'af-south-1:Africa (Cape Town)'
    'ap-east-1:Asia Pacific (Hong Kong)'
    'ap-south-1:Asia Pacific (Mumbai)'
    'ap-northeast-3:Asia Pacific (Osaka)'
    'ap-northeast-2:Asia Pacific (Seoul)'
    'ap-southeast-1:Asia Pacific (Singapore)'
    'ap-southeast-2:Asia Pacific (Sydney)'
    'ap-northeast-1:Asia Pacific (Tokyo)'
    'ca-central-1:Canada (Central)'
    'eu-central-1:Europe (Frankfurt)'
    'eu-west-1:Europe (Ireland)'
    'eu-west-2:Europe (London)'
    'eu-south-1:Europe (Milan)'
    'eu-west-3:Europe (Paris)'
    'eu-north-1:Europe (Stockholm)'
    'me-south-1:Middle East (Bahrain)'
    'sa-east-1:South America (São Paulo)'
  )
  print -l "${regions[@]}"
}

# Get AWS services
function _aws_get_services() {
  local services=(
    'acm:Certificate Manager'
    'apigateway:API Gateway'
    'appconfig:AppConfig'
    'appstream:AppStream'
    'appsync:AppSync'
    'athena:Athena'
    'autoscaling:Auto Scaling'
    'backup:Backup'
    'batch:Batch'
    'budgets:Budgets'
    'cloud9:Cloud9'
    'cloudformation:CloudFormation'
    'cloudfront:CloudFront'
    'cloudhsm:CloudHSM'
    'cloudsearch:CloudSearch'
    'cloudtrail:CloudTrail'
    'cloudwatch:CloudWatch'
    'codeartifact:CodeArtifact'
    'codebuild:CodeBuild'
    'codecommit:CodeCommit'
    'codedeploy:CodeDeploy'
    'codepipeline:CodePipeline'
    'codestar:CodeStar'
    'cognito-identity:Cognito Identity'
    'cognito-idp:Cognito Identity Provider'
    'comprehend:Comprehend'
    'configservice:Config Service'
    'configure:Configure'
    'connect:Connect'
    'databrew:DataBrew'
    'datapipeline:Data Pipeline'
    'datasync:DataSync'
    'dax:DAX'
    'deploy:Deploy'
    'devicefarm:Device Farm'
    'devops-guru:DevOps Guru'
    'directconnect:Direct Connect'
    'discovery:Application Discovery'
    'dms:Database Migration Service'
    'docdb:DocumentDB'
    'ds:Directory Service'
    'dynamodb:DynamoDB'
    'dynamodbstreams:DynamoDB Streams'
    'ec2:EC2'
    'ecr:ECR'
    'ecs:ECS'
    'efs:EFS'
    'eks:EKS'
    'elasticache:ElastiCache'
    'elasticbeanstalk:Elastic Beanstalk'
    'elastictranscoder:Elastic Transcoder'
    'elb:ELB'
    'elbv2:ELBv2'
    'emr:EMR'
    'es:Elasticsearch'
    'events:EventBridge'
    'firehose:Firehose'
    'fms:Firewall Manager'
    'forecast:Forecast'
    'frauddetector:Fraud Detector'
    'fsx:FSx'
    'gamelift:GameLift'
    'glacier:Glacier'
    'globalaccelerator:Global Accelerator'
    'glue:Glue'
    'greengrass:Greengrass'
    'guardduty:GuardDuty'
    'health:Health'
    'iam:IAM'
    'imagebuilder:Image Builder'
    'inspector:Inspector'
    'iot:IoT'
    'iotanalytics:IoT Analytics'
    'iotevents:IoT Events'
    'iotthingsgraph:IoT Things Graph'
    'kafka:MSK'
    'kendra:Kendra'
    'kinesis:Kinesis'
    'kinesisanalytics:Kinesis Analytics'
    'kinesisvideo:Kinesis Video'
    'kms:KMS'
    'lakeformation:Lake Formation'
    'lambda:Lambda'
    'lex-models:Lex'
    'license-manager:License Manager'
    'lightsail:Lightsail'
    'logs:CloudWatch Logs'
    'machinelearning:Machine Learning'
    'macie2:Macie'
    'managedblockchain:Managed Blockchain'
    'marketplace-catalog:Marketplace Catalog'
    'marketplace-entitlement:Marketplace Entitlement'
    'marketplacecommerceanalytics:Marketplace Commerce Analytics'
    'mediaconnect:MediaConnect'
    'mediaconvert:MediaConvert'
    'medialive:MediaLive'
    'mediapackage:MediaPackage'
    'mediastore:MediaStore'
    'mediatailor:MediaTailor'
    'meteringmarketplace:Marketplace Metering'
    'mgh:Migration Hub'
    'mq:MQ'
    'mturk:Mechanical Turk'
    'neptune:Neptune'
    'networkmanager:Network Manager'
    'opsworks:OpsWorks'
    'opsworkscm:OpsWorks CM'
    'organizations:Organizations'
    'outposts:Outposts'
    'personalize:Personalize'
    'pi:PI'
    'pinpoint:Pinpoint'
    'polly:Polly'
    'pricing:Pricing'
    'qldb:QLDB'
    'quicksight:QuickSight'
    'ram:RAM'
    'rds:RDS'
    'rds-data:RDS Data'
    'redshift:Redshift'
    'rekognition:Rekognition'
    'resource-groups:Resource Groups'
    'resourcegroupstaggingapi:Resource Groups Tagging'
    'robomaker:RoboMaker'
    'route53:Route 53'
    'route53domains:Route 53 Domains'
    'route53resolver:Route 53 Resolver'
    's3:S3'
    's3api:S3 API'
    's3control:S3 Control'
    'sagemaker:SageMaker'
    'sagemaker-runtime:SageMaker Runtime'
    'savingsplans:Savings Plans'
    'schemas:EventBridge Schemas'
    'sdb:SimpleDB'
    'secretsmanager:Secrets Manager'
    'securityhub:Security Hub'
    'serverlessrepo:Serverless Application Repository'
    'service-quotas:Service Quotas'
    'servicecatalog:Service Catalog'
    'servicediscovery:Service Discovery'
    'ses:SES'
    'sesv2:SESv2'
    'shield:Shield'
    'signer:Signer'
    'sms:Server Migration'
    'snowball:Snowball'
    'sns:SNS'
    'sqs:SQS'
    'ssm:SSM'
    'sso:SSO'
    'stepfunctions:Step Functions'
    'storagegateway:Storage Gateway'
    'sts:STS'
    'support:Support'
    'swf:SWF'
    'synthetics:Synthetics'
    'textract:Textract'
    'timestream-query:Timestream Query'
    'timestream-write:Timestream Write'
    'transcribe:Transcribe'
    'transfer:Transfer'
    'translate:Translate'
    'waf:WAF'
    'waf-regional:WAF Regional'
    'wafv2:WAFv2'
    'workdocs:WorkDocs'
    'worklink:WorkLink'
    'workmail:WorkMail'
    'workmailmessageflow:WorkMail Message Flow'
    'workspaces:WorkSpaces'
    'xray:X-Ray'
  )
  print -l "${services[@]}"
}

# Get S3 buckets (cached)
function _aws_get_s3_buckets() {
  local cache_file="${ZSH_CACHE_DIR}/aws_s3_buckets"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    aws s3 ls 2>/dev/null | awk '{print $3}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get EC2 instances (cached)
function _aws_get_ec2_instances() {
  local cache_file="${ZSH_CACHE_DIR}/aws_ec2_instances"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 60 ]]; then
    aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' --output text 2>/dev/null | \
      awk '{print $1":"$2" ["$3"]"}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get Lambda functions (cached)
function _aws_get_lambda_functions() {
  local cache_file="${ZSH_CACHE_DIR}/aws_lambda_functions"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 120 ]]; then
    aws lambda list-functions --query 'Functions[*].[FunctionName,Runtime,LastModified]' --output text 2>/dev/null | \
      awk '{print $1":"$2}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get CloudFormation stacks (cached)
function _aws_get_cfn_stacks() {
  local cache_file="${ZSH_CACHE_DIR}/aws_cfn_stacks"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 120 ]]; then
    aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --query 'StackSummaries[*].[StackName,StackStatus]' --output text 2>/dev/null | \
      awk '{print $1":"$2}' >| "$cache_file" &|
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# ============================================================
# ENHANCED AWS COMPLETION FUNCTION
# ============================================================

_aws_enhanced() {
  local curcontext="$curcontext" state line
  typeset -A opt_args
  
  local cur=$words[CURRENT]
  local prev=$words[CURRENT-1]
  
  # Global options completion
  if [[ "$cur" == -* ]]; then
    _aws_global_options
    return
  fi
  
  # Complete services
  if (( CURRENT == 2 )); then
    local -a services
    services=(${(f)"$(_aws_get_services)"})
    _describe -t services "AWS services" services
    return
  fi
  
  local service=$words[2]
  
  # Service-specific completions
  case "$service" in
    s3)
      _aws_s3_completion
      ;;
    s3api)
      _aws_s3api_completion
      ;;
    ec2)
      _aws_ec2_completion
      ;;
    lambda)
      _aws_lambda_completion
      ;;
    cloudformation)
      _aws_cloudformation_completion
      ;;
    iam)
      _aws_iam_completion
      ;;
    rds)
      _aws_rds_completion
      ;;
    ecs)
      _aws_ecs_completion
      ;;
    eks)
      _aws_eks_completion
      ;;
    sqs)
      _aws_sqs_completion
      ;;
    sns)
      _aws_sns_completion
      ;;
    cloudwatch)
      _aws_cloudwatch_completion
      ;;
    logs)
      _aws_logs_completion
      ;;
    kms)
      _aws_kms_completion
      ;;
    secretsmanager)
      _aws_secretsmanager_completion
      ;;
    ssm)
      _aws_ssm_completion
      ;;
    configure)
      _aws_configure_completion
      ;;
    *)
      # Fall back to default AWS completion
      _aws
      ;;
  esac
}

_aws_global_options() {
  local -a options
  options=(
    '--debug[Turn on debug logging]'
    '--endpoint-url[Override default URL]:url: '
    '--no-verify-ssl[Disable SSL verification]'
    '--no-paginate[Disable pagination]'
    '--output[Output format]:format:(json text table yaml yaml-stream)'
    '--query[JMESPath query]:query: '
    '--profile[AWS profile]:profile:_aws_profiles'
    '--region[AWS region]:region:_aws_regions'
    '--version[Display version]'
    '--color[Color output]:color:(on off auto)'
    '--no-sign-request[Skip request signing]'
    '--ca-bundle[CA certificate bundle]:file:_files'
    '--cli-read-timeout[Read timeout]:seconds:'
    '--cli-connect-timeout[Connect timeout]:seconds:'
  )
  _describe -t options "AWS options" options
}

_aws_profiles() {
  local profiles=(${(f)"$(_aws_get_profiles)"})
  _describe -t profiles "profiles" profiles
}

_aws_regions() {
  local regions=(${(f)"$(_aws_get_regions)"})
  _describe -t regions "regions" regions
}

# S3 completions
_aws_s3_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'ls:List buckets/objects'
      'cp:Copy files'
      'mv:Move files'
      'rm:Remove files'
      'sync:Sync directories'
      'mb:Make bucket'
      'rb:Remove bucket'
      'presign:Generate presigned URL'
    )
    _describe -t commands "S3 commands" commands
    return
  fi
  
  local cmd=$words[3]
  
  case "$cmd" in
    ls)
      _arguments \
        '--human-readable[Human readable sizes]' \
        '--summarize[Summary]' \
        '--recursive[Recursive]' \
        '*:bucket:_aws_s3_buckets'
      ;;
    cp|mv)
      _arguments \
        '--recursive[Recursive]' \
        '--include[Include pattern]:pattern: ' \
        '--exclude[Exclude pattern]:pattern: ' \
        '--cache-control[Cache control]:value: ' \
        '--content-type[Content type]:type: ' \
        '--metadata[Metadata]:map: ' \
        '--grants[Grants]:permissions: ' \
        '--storage-class[Storage class]:class:(STANDARD REDUCED_REDUNDANCY STANDARD_IA ONEZONE_IA INTELLIGENT_TIERING GLACIER DEEP_ARCHIVE OUTPOSTS)' \
        '--sse[Server-side encryption]:type:(AES256 aws:kms)' \
        '--sse-kms-key-id[KMS key ID]:key: ' \
        '--acl[ACL]:acl:(private public-read public-read-write authenticated-read bucket-owner-read bucket-owner-full-control)' \
        ':source:_files' \
        ':destination:_aws_s3_buckets'
      ;;
    rm)
      _arguments \
        '--recursive[Recursive]' \
        '--include[Include pattern]:pattern: ' \
        '--exclude[Exclude pattern]:pattern: ' \
        '--dryrun[Show what would be done]' \
        '*:path:_aws_s3_buckets'
      ;;
    sync)
      _arguments \
        '--delete[Delete destination files]' \
        '--include[Include pattern]:pattern: ' \
        '--exclude[Exclude pattern]:pattern: ' \
        '--storage-class[Storage class]:class:(STANDARD REDUCED_REDUNDANCY STANDARD_IA ONEZONE_IA INTELLIGENT_TIERING GLACIER DEEP_ARCHIVE)' \
        '--sse[Server-side encryption]:type:(AES256 aws:kms)' \
        ':source:_files -/' \
        ':destination:_aws_s3_buckets'
      ;;
    mb|rb)
      _arguments \
        '--region[Region]:region:_aws_regions' \
        '*:bucket:_aws_s3_buckets'
      ;;
    presign)
      _arguments \
        '--expires-in[Expiration]:seconds:' \
        ':bucket:_aws_s3_buckets'
      ;;
  esac
}

_aws_s3_buckets() {
  local buckets=(${(f)"$(_aws_get_s3_buckets)"})
  _describe -t buckets "S3 buckets" buckets
}

# S3API completions
_aws_s3api_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'abort-multipart-upload:Abort multipart upload'
      'complete-multipart-upload:Complete multipart upload'
      'copy-object:Copy object'
      'create-bucket:Create bucket'
      'create-multipart-upload:Create multipart upload'
      'delete-bucket:Delete bucket'
      'delete-bucket-analytics-configuration:Delete analytics config'
      'delete-bucket-cors:Delete CORS'
      'delete-bucket-encryption:Delete encryption'
      'delete-bucket-inventory-configuration:Delete inventory config'
      'delete-bucket-lifecycle:Delete lifecycle'
      'delete-bucket-metrics-configuration:Delete metrics config'
      'delete-bucket-policy:Delete policy'
      'delete-bucket-replication:Delete replication'
      'delete-bucket-tagging:Delete tagging'
      'delete-bucket-website:Delete website'
      'delete-object:Delete object'
      'delete-object-tagging:Delete object tagging'
      'delete-objects:Delete multiple objects'
      'get-bucket-acl:Get bucket ACL'
      'get-bucket-analytics-configuration:Get analytics config'
      'get-bucket-cors:Get CORS'
      'get-bucket-encryption:Get encryption'
      'get-bucket-inventory-configuration:Get inventory config'
      'get-bucket-lifecycle:Get lifecycle'
      'get-bucket-lifecycle-configuration:Get lifecycle config'
      'get-bucket-location:Get location'
      'get-bucket-logging:Get logging'
      'get-bucket-metrics-configuration:Get metrics config'
      'get-bucket-notification:Get notification'
      'get-bucket-notification-configuration:Get notification config'
      'get-bucket-policy:Get policy'
      'get-bucket-policy-status:Get policy status'
      'get-bucket-replication:Get replication'
      'get-bucket-request-payment:Get request payment'
      'get-bucket-tagging:Get tagging'
      'get-bucket-versioning:Get versioning'
      'get-bucket-website:Get website'
      'get-object:Get object'
      'get-object-acl:Get object ACL'
      'get-object-legal-hold:Get legal hold'
      'get-object-lock-configuration:Get lock config'
      'get-object-retention:Get retention'
      'get-object-tagging:Get object tagging'
      'get-object-torrent:Get torrent'
      'head-bucket:Head bucket'
      'head-object:Head object'
      'list-buckets:List buckets'
      'list-bucket-analytics-configurations:List analytics configs'
      'list-bucket-inventory-configurations:List inventory configs'
      'list-bucket-metrics-configurations:List metrics configs'
      'list-multipart-uploads:List multipart uploads'
      'list-object-versions:List object versions'
      'list-objects:List objects'
      'list-objects-v2:List objects V2'
      'list-parts:List parts'
      'put-bucket-acl:Put bucket ACL'
      'put-bucket-analytics-configuration:Put analytics config'
      'put-bucket-cors:Put CORS'
      'put-bucket-encryption:Put encryption'
      'put-bucket-inventory-configuration:Put inventory config'
      'put-bucket-lifecycle:Put lifecycle'
      'put-bucket-lifecycle-configuration:Put lifecycle config'
      'put-bucket-logging:Put logging'
      'put-bucket-metrics-configuration:Put metrics config'
      'put-bucket-notification:Put notification'
      'put-bucket-notification-configuration:Put notification config'
      'put-bucket-policy:Put policy'
      'put-bucket-replication:Put replication'
      'put-bucket-request-payment:Put request payment'
      'put-bucket-tagging:Put tagging'
      'put-bucket-versioning:Put versioning'
      'put-bucket-website:Put website'
      'put-object:Put object'
      'put-object-acl:Put object ACL'
      'put-object-legal-hold:Put legal hold'
      'put-object-lock-configuration:Put lock config'
      'put-object-retention:Put retention'
      'put-object-tagging:Put object tagging'
      'restore-object:Restore object'
      'select-object-content:Select object content'
      'upload-part:Upload part'
      'upload-part-copy:Upload part copy'
      'wait:Wait'
    )
    _describe -t commands "S3API commands" commands
    return
  fi
  
  _aws_s3_buckets
}

# EC2 completions
_aws_ec2_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'accept-reserved-instances-exchange-quote:Accept RI exchange'
      'accept-transit-gateway-multicast-domain-associations:Accept multicast associations'
      'accept-transit-gateway-peering-attachment:Accept peering'
      'accept-transit-gateway-vpc-attachment:Accept VPC attachment'
      'accept-vpc-endpoint-connections:Accept endpoint connections'
      'accept-vpc-peering-connection:Accept peering'
      'advertise-byoip-cidr:Advertise BYOIP'
      'allocate-address:Allocate Elastic IP'
      'allocate-hosts:Allocate Dedicated Host'
      'apply-security-groups-to-load-balancer:Apply SG to LB'
      'assign-ipv6-addresses:Assign IPv6'
      'assign-private-ip-addresses:Assign private IPs'
      'associate-address:Associate Elastic IP'
      'associate-client-vpn-target-network:Associate VPN target'
      'associate-dhcp-options:Associate DHCP options'
      'associate-enclave-certificate-iam-role:Associate enclave cert'
      'associate-iam-instance-profile:Associate IAM profile'
      'associate-route-table:Associate route table'
      'associate-subnet-cidr-block:Associate subnet CIDR'
      'associate-transit-gateway-multicast-domain:Associate multicast'
      'associate-transit-gateway-route-table:Associate TGW route table'
      'associate-vpc-cidr-block:Associate VPC CIDR'
      'attach-classic-link-vpc:Attach ClassicLink'
      'attach-internet-gateway:Attach IGW'
      'attach-network-interface:Attach ENI'
      'attach-volume:Attach volume'
      'attach-vpn-gateway:Attach VPN gateway'
      'authorize-client-vpn-ingress:Authorize VPN ingress'
      'authorize-security-group-egress:Authorize egress'
      'authorize-security-group-ingress:Authorize ingress'
      'bundle-instance:Bundle instance'
      'cancel-bundle-task:Cancel bundle'
      'cancel-capacity-reservation:Cancel capacity reservation'
      'cancel-conversion-task:Cancel conversion'
      'cancel-export-task:Cancel export'
      'cancel-import-task:Cancel import'
      'cancel-reserved-instances-listing:Cancel RI listing'
      'cancel-spot-fleet-requests:Cancel spot fleet'
      'cancel-spot-instance-requests:Cancel spot request'
      'confirm-product-instance:Confirm product'
      'copy-fpga-image:Copy FPGA image'
      'copy-image:Copy AMI'
      'copy-snapshot:Copy snapshot'
      'create-capacity-reservation:Create capacity reservation'
      'create-carrier-gateway:Create carrier gateway'
      'create-client-vpn-endpoint:Create VPN endpoint'
      'create-client-vpn-route:Create VPN route'
      'create-customer-gateway:Create CGW'
      'create-default-subnet:Create default subnet'
      'create-default-vpc:Create default VPC'
      'create-dhcp-options:Create DHCP options'
      'create-egress-only-internet-gateway:Create EIGW'
      'create-fleet:Create fleet'
      'create-fpga-image:Create FPGA image'
      'create-image:Create AMI'
      'create-instance-export-task:Create export task'
      'create-internet-gateway:Create IGW'
      'create-key-pair:Create key pair'
      'create-launch-template:Create launch template'
      'create-launch-template-version:Create launch template version'
      'create-local-gateway-route:Create local gateway route'
      'create-local-gateway-route-table-vpc-association:Create local gateway association'
      'create-managed-prefix-list:Create prefix list'
      'create-nat-gateway:Create NAT gateway'
      'create-network-acl:Create NACL'
      'create-network-acl-entry:Create NACL entry'
      'create-network-insights-path:Create insights path'
      'create-network-interface:Create ENI'
      'create-network-interface-permission:Create ENI permission'
      'create-placement-group:Create placement group'
      'create-reserved-instances-listing:Create RI listing'
      'create-route:Create route'
      'create-route-table:Create route table'
      'create-security-group:Create security group'
      'create-snapshot:Create snapshot'
      'create-snapshots:Create multi-volume snapshots'
      'create-spot-datafeed-subscription:Create spot datafeed'
      'create-subnet:Create subnet'
      'create-tags:Create tags'
      'create-traffic-mirror-filter:Create mirror filter'
      'create-traffic-mirror-filter-rule:Create mirror filter rule'
      'create-traffic-mirror-session:Create mirror session'
      'create-traffic-mirror-target:Create mirror target'
      'create-transit-gateway:Create TGW'
      'create-transit-gateway-connect:Create TGW connect'
      'create-transit-gateway-connect-peer:Create TGW peer'
      'create-transit-gateway-multicast-domain:Create multicast domain'
      'create-transit-gateway-peering-attachment:Create peering'
      'create-transit-gateway-prefix-list-reference:Create prefix reference'
      'create-transit-gateway-route:Create TGW route'
      'create-transit-gateway-route-table:Create TGW route table'
      'create-transit-gateway-vpc-attachment:Create VPC attachment'
      'create-volume:Create volume'
      'create-vpc:Create VPC'
      'create-vpc-endpoint:Create endpoint'
      'create-vpc-endpoint-connection-notification:Create notification'
      'create-vpc-endpoint-service-configuration:Create service config'
      'create-vpc-peering-connection:Create peering'
      'create-vpn-connection:Create VPN'
      'create-vpn-connection-route:Create VPN route'
      'create-vpn-gateway:Create VPN gateway'
      'delete-carrier-gateway:Delete carrier gateway'
      'delete-client-vpn-endpoint:Delete VPN endpoint'
      'delete-client-vpn-route:Delete VPN route'
      'delete-customer-gateway:Delete CGW'
      'delete-dhcp-options:Delete DHCP'
      'delete-egress-only-internet-gateway:Delete EIGW'
      'delete-fleets:Delete fleets'
      'delete-flow-logs:Delete flow logs'
      'delete-fpga-image:Delete FPGA image'
      'delete-internet-gateway:Delete IGW'
      'delete-key-pair:Delete key pair'
      'delete-launch-template:Delete launch template'
      'delete-launch-template-versions:Delete launch template versions'
      'delete-local-gateway-route:Delete local gateway route'
      'delete-local-gateway-route-table-vpc-association:Delete association'
      'delete-managed-prefix-list:Delete prefix list'
      'delete-nat-gateway:Delete NAT'
      'delete-network-acl:Delete NACL'
      'delete-network-acl-entry:Delete NACL entry'
      'delete-network-insights-analysis:Delete insights analysis'
      'delete-network-insights-path:Delete insights path'
      'delete-network-interface:Delete ENI'
      'delete-network-interface-permission:Delete ENI permission'
      'delete-placement-group:Delete placement group'
      'delete-queued-reserved-instances:Delete queued RIs'
      'delete-route:Delete route'
      'delete-route-table:Delete route table'
      'delete-security-group:Delete security group'
      'delete-snapshot:Delete snapshot'
      'delete-spot-datafeed-subscription:Delete spot datafeed'
      'delete-subnet:Delete subnet'
      'delete-tags:Delete tags'
      'delete-traffic-mirror-filter:Delete mirror filter'
      'delete-traffic-mirror-filter-rule:Delete mirror rule'
      'delete-traffic-mirror-session:Delete mirror session'
      'delete-traffic-mirror-target:Delete mirror target'
      'delete-transit-gateway:Delete TGW'
      'delete-transit-gateway-connect:Delete TGW connect'
      'delete-transit-gateway-connect-peer:Delete TGW peer'
      'delete-transit-gateway-multicast-domain:Delete multicast'
      'delete-transit-gateway-peering-attachment:Delete peering'
      'delete-transit-gateway-prefix-list-reference:Delete reference'
      'delete-transit-gateway-route:Delete TGW route'
      'delete-transit-gateway-route-table:Delete TGW route table'
      'delete-transit-gateway-vpc-attachment:Delete VPC attachment'
      'delete-volume:Delete volume'
      'delete-vpc:Delete VPC'
      'delete-vpc-endpoints:Delete endpoints'
      'delete-vpc-endpoint-connection-notifications:Delete notifications'
      'delete-vpc-endpoint-service-configurations:Delete service configs'
      'delete-vpc-peering-connection:Delete peering'
      'delete-vpn-connection:Delete VPN'
      'delete-vpn-connection-route:Delete VPN route'
      'delete-vpn-gateway:Delete VPN gateway'
      'deprovision-byoip-cidr:Deprovision BYOIP'
      'deregister-image:Deregister AMI'
      'deregister-instance-event-notification-attributes:Deregister event attrs'
      'deregister-transit-gateway-multicast-group-members:Deregister multicast members'
      'deregister-transit-gateway-multicast-group-sources:Deregister multicast sources'
      'describe-account-attributes:Describe account attrs'
      'describe-addresses:Describe addresses'
      'describe-address-transfers:Describe transfers'
      'describe-aggregate-id-format:Describe ID format'
      'describe-availability-zones:Describe AZs'
      'describe-bundle-tasks:Describe bundles'
      'describe-byoip-cidrs:Describe BYOIP'
      'describe-capacity-reservations:Describe capacity reservations'
      'describe-carrier-gateways:Describe carrier gateways'
      'describe-classic-link-instances:Describe ClassicLink'
      'describe-client-vpn-authorization-rules:Describe VPN rules'
      'describe-client-vpn-connections:Describe VPN connections'
      'describe-client-vpn-endpoints:Describe VPN endpoints'
      'describe-client-vpn-routes:Describe VPN routes'
      'describe-client-vpn-target-networks:Describe VPN targets'
      'describe-coip-pools:Describe COIP'
      'describe-conversion-tasks:Describe conversion'
      'describe-customer-gateways:Describe CGWs'
      'describe-dhcp-options:Describe DHCP'
      'describe-egress-only-internet-gateways:Describe EIGWs'
      'describe-elastic-gpus:Describe GPUs'
      'describe-export-image-tasks:Describe export'
      'describe-export-tasks:Describe export tasks'
      'describe-fast-snapshot-restores:Describe restores'
      'describe-fleet-history:Describe fleet history'
      'describe-fleet-instances:Describe fleet instances'
      'describe-fleets:Describe fleets'
      'describe-flow-logs:Describe flow logs'
      'describe-fpga-image-attribute:Describe FPGA attr'
      'describe-fpga-images:Describe FPGA images'
      'describe-host-reservation-offerings:Describe host offerings'
      'describe-host-reservations:Describe host RIs'
      'describe-hosts:Describe hosts'
      'describe-iam-instance-profile-associations:Describe IAM associations'
      'describe-id-format:Describe ID format'
      'describe-identity-id-format:Describe identity format'
      'describe-image-attribute:Describe AMI attr'
      'describe-images:Describe AMIs'
      'describe-import-image-tasks:Describe import'
      'describe-import-snapshot-tasks:Describe snapshot import'
      'describe-instance-attribute:Describe instance attr'
      'describe-instance-credit-specifications:Describe credit'
      'describe-instance-event-notification-attributes:Describe event attrs'
      'describe-instance-event-windows:Describe event windows'
      'describe-instance-status:Describe status'
      'describe-instance-type-offerings:Describe types'
      'describe-instance-types:Describe instance types'
      'describe-instances:Describe instances'
      'describe-internet-gateways:Describe IGWs'
      'describe-ipv6-pools:Describe IPv6'
      'describe-key-pairs:Describe key pairs'
      'describe-launch-template-versions:Describe template versions'
      'describe-launch-templates:Describe templates'
      'describe-local-gateway-route-table-virtual-interface-group-associations:Describe associations'
      'describe-local-gateway-route-table-vpc-associations:Describe VPC associations'
      'describe-local-gateway-route-tables:Describe route tables'
      'describe-local-gateway-virtual-interface-groups:Describe groups'
      'describe-local-gateway-virtual-interfaces:Describe interfaces'
      'describe-local-gateways:Describe local gateways'
      'describe-managed-prefix-lists:Describe prefix lists'
      'describe-moving-addresses:Describe moving'
      'describe-nat-gateways:Describe NAT'
      'describe-network-acls:Describe NACLs'
      'describe-network-insights-analyses:Describe analyses'
      'describe-network-insights-paths:Describe paths'
      'describe-network-interface-attribute:Describe ENI attr'
      'describe-network-interface-permissions:Describe ENI permissions'
      'describe-network-interfaces:Describe ENIs'
      'describe-placement-groups:Describe placement'
      'describe-prefix-lists:Describe prefix lists'
      'describe-principal-id-format:Describe principal format'
      'describe-public-ipv4-pools:Describe pools'
      'describe-regions:Describe regions'
      'describe-reserved-instances:Describe RIs'
      'describe-reserved-instances-listings:Describe RI listings'
      'describe-reserved-instances-modifications:Describe RI mods'
      'describe-reserved-instances-offerings:Describe RI offerings'
      'describe-route-tables:Describe route tables'
      'describe-scheduled-instance-availability:Describe scheduled'
      'describe-scheduled-instances:Describe scheduled instances'
      'describe-security-group-references:Describe SG refs'
      'describe-security-groups:Describe SGs'
      'describe-snapshot-attribute:Describe snapshot attr'
      'describe-snapshots:Describe snapshots'
      'describe-spot-datafeed-subscription:Describe spot datafeed'
      'describe-spot-fleet-instances:Describe spot fleet'
      'describe-spot-fleet-request-history:Describe spot history'
      'describe-spot-fleet-requests:Describe spot requests'
      'describe-spot-instance-requests:Describe spot instances'
      'describe-spot-price-history:Describe spot prices'
      'describe-stale-security-groups:Describe stale SGs'
      'describe-subnets:Describe subnets'
      'describe-tags:Describe tags'
      'describe-traffic-mirror-filters:Describe mirror filters'
      'describe-traffic-mirror-sessions:Describe mirror sessions'
      'describe-traffic-mirror-targets:Describe mirror targets'
      'describe-transit-gateway-attachments:Describe TGW attachments'
      'describe-transit-gateway-connect-peers:Describe TGW peers'
      'describe-transit-gateway-connects:Describe TGW connects'
      'describe-transit-gateway-multicast-domains:Describe multicast'
      'describe-transit-gateway-peering-attachments:Describe peering'
      'describe-transit-gateway-route-tables:Describe TGW tables'
      'describe-transit-gateway-vpc-attachments:Describe VPC attachments'
      'describe-transit-gateways:Describe TGWs'
      'describe-volume-attribute:Describe volume attr'
      'describe-volume-status:Describe volume status'
      'describe-volumes:Describe volumes'
      'describe-volumes-modifications:Describe volume mods'
      'describe-vpc-attribute:Describe VPC attr'
      'describe-vpc-classic-link:Describe ClassicLink'
      'describe-vpc-classic-link-dns-support:Describe ClassicLink DNS'
      'describe-vpc-endpoint-connection-notifications:Describe notifications'
      'describe-vpc-endpoint-connections:Describe connections'
      'describe-vpc-endpoint-service-configurations:Describe configs'
      'describe-vpc-endpoint-service-permissions:Describe permissions'
      'describe-vpc-endpoint-services:Describe services'
      'describe-vpc-endpoints:Describe endpoints'
      'describe-vpc-peering-connections:Describe peering'
      'describe-vpcs:Describe VPCs'
      'describe-vpn-connections:Describe VPNs'
      'describe-vpn-gateways:Describe VPN gateways'
      'detach-classic-link-vpc:Detach ClassicLink'
      'detach-internet-gateway:Detach IGW'
      'detach-network-interface:Detach ENI'
      'detach-volume:Detach volume'
      'detach-vpn-gateway:Detach VPN'
      'disable-ebs-encryption-by-default:Disable EBS encryption'
      'disable-fast-snapshot-restores:Disable restores'
      'disable-image-deprecation:Disable deprecation'
      'disable-ipam-organization-admin-account:Disable IPAM'
      'disable-serial-console-access:Disable serial console'
      'disable-transit-gateway-route-table-propagation:Disable propagation'
      'disable-vgw-route-propagation:Disable VGW propagation'
      'disable-vpc-classic-link:Disable ClassicLink'
      'disable-vpc-classic-link-dns-support:Disable ClassicLink DNS'
      'disassociate-address:Disassociate address'
      'disassociate-client-vpn-target-network:Disassociate VPN'
      'disassociate-enclave-certificate-iam-role:Disassociate cert'
      'disassociate-iam-instance-profile:Disassociate IAM'
      'disassociate-route-table:Disassociate route'
      'disassociate-subnet-cidr-block:Disassociate subnet CIDR'
      'disassociate-transit-gateway-multicast-domain:Disassociate multicast'
      'disassociate-transit-gateway-route-table:Disassociate table'
      'disassociate-vpc-cidr-block:Disassociate VPC CIDR'
      'enable-ebs-encryption-by-default:Enable EBS encryption'
      'enable-fast-snapshot-restores:Enable restores'
      'enable-image-deprecation:Enable deprecation'
      'enable-ipam-organization-admin-account:Enable IPAM'
      'enable-serial-console-access:Enable serial console'
      'enable-transit-gateway-route-table-propagation:Enable propagation'
      'enable-vgw-route-propagation:Enable VGW'
      'enable-volume-io:Enable volume IO'
      'enable-vpc-classic-link:Enable ClassicLink'
      'enable-vpc-classic-link-dns-support:Enable ClassicLink DNS'
      'export-client-vpn-client-configuration:Export VPN config'
      'export-image:Export image'
      'export-transit-gateway-routes:Export routes'
      'get-associated-enclave-certificate-iam-roles:Get roles'
      'get-associated-ipv6-pool-cidrs:Get CIDRs'
      'get-aws-network-performance-data:Get network data'
      'get-capacity-reservation-usage:Get capacity usage'
      'get-coip-pool-usage:Get COIP usage'
      'get-console-output:Get console'
      'get-console-screenshot:Get screenshot'
      'get-default-credit-specification:Get credit'
      'get-ebs-default-kms-key-id:Get KMS key'
      'get-ebs-encryption-by-default:Get encryption'
      'get-flow-logs-integration-template:Get template'
      'get-groups-for-capacity-reservation:Get groups'
      'get-host-reservation-purchase-preview:Get preview'
      'get-instance-types-from-instance-requirements:Get types'
      'get-instance-uefi-data:Get UEFI'
      'get-ipam-address-history:Get history'
      'get-ipam-discovered-accounts:Get accounts'
      'get-ipam-discovered-resource-cidrs:Get CIDRs'
      'get-ipam-pool-allocations:Get allocations'
      'get-ipam-pool-cidrs:Get CIDRs'
      'get-ipam-resource-cidrs:Get resource CIDRs'
      'get-launch-template-data:Get template data'
      'get-managed-prefix-list-associations:Get associations'
      'get-managed-prefix-list-entries:Get entries'
      'get-network-insights-access-scope-analysis-content:Get content'
      'get-network-insights-access-scope-content:Get scope content'
      'get-password-data:Get password'
      'get-reserved-instances-exchange-quote:Get quote'
      'get-serial-console-access-status:Get status'
      'get-spot-placement-scores:Get scores'
      'get-subnet-cidr-reservations:Get reservations'
      'get-transit-gateway-attachment-propagations:Get propagations'
      'get-transit-gateway-multicast-domain-associations:Get associations'
      'get-transit-gateway-prefix-list-references:Get references'
      'get-transit-gateway-route-table-associations:Get associations'
      'get-transit-gateway-route-table-propagations:Get propagations'
      'get-vpn-connection-device-sample-configuration:Get sample'
      'get-vpn-connection-device-types:Get types'
      'import-client-vpn-client-configuration-routes:Import routes'
      'import-image:Import image'
      'import-instance:Import instance'
      'import-key-pair:Import key'
      'import-snapshot:Import snapshot'
      'list-images-in-deprecation-time-window:List deprecated'
      'modify-address-attribute:Modify address'
      'modify-availability-zone-group:Modify AZ group'
      'modify-capacity-reservation:Modify capacity'
      'modify-client-vpn-endpoint:Modify VPN'
      'modify-default-credit-specification:Modify credit'
      'modify-ebs-default-kms-key-id:Modify KMS'
      'modify-fleet:Modify fleet'
      'modify-fpga-image-attribute:Modify FPGA'
      'modify-hosts:Modify hosts'
      'modify-id-format:Modify ID'
      'modify-identity-id-format:Modify identity'
      'modify-image-attribute:Modify AMI'
      'modify-instance-attribute:Modify instance'
      'modify-instance-capacity-reservation-attributes:Modify capacity'
      'modify-instance-credit-specification:Modify credit'
      'modify-instance-event-start-time:Modify start'
      'modify-instance-event-window:Modify window'
      'modify-instance-maintenance-options:Modify maintenance'
      'modify-instance-metadata-options:Modify metadata'
      'modify-instance-placement:Modify placement'
      'modify-ipam:Modify IPAM'
      'modify-ipam-pool:Modify pool'
      'modify-ipam-resource-cidr:Modify CIDR'
      'modify-ipam-scope:Modify scope'
      'modify-launch-template:Modify template'
      'modify-local-gateway-route:Modify route'
      'modify-managed-prefix-list:Modify prefix'
      'modify-network-interface-attribute:Modify ENI'
      'modify-private-dns-name-options:Modify DNS'
      'modify-reserved-instances:Modify RIs'
      'modify-security-group-rules:Modify rules'
      'modify-snapshot-attribute:Modify snapshot'
      'modify-snapshot-tier:Modify tier'
      'modify-spot-fleet-request:Modify spot'
      'modify-subnet-attribute:Modify subnet'
      'modify-traffic-mirror-filter-network-services:Modify filter'
      'modify-traffic-mirror-filter-rule:Modify rule'
      'modify-traffic-mirror-session:Modify session'
      'modify-transit-gateway:Modify TGW'
      'modify-transit-gateway-prefix-list-reference:Modify reference'
      'modify-transit-gateway-vpc-attachment:Modify attachment'
      'modify-volume:Modify volume'
      'modify-volume-attribute:Modify attr'
      'modify-vpc-attribute:Modify VPC'
      'modify-vpc-endpoint:Modify endpoint'
      'modify-vpc-endpoint-connection-notification:Modify notification'
      'modify-vpc-endpoint-service-configuration:Modify config'
      'modify-vpc-endpoint-service-permissions:Modify permissions'
      'modify-vpc-peering-connection-options:Modify peering'
      'modify-vpc-tenancy:Modify tenancy'
      'modify-vpn-connection:Modify VPN'
      'modify-vpn-connection-options:Modify options'
      'modify-vpn-tunnel-certificate:Modify cert'
      'modify-vpn-tunnel-options:Modify tunnel'
      'monitor-instances:Monitor'
      'move-address-to-vpc:Move to VPC'
      'move-byoip-cidr-to-ipam:Move to IPAM'
      'provision-byoip-cidr:Provision BYOIP'
      'provision-ipam-pool-cidr:Provision CIDR'
      'provision-public-ipv4-pool-cidr:Provision public'
      'purchase-host-reservation:Purchase host'
      'purchase-reserved-instances-offering:Purchase RI'
      'purchase-scheduled-instances:Purchase scheduled'
      'reboot-instances:Reboot'
      'register-image:Register AMI'
      'register-instance-event-notification-attributes:Register events'
      'register-transit-gateway-multicast-group-members:Register members'
      'register-transit-gateway-multicast-group-sources:Register sources'
      'reject-transit-gateway-multicast-domain-associations:Reject multicast'
      'reject-transit-gateway-peering-attachment:Reject peering'
      'reject-transit-gateway-vpc-attachment:Reject attachment'
      'reject-vpc-endpoint-connections:Reject endpoint'
      'reject-vpc-peering-connection:Reject peering'
      'release-address:Release address'
      'release-hosts:Release hosts'
      'release-ipam-pool-allocation:Release allocation'
      'replace-iam-instance-profile-association:Replace IAM'
      'replace-network-acl-association:Replace NACL'
      'replace-network-acl-entry:Replace entry'
      'replace-route:Replace route'
      'replace-route-table-association:Replace association'
      'replace-transit-gateway-route:Replace TGW'
      'report-instance-status:Report status'
      'request-spot-fleet:Request spot fleet'
      'request-spot-instances:Request spot'
      'reset-address-attribute:Reset address'
      'reset-ebs-default-kms-key-id:Reset KMS'
      'reset-fpga-image-attribute:Reset FPGA'
      'reset-image-attribute:Reset AMI'
      'reset-instance-attribute:Reset instance'
      'reset-network-interface-attribute:Reset ENI'
      'reset-snapshot-attribute:Reset snapshot'
      'restore-address-to-classic:Restore Classic'
      'restore-image-from-recycle-bin:Restore image'
      'restore-managed-prefix-list-version:Restore prefix'
      'restore-snapshot-from-recycle-bin:Restore snapshot'
      'restore-snapshot-tier:Restore tier'
      'revoke-client-vpn-ingress:Revoke VPN'
      'revoke-security-group-egress:Revoke egress'
      'revoke-security-group-ingress:Revoke ingress'
      'run-instances:Run instances'
      'run-scheduled-instances:Run scheduled'
      'search-local-gateway-routes:Search routes'
      'search-transit-gateway-multicast-groups:Search multicast'
      'search-transit-gateway-routes:Search TGW'
      'send-diagnostic-interrupt:Send interrupt'
      'start-instances:Start'
      'start-network-insights-access-scope-analysis:Start analysis'
      'start-network-insights-analysis:Start insights'
      'start-vpc-endpoint-service-private-dns-verification:Start DNS'
      'stop-instances:Stop'
      'terminate-instances:Terminate'
      'unassign-ipv6-addresses:Unassign IPv6'
      'unassign-private-ip-addresses:Unassign IPs'
      'unmonitor-instances:Unmonitor'
      'update-security-group-rule-descriptions-egress:Update egress desc'
      'update-security-group-rule-descriptions-ingress:Update ingress desc'
      'withdraw-byoip-cidr:Withdraw BYOIP'
      'wait:Wait'
    )
    _describe -t commands "EC2 commands" commands
    return
  fi
  
  _aws_ec2_instances
}

_aws_ec2_instances() {
  local instances=(${(f)"$(_aws_get_ec2_instances)"})
  _describe -t instances "EC2 instances" instances
}

# Lambda completions
_aws_lambda_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'add-layer-version-permission:Add layer permission'
      'add-permission:Add permission'
      'create-alias:Create alias'
      'create-code-signing-config:Create signing config'
      'create-event-source-mapping:Create event source'
      'create-function:Create function'
      'delete-alias:Delete alias'
      'delete-code-signing-config:Delete signing'
      'delete-event-source-mapping:Delete event source'
      'delete-function:Delete function'
      'delete-function-code-signing-config:Delete code signing'
      'delete-function-concurrency:Delete concurrency'
      'delete-function-event-invoke-config:Delete invoke config'
      'delete-layer-version:Delete layer'
      'delete-provisioned-concurrency-config:Delete provisioned'
      'get-account-settings:Get settings'
      'get-alias:Get alias'
      'get-code-signing-config:Get signing'
      'get-event-source-mapping:Get event source'
      'get-function:Get function'
      'get-function-code-signing-config:Get code signing'
      'get-function-concurrency:Get concurrency'
      'get-function-configuration:Get config'
      'get-function-event-invoke-config:Get invoke config'
      'get-layer-version:Get layer'
      'get-layer-version-by-arn:Get layer by ARN'
      'get-layer-version-policy:Get layer policy'
      'get-policy:Get policy'
      'get-provisioned-concurrency-config:Get provisioned'
      'get-runtime-management-config:Get runtime'
      'invoke:Invoke'
      'list-aliases:List aliases'
      'list-code-signing-configs:List signing'
      'list-event-source-mappings:List event sources'
      'list-function-event-invoke-configs:List invoke configs'
      'list-function-url-configs:List URL configs'
      'list-functions:List functions'
      'list-layer-versions:List versions'
      'list-layers:List layers'
      'list-provisioned-concurrency-configs:List provisioned'
      'list-tags:List tags'
      'list-versions-by-function:List versions'
      'publish-layer-version:Publish layer'
      'publish-version:Publish version'
      'put-function-code-signing-config:Put code signing'
      'put-function-concurrency:Put concurrency'
      'put-function-event-invoke-config:Put invoke config'
      'put-provisioned-concurrency-config:Put provisioned'
      'put-runtime-management-config:Put runtime'
      'remove-layer-version-permission:Remove layer permission'
      'remove-permission:Remove permission'
      'tag-resource:Tag'
      'untag-resource:Untag'
      'update-alias:Update alias'
      'update-code-signing-config:Update signing'
      'update-event-source-mapping:Update event source'
      'update-function-code:Update code'
      'update-function-configuration:Update config'
      'update-function-event-invoke-config:Update invoke'
      'update-function-url-config:Update URL'
    )
    _describe -t commands "Lambda commands" commands
    return
  fi
  
  _aws_lambda_functions
}

_aws_lambda_functions() {
  local functions=(${(f)"$(_aws_get_lambda_functions)"})
  _describe -t functions "Lambda functions" functions
}

# CloudFormation completions
_aws_cloudformation_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'activate-type:Activate type'
      'batch-describe-type-configurations:Batch describe'
      'cancel-update-stack:Cancel update'
      'continue-update-rollback:Continue rollback'
      'create-change-set:Create change set'
      'create-stack:Create stack'
      'create-stack-instances:Create instances'
      'create-stack-set:Create stack set'
      'deactivate-type:Deactivate type'
      'delete-change-set:Delete change set'
      'delete-stack:Delete stack'
      'delete-stack-instances:Delete instances'
      'delete-stack-set:Delete stack set'
      'deregister-type:Deregister type'
      'describe-account-limits:Describe limits'
      'describe-change-set:Describe change set'
      'describe-change-set-hooks:Describe hooks'
      'describe-publisher:Describe publisher'
      'describe-stack-drift-detection-status:Describe drift'
      'describe-stack-events:Describe events'
      'describe-stack-instance:Describe instance'
      'describe-stack-resource:Describe resource'
      'describe-stack-resource-drifts:Describe drifts'
      'describe-stack-resources:Describe resources'
      'describe-stack-set:Describe stack set'
      'describe-stack-set-operation:Describe operation'
      'describe-stacks:Describe stacks'
      'describe-type:Describe type'
      'describe-type-registration:Describe registration'
      'detect-stack-drift:Detect drift'
      'detect-stack-resource-drift:Detect resource drift'
      'detect-stack-set-drift:Detect set drift'
      'estimate-template-cost:Estimate cost'
      'execute-change-set:Execute change set'
      'get-stack-policy:Get policy'
      'get-template:Get template'
      'get-template-summary:Get summary'
      'import-stacks-to-stack-set:Import stacks'
      'list-change-sets:List change sets'
      'list-exports:List exports'
      'list-imports:List imports'
      'list-stack-instances:List instances'
      'list-stack-resources:List resources'
      'list-stack-set-operation-results:List results'
      'list-stack-set-operations:List operations'
      'list-stack-sets:List stack sets'
      'list-stacks:List stacks'
      'list-type-registrations:List registrations'
      'list-type-versions:List versions'
      'list-types:List types'
      'publish-type:Publish type'
      'record-handler-progress:Record progress'
      'register-publisher:Register publisher'
      'register-type:Register type'
      'rollback-stack:Rollback'
      'set-stack-policy:Set policy'
      'set-type-configuration:Set config'
      'set-type-default-version:Set default'
      'signal-resource:Signal'
      'stop-stack-set-operation:Stop operation'
      'test-type:Test type'
      'update-stack:Update stack'
      'update-stack-instances:Update instances'
      'update-stack-set:Update stack set'
      'update-termination-protection:Update protection'
      'validate-template:Validate'
      'wait:Wait'
    )
    _describe -t commands "CloudFormation commands" commands
    return
  fi
  
  _aws_cfn_stacks
}

_aws_cfn_stacks() {
  local stacks=(${(f)"$(_aws_get_cfn_stacks)"})
  _describe -t stacks "CloudFormation stacks" stacks
}

# IAM completions (simplified)
_aws_iam_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'add-client-id-to-open-id-connect-provider:Add client ID'
      'add-role-to-instance-profile:Add role to profile'
      'add-user-to-group:Add user to group'
      'attach-group-policy:Attach group policy'
      'attach-role-policy:Attach role policy'
      'attach-user-policy:Attach user policy'
      'change-password:Change password'
      'create-access-key:Create access key'
      'create-account-alias:Create alias'
      'create-group:Create group'
      'create-instance-profile:Create profile'
      'create-login-profile:Create login'
      'create-open-id-connect-provider:Create OIDC'
      'create-policy:Create policy'
      'create-policy-version:Create version'
      'create-role:Create role'
      'create-saml-provider:Create SAML'
      'create-service-linked-role:Create linked'
      'create-service-specific-credential:Create credential'
      'create-user:Create user'
      'create-virtual-mfa-device:Create MFA'
      'deactivate-mfa-device:Deactivate MFA'
      'delete-access-key:Delete key'
      'delete-account-alias:Delete alias'
      'delete-account-password-policy:Delete password policy'
      'delete-group:Delete group'
      'delete-group-policy:Delete group policy'
      'delete-instance-profile:Delete profile'
      'delete-login-profile:Delete login'
      'delete-open-id-connect-provider:Delete OIDC'
      'delete-policy:Delete policy'
      'delete-policy-version:Delete version'
      'delete-role:Delete role'
      'delete-role-permissions-boundary:Delete boundary'
      'delete-role-policy:Delete role policy'
      'delete-saml-provider:Delete SAML'
      'delete-server-certificate:Delete cert'
      'delete-service-linked-role:Delete linked'
      'delete-service-specific-credential:Delete credential'
      'delete-signing-certificate:Delete signing'
      'delete-ssh-public-key:Delete SSH key'
      'delete-user:Delete user'
      'delete-user-permissions-boundary:Delete boundary'
      'delete-user-policy:Delete user policy'
      'delete-virtual-mfa-device:Delete MFA'
      'detach-group-policy:Detach group'
      'detach-role-policy:Detach role'
      'detach-user-policy:Detach user'
      'enable-mfa-device:Enable MFA'
      'generate-credential-report:Generate report'
      'generate-organizations-access-report:Generate org report'
      'generate-service-last-accessed-details:Generate access'
      'get-access-key-last-used:Get last used'
      'get-account-authorization-details:Get details'
      'get-account-password-policy:Get policy'
      'get-account-summary:Get summary'
      'get-context-keys-for-custom-policy:Get keys'
      'get-context-keys-for-principal-policy:Get principal keys'
      'get-credential-report:Get report'
      'get-group:Get group'
      'get-group-policy:Get group policy'
      'get-instance-profile:Get profile'
      'get-login-profile:Get login'
      'get-open-id-connect-provider:Get OIDC'
      'get-organizations-access-report:Get org report'
      'get-policy:Get policy'
      'get-policy-version:Get version'
      'get-role:Get role'
      'get-role-policy:Get role policy'
      'get-saml-provider:Get SAML'
      'get-server-certificate:Get cert'
      'get-service-last-accessed-details:Get access'
      'get-service-last-accessed-details-with-entities:Get with entities'
      'get-service-linked-role-deletion-status:Get deletion'
      'get-ssh-public-key:Get SSH key'
      'get-user:Get user'
      'get-user-policy:Get user policy'
      'list-access-keys:List keys'
      'list-account-aliases:List aliases'
      'list-attached-group-policies:List attached group'
      'list-attached-role-policies:List attached role'
      'list-attached-user-policies:List attached user'
      'list-entities-for-policy:List entities'
      'list-group-policies:List group policies'
      'list-groups:List groups'
      'list-groups-for-user:List user groups'
      'list-instance-profile-tags:List profile tags'
      'list-instance-profiles:List profiles'
      'list-instance-profiles-for-role:List for role'
      'list-mfa-device-tags:List MFA tags'
      'list-mfa-devices:List MFA'
      'list-open-id-connect-provider-tags:List OIDC tags'
      'list-open-id-connect-providers:List OIDC'
      'list-policies:List policies'
      'list-policies-granting-service-access:List granting'
      'list-policy-tags:List tags'
      'list-policy-versions:List versions'
      'list-role-policies:List role policies'
      'list-role-tags:List role tags'
      'list-roles:List roles'
      'list-saml-provider-tags:List SAML tags'
      'list-saml-providers:List SAML'
      'list-server-certificate-tags:List cert tags'
      'list-server-certificates:List certs'
      'list-service-specific-credentials:List credentials'
      'list-signing-certificates:List signing'
      'list-ssh-public-keys:List SSH'
      'list-user-policies:List user policies'
      'list-user-tags:List user tags'
      'list-users:List users'
      'list-virtual-mfa-devices:List MFA'
      'put-group-policy:Put group'
      'put-role-permissions-boundary:Put role boundary'
      'put-role-policy:Put role'
      'put-user-permissions-boundary:Put user boundary'
      'put-user-policy:Put user'
      'remove-client-id-from-open-id-connect-provider:Remove client'
      'remove-role-from-instance-profile:Remove from profile'
      'remove-user-from-group:Remove from group'
      'reset-service-specific-credential:Reset credential'
      'resync-mfa-device:Resync MFA'
      'set-default-policy-version:Set default'
      'set-security-token-service-preferences:Set STS'
      'simulate-custom-policy:Simulate custom'
      'simulate-principal-policy:Simulate principal'
      'tag-instance-profile:Tag profile'
      'tag-mfa-device:Tag MFA'
      'tag-open-id-connect-provider:Tag OIDC'
      'tag-policy:Tag policy'
      'tag-role:Tag role'
      'tag-saml-provider:Tag SAML'
      'tag-server-certificate:Tag cert'
      'tag-user:Tag user'
      'untag-instance-profile:Untag profile'
      'untag-mfa-device:Untag MFA'
      'untag-open-id-connect-provider:Untag OIDC'
      'untag-policy:Untag policy'
      'untag-role:Untag role'
      'untag-saml-provider:Untag SAML'
      'untag-server-certificate:Untag cert'
      'untag-user:Untag user'
      'update-access-key:Update key'
      'update-account-password-policy:Update policy'
      'update-assume-role-policy:Update assume'
      'update-group:Update group'
      'update-login-profile:Update login'
      'update-open-id-connect-provider-thumbprint:Update thumbprint'
      'update-role:Update role'
      'update-role-description:Update desc'
      'update-saml-provider:Update SAML'
      'update-server-certificate:Update cert'
      'update-service-specific-credential:Update credential'
      'update-signing-certificate:Update signing'
      'update-ssh-public-key:Update SSH'
      'update-user:Update user'
      'upload-server-certificate:Upload cert'
      'upload-signing-certificate:Upload signing'
      'upload-ssh-public-key:Upload SSH'
      'wait:Wait'
    )
    _describe -t commands "IAM commands" commands
    return
  fi
  
  # Could add IAM users/roles/policies here if needed
}

# Simple stubs for remaining services
_aws_rds_completion() { _message 'RDS commands'; }
_aws_ecs_completion() { _message 'ECS commands'; }
_aws_eks_completion() { _message 'EKS commands'; }
_aws_sqs_completion() { _message 'SQS commands'; }
_aws_sns_completion() { _message 'SNS commands'; }
_aws_cloudwatch_completion() { _message 'CloudWatch commands'; }
_aws_logs_completion() { _message 'Logs commands'; }
_aws_kms_completion() { _message 'KMS commands'; }
_aws_secretsmanager_completion() { _message 'Secrets Manager commands'; }
_aws_ssm_completion() { _message 'SSM commands'; }

# Configure completion
_aws_configure_completion() {
  if (( CURRENT == 3 )); then
    local commands=(
      'add-model:Add model'
      'get:Get config'
      'list:List configs'
      'set:Set config'
    )
    _describe -t commands "configure commands" commands
    return
  fi
  
  local cmd=$words[3]
  
  case "$cmd" in
    get|set)
      _arguments \
        '--profile[Profile]:profile:_aws_profiles' \
        ':variable:(aws_access_key_id aws_secret_access_key aws_session_token region output)' \
        ':value: '
      ;;
    list)
      _arguments \
        '--profile[Profile]:profile:_aws_profiles'
      ;;
  esac
}

# Register enhanced completion
compdef _aws_enhanced aws

# ============================================================
# LEGACY: Keep AWS CLI native completions if available
# ============================================================

if [[ ! -f "$ZSH_CACHE_DIR/completions/_aws" ]]; then
  # AWS CLI doesn't have built-in completion generator, use our enhanced one
  typeset -g -A _comps
  autoload -Uz _aws
  _comps[aws]=_aws_enhanced
fi

# ============================================================
# ALIASES (Enhanced)
# ============================================================

# Profile management
alias awsprofiles='cat ~/.aws/credentials | grep "\\[" | sed "s/\\[//g" | sed "s/\\]//g"'
alias awswhoami='aws sts get-caller-identity'
alias awsregions='_aws_get_regions'

# S3
alias s3ls='aws s3 ls'
alias s3sync='aws s3 sync'
alias s3cp='aws s3 cp'
alias s3rm='aws s3 rm'
alias s3mb='aws s3 mb'

# EC2
alias ec2ls='aws ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,Tags[?Key==\'Name\'].Value|[0]]" --output table'
alias ec2start='aws ec2 start-instances --instance-ids'
alias ec2stop='aws ec2 stop-instances --instance-ids'
alias ec2terminate='aws ec2 terminate-instances --instance-ids'

# Lambda
alias lambdals='aws lambda list-functions'
alias lambdainvoke='aws lambda invoke --function-name'

# CloudFormation
alias cfnls='aws cloudformation list-stacks'
alias cfnevents='aws cloudformation describe-stack-events --stack-name'

# CloudWatch Logs
alias cwlogs='aws logs describe-log-groups'
alias cwstreams='aws logs describe-log-streams --log-group-name'

# Helper functions
aws-ec2-ip() {
  aws ec2 describe-instances --instance-ids "$1" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
}

aws-ec2-ssh() {
  local instance_id="$1"
  shift
  local ip=$(aws-ec2-ip "$instance_id")
  ssh "$@" "ec2-user@$ip"
}
