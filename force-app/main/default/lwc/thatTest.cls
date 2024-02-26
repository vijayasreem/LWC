
import { createElement } from 'lwc';
import FileUploader from 'c/fileUploader';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';

// Mock the AWS SDK
jest.mock('aws-sdk', () => {
    return {
        S3: jest.fn().mockImplementation(() => ({
            upload: jest.fn().mockImplementation((params, callback) => {
                callback(null, { Location: 'mocked-url' });
            })
        }))
    };
});

// Mock the Apex method
jest.mock('@salesforce/apex/FileUploaderController.createDocument', () => {
    return {
        default: jest.fn()
    };
});

describe('c-file-uploader', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('should upload file and create Salesforce record', () => {
        // Create a mock file and event object
        const mockFile = new File(['file content'], 'test.txt', { type: 'text/plain' });
        const mockEvent = { target: { files: [mockFile] } };

        // Create the component
        const element = createElement('c-file-uploader', {
            is: FileUploader
        });
        document.body.appendChild(element);

        // Access the child component
        const fileUploader = element.shadowRoot.querySelector('c-file-uploader');

        // Set the recordId attribute
        fileUploader.recordId = 'mocked-record-id';

        // Trigger the handleUpload method
        fileUploader.handleUpload(mockEvent);

        // Validate the AWS S3 upload parameters
        expect(AWS.S3).toHaveBeenCalledWith({
            accessKeyId: 'YOUR_AWS_ACCESS_KEY',
            secretAccessKey: 'YOUR_AWS_SECRET_ACCESS_KEY',
            region: 'YOUR_AWS_REGION'
        });
        expect(s3.upload).toHaveBeenCalledWith(
            expect.objectContaining({
                Bucket: 'YOUR_AWS_BUCKET_NAME',
                Key: 'mocked-record-id/test.txt',
                Body: mockFile
            }),
            expect.any(Function)
        );

        // Validate the Apex method call
        expect(createDocument).toHaveBeenCalledWith({
            documentName: 'test.txt',
            documentUrl: 'mocked-url',
            createdBy: 'User'
        });

        // Validate the toast event
        const toastEvent = new ShowToastEventName('Success', 'The file has been uploaded successfully.', 'success');
        expect(fileUploader.dispatchEvent).toHaveBeenCalledWith(toastEvent);
    });

    it('should show error toast when upload fails', () => {
        // Create a mock file and event object
        const mockFile = new File(['file content'], 'test.txt', { type: 'text/plain' });
        const mockEvent = { target: { files: [mockFile] } };

        // Create the component
        const element = createElement('c-file-uploader', {
            is: FileUploader
        });
        document.body.appendChild(element);

        // Access the child component
        const fileUploader = element.shadowRoot.querySelector('c-file-uploader');

        // Set the recordId attribute
        fileUploader.recordId = 'mocked-record-id';

        // Mock the AWS S3 upload error
        s3.upload.mockImplementationOnce((params, callback) => {
            callback(new Error('mocked-error'), null);
        });

        // Trigger the handleUpload method
        fileUploader.handleUpload(mockEvent);

        // Validate the error toast event
        const toastEvent = new ShowToastEventName('Error', 'An error occurred while uploading the file.', 'error');
        expect(fileUploader.dispatchEvent).toHaveBeenCalledWith(toastEvent);
    });

    it('should show error toast when creating Salesforce record fails', () => {
        // Create a mock file and event object
        const mockFile = new File(['file content'], 'test.txt', { type: 'text/plain' });
        const mockEvent = { target: { files: [mockFile] } };

        // Create the component
        const element = createElement('c-file-uploader', {
            is: FileUploader
        });
        document.body.appendChild(element);

        // Access the child component
        const fileUploader = element.shadowRoot.querySelector('c-file-uploader');

        // Set the recordId attribute
        fileUploader.recordId = 'mocked-record-id';

        // Mock the Apex method error
        createDocument.mockRejectedValueOnce(new Error('mocked-error'));

        // Trigger the handleUpload method
        fileUploader.handleUpload(mockEvent);

        // Validate the error toast event
        const toastEvent = new ShowToastEventName('Error', 'An error occurred while creating the document record.', 'error');
        expect(fileUploader.dispatchEvent).toHaveBeenCalledWith(toastEvent);
    });
});
