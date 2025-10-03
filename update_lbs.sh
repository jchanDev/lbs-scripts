#!/bin/bash

PROFILE=$1
REGION=$2
INPUT_FILE=$3 #list of lbs you want to update, will be the chunk files created from split_lbs.sh
NEW_POLICY="ELBSecurityPolicy-TLS13-1-2-Res-2021-06"

if [ -z "$PROFILE" ] || [ -z "$REGION" ] || [ -z "$INPUT_FILE" ]; then
  echo "Usage: $0 <aws-profile> <region> <input_file> aws-profile will be default if you have no profiles configured"
  exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
  echo "Input file $INPUT_FILE not found!"
  exit 1
fi

echo "Updating ALBs and NLBs in $REGION using profile '$PROFILE' from $INPUT_FILE..."

current_block=""
while IFS= read -r line || [[ -n "$line" ]]; do
  current_block+="$line"$'\n'

  if [ -z "$line" ]; then
    LB_ARN=$(echo "$current_block" | grep "^ARN:" | awk '{print $2}')
    if [ -n "$LB_ARN" ]; then
      echo "=== Checking $LB_ARN ==="
      aws elbv2 describe-listeners --load-balancer-arn "$LB_ARN" --region "$REGION" --profile "$PROFILE" \
        --query "Listeners[?Protocol=='HTTPS' || Protocol=='TLS'].[ListenerArn,SslPolicy]" \
        --output text | while read -r listener current_policy; do
          if [ -z "$listener" ]; then
            continue
          fi
          echo "  Listener $listener current=$current_policy"
          if [ "$current_policy" != "$NEW_POLICY" ]; then
            echo "  -> Updating to $NEW_POLICY"
            aws elbv2 modify-listener \
              --listener-arn "$listener" \
              --ssl-policy "$NEW_POLICY" \
              --region "$REGION" \
              --profile "$PROFILE"
          else
            echo "  Already correct"
          fi
        done
    fi
    current_block=""
  fi
done < "$INPUT_FILE"