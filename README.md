Instructions for Setting up and Deploying Vanity Phone Number Generator Service on AWS using Terraform and AWS CLI

# Introduction:
This documentation is a guide to set up and deploy the Vanity Phone Number Generator Service on AWS using Terraform and AWS CLI. The Vanity Phone Number Generator Service is a simple application that generates unique vanity phone numbers based on user input.

## Prerequisites:
To follow this documentation, you need to have the following prerequisites installed on your system:

Git
Terraform CLI
AWS CLI
Steps to set up and deploy the Vanity Phone Number Generator Service:

## 1. Clone the repository:
Clone the repository using the following command:
</br>

  ```git clone https://github.com/michealvernon/TTECVanityGen.git```

## 2. Set up AWS CLI:
Configure the AWS CLI by running the following command and providing the necessary information:
</br>

 ```aws configure```
 
## 3. Set up Terraform CLI:
Download and install the Terraform CLI from the official website: https://www.terraform.io/downloads.html

## 4. Initialize Terraform:
Open a terminal in the root folder of the cloned repository and run the following command to initialize Terraform:
</br>

```terraform init```

This command will download the necessary provider plugins and initialize Terraform for the project. It may take up to 2 minutes to complete.

## 5. Plan the infrastructure: (Optional)
Run the following command to preview the infrastructure changes that Terraform will make:
<br>
```terraform plan```

## 6. Deploy the infrastructure:
Run the following command to deploy the infrastructure to AWS:
<br>

```terraform apply -auto-approve```

This command will create all the necessary resources on AWS, including an Amazon Connect instance, an Amazon S3 bucket, and an Amazon CloudFront distribution. It may take up to 5 minutes to complete.

KNOWN ISSUES : This command might generate an error “Error creating connect queue (dataqueue)” you can ignore this error as there’s some issue with AWS API for creating the queue and it’s known issue. This might also generate some warnings but you can ignore those warnings. 


## 7. Setup Connect Instance
  
  1) Go to the Amazon Connect console and click on "Contact Flows."
  2) Click on Instance name with prefix "VanityGenerator"
  3) Now, you can see instance settings, click on Emergency Access (This will let you login without username and password. Terraform doesnt supports usernames for connect instances you can manually setupup username later on)
  4) Once you're logged in, Select your phone number by clicking on "Begin" on "Explore your channels of communication" option.
  5) Select a US based DID or TOLL Free number and click next
  6) Once the number of your choice has been assigned, go back and click 'view your phone numbers' on dashboard
  7) Click on your phone number and change the contact flow/IVR to 'VanityGenerator' from the dropdown menu
  8) After this you can call on you phone number to test the service. NOTE: When you call the service for the first time, it may not generate the numbers initially as the app initializes the database. But it should be working on second call. This only happens when the app is deployed and used first time. 
  
  


# BONUS TASK 

 There was some issue on the terraform API for s3 bucket and due to which I was unable to access the React APP on AWS. Currently 'frontend' folder is being deployed on S3 bucket and cloudfront distribution is setup for deploying the React app (static HTML files, CSS, JS), but because of some issues I was unable to give public permissions to S3 bucket objects and that's why you wont be able to access the site. You can access S3 bucket object (name will have prefix 'vanitygenerator') and change the permissions manually and try to access the site. You can also look at the React APP (Components and stuff) on 'frontend-react' folder and this folder is not deployed on AWS but you can review the code. 
  
