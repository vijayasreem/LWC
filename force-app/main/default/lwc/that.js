
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FileUploader extends LightningElement {
    @api recordId;

    handleUpload(event) {
        const file = event.target.files[0];
        const fileName = file.name;
        
        // Create AWS S3 client to upload the file
        // Replace the placeholders with your AWS S3 credentials
        const AWS = require('aws-sdk');
        const s3 = new AWS.S3({
            accessKeyId: 'YOUR_AWS_ACCESS_KEY',
            secretAccessKey: 'YOUR_AWS_SECRET_ACCESS_KEY',
            region: 'YOUR_AWS_REGION'
        });

        // Configure the AWS bucket and key for uploading
        const bucketName = 'YOUR_AWS_BUCKET_NAME';
        const key = this.recordId + '/' + fileName;

        // Prepare the parameters for uploading the file to AWS S3
        const params = {
            Bucket: bucketName,
            Key: key,
            Body: file
        };

        // Upload the file to AWS S3
        s3.upload(params, (err, data) => {
            if (err) {
                this.showToast('Error', 'An error occurred while uploading the file.', 'error');
            } else {
                // Create a Salesforce record to store the uploaded file details
                const documentName = fileName;
                const documentUrl = data.Location;
                const createdBy = 'User'; // Replace with the actual user who uploaded the file

                // Call an Apex method to create the Salesforce record
                // Replace 'createDocument' with the actual Apex method name
                createDocument({ documentName, documentUrl, createdBy })
                    .then(result => {
                        this.showToast('Success', 'The file has been uploaded successfully.', 'success');
                    })
                    .catch(error => {
                        this.showToast('Error', 'An error occurred while creating the document record.', 'error');
                    });
            }
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}
