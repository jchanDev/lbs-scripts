#!/bin/bash
PROFILE=$1 #AWS profile name, will be default if you have no profiles configured
REGION=$2
OUTPUT_FILE="load_balancers.txt"

#catches if missing args
if [ -z "$PROFILE" ] || [ -z "$REGION" ]; then
  echo "Usage: $0 <aws-profile> <region> aws-profile will be default if you have no profiles configured"
  exit 1
fi

echo "Listing all ALBs and NLBs in account '$PROFILE' region '$REGION'..."

> "$OUTPUT_FILE"

aws elbv2 describe-load-balancers --region "$REGION" --profile "$PROFILE" \
  --query "LoadBalancers[].[LoadBalancerArn, LoadBalancerName, Type, VpcId]" \
  --output text | while read -r LB_ARN LB_NAME LB_TYPE VPC_ID; do

    echo "Load Balancer: $LB_NAME ($LB_TYPE)" >> "$OUTPUT_FILE"
    echo "ARN: $LB_ARN" >> "$OUTPUT_FILE"
    echo "VPC: $VPC_ID" >> "$OUTPUT_FILE"

    aws elbv2 describe-listeners --load-balancer-arn "$LB_ARN" --region "$REGION" --profile "$PROFILE" \
      --query "Listeners[].[Protocol, Port, SslPolicy]" --output text | while read -r PROTOCOL PORT SSL_POLICY; do
        echo "Listener: $PROTOCOL:$PORT  SSL Policy: ${SSL_POLICY:-N/A}" >> "$OUTPUT_FILE"
    done

    echo "" >> "$OUTPUT_FILE"
done

echo "Saved all Load Balancers to $OUTPUT_FILE"
