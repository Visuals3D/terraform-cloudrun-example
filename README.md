# Deploy an example service

This example service can be deployed for testing authentification and connection to google cloud storage by uploading files to google cloud storage trough the service itself running in cloud run. 

## Create the Container Registry

Run the Terraform script in the *basic_infrastructure* folder with: 

``` shell
terraform init -var="project_id=<PROJECT_ID>"
terraform plan -out="tf-plan"
terraform apply "tf-plan"
```
Run this with **<PROJECT_ID>** replaced with your google clouds project id. 
This creates a container registry in gcp for you. 

## Build and push image

To build the image run this in the example_service folder: 

``` shell
docker build . -t eu.gcr.io/<PROJECT_ID>/storage-uploader:latest
docker push eu.gcr.io/<PROJECT_ID>/storage-uploader:latest
```

Now there should be an image named storage-uploader inside the container registry in Google Cloud Console.
<img src="https://user-images.githubusercontent.com/74773202/200899225-1fbde32a-7bc1-4348-a21a-1139153539b7.png" width="200"/>


## Create Cloud Storage and Cloud Run Container

Now the cloud run container can be deployed with the infrastructure it depends on. The terraform script inside the *example/terraform* folder will rollout all the needed infrastructure as well as deploy the container itself in cloud run. The following components will be created: 

- Cloud Run Instance (To run the container)
- Cloud Storage Bucket (To save files)
- Service Account (To access Storage Bucket)
- Cloud Load Balancer (To route traffic to Cloud Run) 

This can be rolled out by the following commands inside the *example/terraform* folder: 

``` shell
terraform init -var="project_id=<project_id>"
terraform plan -out="tf-plan"
terraform apply "tf-plan"
```
Run this with **<PROJECT_ID>** replaced with your google clouds project id. 

Now the storage bucket, cloud run instance and loadbalancer should be visible in the google cloud console. In order to test the container send a get request to the ip adress of the loadbalancer with the **/files** route. This should return an empty json list. 
<img src="https://user-images.githubusercontent.com/74773202/200898946-04407cfe-bdd6-438b-8f86-097b4d05f50b.png" width="200"/>


<img src="https://user-images.githubusercontent.com/74773202/200898815-fec8a672-84dc-4da0-ad89-72076f22ed99.png" width="200"/>

In oder to test the cloud storage connectivity upload a file to the storage bucket using the google cloud console or the POST method behind the **/upload** route. 
Hiting the **/files** endpoint afterwards should now return a json list with the filename and creation date in it. 
