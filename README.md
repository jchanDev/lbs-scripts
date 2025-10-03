# Load Balancer SSL Policy Update Scripts

This repository provides helper scripts to:

- List all Application and Network Load Balancers (ALB & NLB) with detailed info  
- Split them into smaller chunks for safe batch updates  
- Update their SSL/TLS security policies to a new TLS policy  

All scripts support AWS CLI profiles and regions so you can run them safely across different AWS accounts.

---

### 1. List all Load Balancers

<pre> ./list_load_balancers.sh &lt;aws-profile&gt; &lt;region&gt; </pre>
&lt;aws-profile&gt; — AWS CLI profile (use "default" if you only have one)

&lt;region&gt; — AWS region, e.g. us-west-2

Output file: load_balancers.txt

Example output format:
<pre>
Load Balancer: my-app-alb-1 (application)
ARN: arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-app-alb-1/1234567890abcdef
VPC: vpc-0a1b2c3d4e5f6g7h
Listener: HTTP:80  SSL Policy: N/A
Listener: HTTPS:443  SSL Policy: ELBSecurityPolicy-2016-08

Load Balancer: my-nlb-1 (network)
ARN: arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/net/my-nlb-1/1234567890abcdef
VPC: vpc-0h7g6f5e4d3c2b1a
Listener: TCP:443  SSL Policy: TLS-1-2-2017-01
</pre>

### 2. Split into Chunks
<pre>./split_albs_txt.sh &lt;load_balancers_file&gt; &lt;number_of_lbs_per_chunk&gt;</pre>

&lt;load_balancers_file&gt; — input file from step 1 (e.g. load_balancers.txt)

&lt;number_of_lbs_per_chunk&gt; — how many LBs per split file

Output files:
alb_chunk_1.txt
alb_chunk_2.txt
...

Each chunk contains full LB blocks (including listeners), separated by blank lines.

### 3. Update SSL/TLS Policies
<pre> ./update_lb_ssl.sh &lt;aws-profile&gt; &lt;region&gt; &lt;lb_file&gt;</pre>

&lt;aws-profile&gt; — AWS CLI profile (use "default" if you only have one)

&lt;region&gt; — AWS region, e.g. us-west-2

&lt;lb_file&gt; — the file from step 1 or 2 (load_balancers.txt or a chunk file)

Behavior:
- Reads LB ARNs from the file
- Checks HTTPS/TLS listeners
- Updates SSL policy to ELBSecurityPolicy-TLS13-1-2-Res-2021-06 (default in script)
- Skips listeners already using the correct policy

Example run:
<pre> ./update_lb_ssl.sh default us-west-2 alb_chunk_1.txt </pre>

Example console output:
<pre>
=== Checking arn:aws:elasticloadbalancing:us-west-2:123456789012:listener/app/my-app-alb-1/50dc6c495c0c9188/abcd1234efgh5678 ===
  Listener arn:aws:elasticloadbalancing:us-west-2:123456789012:listener/app/my-app-alb-1/50dc6c495c0c9188/abcd1234efgh5678 current=ELBSecurityPolicy-2016-08
  -> Updating to ELBSecurityPolicy-TLS13-1-2-Res-2021-06
</pre>
